import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const _base = 'https://vitalmap-backend.onrender.com';

  static Future<Map<String, dynamic>?> analyze(
      Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$_base/analyze');
      final res = await http
          .post(url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload))
          .timeout(Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
