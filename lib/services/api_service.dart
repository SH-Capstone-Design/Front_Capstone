import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class ApiService {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  // 🔐 로그인 API (provider + accessToken 전달)
  static Future<Map<String, dynamic>> loginWithProvider({
    required String provider,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'accessToken': accessToken,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  // 🔐 인증 토큰을 포함한 POST 요청
  static Future<http.Response> postWithAuth(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await AuthService.getToken();
    return await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // 🔐 인증 토큰을 포함한 GET 요청
  static Future<http.Response> getWithAuth(String endpoint) async {
    final token = await AuthService.getToken();
    return await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}
