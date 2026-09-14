import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class BackendAnalysisService {
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
    final response = await http.get(_uri('/ai/status')).timeout(
          const Duration(seconds: 8),
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI status failed: ${response.statusCode}');
    }
    return _decodeMap(response.body);
  }

  static Future<Map<String, dynamic>?> localToolsStatus() async {
    if (!isConfigured) return null;
    final response = await http.get(_uri('/tools/status')).timeout(
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
    if (!isConfigured) {
      throw Exception('Local VitalMap backend is not configured.');
    }
    final request = http.MultipartRequest(
      'POST',
      _uri('/tools/lab-report/scan'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );
    final response = await (() async {
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    })().timeout(const Duration(seconds: 390));
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
          _uri('/tools/changes/explain'),
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
          _uri('/tools/metric-guidance'),
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
          _uri('/tools/report-guidance'),
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
