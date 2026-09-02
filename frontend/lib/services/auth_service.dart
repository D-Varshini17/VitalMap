import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/local_storage.dart';

class AuthService {
  static const _localhostBaseUrl = 'http://127.0.0.1:5000';
  static const _androidEmulatorBaseUrl = 'http://10.0.2.2:5000';

  static String resolveBaseUrlForPlatform({required bool isAndroid}) {
    return isAndroid ? _androidEmulatorBaseUrl : _localhostBaseUrl;
  }

  /// Attempt to login against backend; falls back to local stored user.
  /// Returns a map { 'success': bool, 'message': String }
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final baseUrl = resolveBaseUrlForPlatform(isAndroid: true);
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        return {'success': j['success'] == true, 'message': j['message'] ?? ''};
      }
      return {'success': false, 'message': 'Server error ${resp.statusCode}'};
    } catch (_) {
      // Fallback: accept if email matches locally stored user
      final stored = await LocalStorage.loadUserEmail();
      if (stored != null && stored == email) {
        return {'success': true, 'message': 'Signed in locally (offline mode)'};
      }
      return {'success': false, 'message': 'Unable to reach auth server'};
    }
  }

  /// Register a new user on backend; falls back to local save.
  static Future<Map<String, dynamic>> register(
    String email,
    String password,
  ) async {
    final baseUrl = resolveBaseUrlForPlatform(isAndroid: true);
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        if (j['success'] == true) {
          // persist locally as well
          await LocalStorage.saveUserEmail(email);
        }
        return {'success': j['success'] == true, 'message': j['message'] ?? ''};
      }
      return {'success': false, 'message': 'Server error ${resp.statusCode}'};
    } catch (_) {
      // Fallback: save locally
      await LocalStorage.saveUserEmail(email);
      return {'success': true, 'message': 'Registered locally (offline)'};
    }
  }
}
