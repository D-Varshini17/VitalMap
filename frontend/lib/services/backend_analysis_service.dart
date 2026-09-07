import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendAnalysisService {
  static const backendUrl = String.fromEnvironment(
    'VITALMAP_BACKEND_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

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
    final decoded = jsonDecode(response.body);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  static Future<Map<String, dynamic>?> localAiStatus() async {
    if (!isConfigured) return null;
    final response = await http.get(_uri('/ai/status')).timeout(
          const Duration(seconds: 8),
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI status failed: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }
}
