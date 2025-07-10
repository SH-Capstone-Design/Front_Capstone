import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthRepository {
  final String baseUrl = dotenv.env['BASE_URL']!;

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
