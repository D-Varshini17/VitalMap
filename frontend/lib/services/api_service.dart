import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/local_analysis_engine.dart';

class ApiService {
  static final LocalAnalysisEngine _localEngine = LocalAnalysisEngine();

  static String get _base {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static Future<Map<String, dynamic>?> analyze(
      Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$_base/analyze');
      final res = await http
          .post(url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        decoded['offline_mode'] = false;
        decoded['recommendation_mode'] = 'online';
        return decoded;
      }
      return _localAnalyze(payload);
    } catch (e) {
      return _localAnalyze(payload);
    }
  }

  static Map<String, dynamic>? _localAnalyze(Map<String, dynamic> payload) {
    try {
      final response = _localEngine.analyze(payload);
      response['offline_mode'] = true;
      response['recommendation_mode'] = 'offline';
      return response;
    } catch (e) {
      return null;
    }
  }
}
