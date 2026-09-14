import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static String _key(String name) {
    final uid = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? name : '$uid:$name';
  }
  static Future<void> saveLastPayload(Map<String, dynamic> payload) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key('last_payload'), jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> loadLastPayload() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_key('last_payload'));
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> saveLastResponse(Map<String, dynamic> resp) async {
    final sp = await SharedPreferences.getInstance();
    final withMeta = {
      'timestamp': DateTime.now().toIso8601String(),
      'response': resp,
    };
    await sp.setString(_key('last_response'), jsonEncode(withMeta));
  }

  static Future<Map<String, dynamic>?> loadLastResponse() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_key('last_response'));
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key('last_payload'));
    await sp.remove(_key('last_response'));
  }
}
