import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ReportProcessorException implements Exception {
  const ReportProcessorException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackendAnalysisService {
  // Report files and local AI must not follow the public calculation API URL.
  // On Android, START_LOCAL_REPORT_PROCESSOR.bat forwards this port over USB.
  static const toolsBackendUrl = String.fromEnvironment(
    'VITALMAP_TOOLS_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get reportConnectionHelp => kIsWeb
      ? 'Start START_LOCAL_REPORT_PROCESSOR.bat on this computer, then retry. '
          'If your browser asks for local network access, allow it for VitalMap.'
      : 'Connect your phone to the laptop with USB debugging enabled and run '
          'START_LOCAL_REPORT_PROCESSOR.bat on the laptop, then retry. '
          'Keep the laptop running and USB connected.';

  static Uri _toolsUri(String path) =>
      Uri.parse('${toolsBackendUrl.replaceFirst(RegExp(r'/+$'), '')}$path');
  static const _defaultBackendUrl = String.fromEnvironment(
    'VITALMAP_BACKEND_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get backendUrl {
    final runtimeUrl = Uri.base.queryParameters['backendUrl']?.trim();
    if (runtimeUrl != null && runtimeUrl.isNotEmpty) {
      final uri = Uri.tryParse(runtimeUrl);
      // A shared link must not redirect medical payloads to an arbitrary host.
      if (uri != null &&
          {'http', 'https'}.contains(uri.scheme) &&
          {'localhost', '127.0.0.1', '::1'}.contains(uri.host) &&
          uri.userInfo.isEmpty) {
        return runtimeUrl;
      }
    }
    return _defaultBackendUrl;
  }

  static bool get isConfigured => backendUrl.trim().isNotEmpty;

  static Uri _uri(String path) {
    final base = backendUrl.endsWith('/')
        ? backendUrl.substring(0, backendUrl.length - 1)
        : backendUrl;
    return Uri.parse('$base$path');
  }

  static Future<Map<String, dynamic>?> analyze(
    Map<String, dynamic> payload,
  ) async {
    if (!isConfigured) return null;
    final response = await http
        .post(
          _uri('/analyze'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend analyze failed: ${response.statusCode}');
    }
    return _decodeMap(response.body);
  }

  static Future<Map<String, dynamic>?> localAiStatus() async {
    if (!isConfigured) return null;
    final response = await http.get(_toolsUri('/ai/status')).timeout(
          const Duration(seconds: 8),
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI status failed: ${response.statusCode}');
    }
    return _decodeMap(response.body);
  }

  static Future<Map<String, dynamic>?> localToolsStatus() async {
    if (!isConfigured) return null;
    final response = await http.get(_toolsUri('/tools/status')).timeout(
          const Duration(seconds: 8),
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Local tools status failed: ${response.statusCode}');
    }
    return _decodeMap(response.body);
  }

  static Future<Map<String, dynamic>> scanLabReport({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty || bytes.length > 12 * 1024 * 1024) {
      throw const ReportProcessorException(
          'Choose a non-empty report of 12 MB or smaller.');
    }
    // Check readiness before transferring any report bytes. A public API can
    // be healthy while its local Ollama processor is unavailable.
    try {
      final status = await localToolsStatus();
      if (status?['text_model_installed'] != true) {
        throw const ReportProcessorException(
            'The report processor is reachable, but its text model is not ready. '
            'Start Ollama on the laptop and install qwen3:1.7b, then retry.');
      }
      final extension = fileName.split('.').last.toLowerCase();
      if ({'png', 'jpg', 'jpeg', 'webp'}.contains(extension) &&
          status?['vision_model_installed'] != true) {
        throw const ReportProcessorException(
            'The image reader is not ready. Install qwen2.5vl:3b in Ollama on the laptop, then retry.');
      }
    } on http.ClientException {
      throw ReportProcessorException(
          'Cannot connect to the local report processor. $reportConnectionHelp');
    } on TimeoutException {
      throw ReportProcessorException(
          'The local report processor is not responding. $reportConnectionHelp');
    }
    final request = http.MultipartRequest(
      'POST',
      _toolsUri('/tools/lab-report/scan'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );
    late final http.Response response;
    final client = http.Client();
    try {
      response = await (() async {
        final streamed = await client.send(request);
        return http.Response.fromStream(streamed);
      })()
          .timeout(const Duration(seconds: 390));
    } on http.ClientException {
      throw ReportProcessorException(
          'Connection to the report processor was lost. $reportConnectionHelp');
    } on TimeoutException {
      throw const ReportProcessorException(
          'Reading the report took too long. Try one clear report page at a time.');
    } finally {
      client.close();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, 'Lab report scan failed'));
    }
    return _decodeMap(response.body) ?? <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> explainChanges(
    Map<String, dynamic> comparison,
  ) async {
    if (!isConfigured) {
      throw Exception('Local VitalMap backend is not configured.');
    }
    final response = await http
        .post(
          _toolsUri('/tools/changes/explain'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(comparison),
        )
        .timeout(const Duration(seconds: 150));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, 'Local AI explanation failed'));
    }
    return _decodeMap(response.body) ?? <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> metricGuidance({
    required Map<String, dynamic> metric,
    required Map<String, dynamic> generalHealth,
    Map<String, dynamic> profile = const {},
    List<Map<String, dynamic>> recentCheckIns = const [],
    List<Map<String, dynamic>> recentTrend = const [],
  }) async {
    if (!isConfigured) {
      throw Exception('Local VitalMap backend is not configured.');
    }
    final response = await http
        .post(
          _toolsUri('/tools/metric-guidance'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'metric': metric,
            'general_health': generalHealth,
            'profile': profile,
            'recent_check_ins': recentCheckIns,
            'recent_trend': recentTrend,
          }),
        )
        .timeout(const Duration(seconds: 150));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, 'Local AI guidance failed'));
    }
    return _decodeMap(response.body) ?? <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> reportGuidance({
    required Map<String, dynamic> analysis,
    required Map<String, dynamic> generalHealth,
  }) async {
    if (!isConfigured) {
      throw Exception('Local VitalMap backend is not configured.');
    }
    final response = await http
        .post(
          _toolsUri('/tools/report-guidance'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'analysis': analysis,
            'general_health': generalHealth,
          }),
        )
        .timeout(const Duration(seconds: 180));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, 'Report guidance failed'));
    }
    return _decodeMap(response.body) ?? <String, dynamic>{};
  }

  static Map<String, dynamic>? _decodeMap(String body) {
    final decoded = jsonDecode(body);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }
}
