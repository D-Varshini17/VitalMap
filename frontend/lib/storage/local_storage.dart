import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveLastPayload(Map<String, dynamic> payload) async {
    final sp = await SharedPreferences.getInstance();
    sp.setString('last_payload', jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> loadLastPayload() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString('last_payload');
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> saveLastResponse(Map<String, dynamic> resp) async {
    final sp = await SharedPreferences.getInstance();
    final withMeta = {
      'timestamp': DateTime.now().toIso8601String(),
      'response': resp,
    };
    sp.setString('last_response', jsonEncode(withMeta));
  }

  static Future<Map<String, dynamic>?> loadLastResponse() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString('last_response');
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }
}
