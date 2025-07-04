import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthRepository {
  static const String baseUrl = 'http://your-api-url.com';

  Future<http.Response> sendKakaoUserToBackend({
    required String email,
    required String nickname,
    required String provider,
    required String providerId,
  }) async {
    final url = Uri.parse('$baseUrl/user/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'nickname': nickname,
        'provider': provider,
        'providerId': providerId,
      }),
    );

    return response;
  }
}
