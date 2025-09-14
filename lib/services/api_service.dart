// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/providers/current_user_provider.dart';
import 'auth_service.dart';

class ApiService {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  // 🔐 로그인 API (provider + accessToken 전달)
  static Future<void> loginWithProvider({
    required WidgetRef ref,
    required String provider,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'accessToken': accessToken,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ✅ 응답에서 userId 추출 후 Provider에 저장
      final userId = data['userId'];
      ref.read(currentUserProvider.notifier).state = userId;

      // 디버그 로그
      print("✅ Login success, userId = $userId");
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  // 🔐 인증 토큰을 포함한 POST 요청
  static Future<http.Response> postWithAuth(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    final token = await AuthService.getToken();

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // ✅ 디버그 로그 추가
    print("🔗 POST $_baseUrl$endpoint");
    print("📦 Headers: $headers");
    if (body != null) print("📤 Body: $body");

    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    print("📥 Response [${response.statusCode}]: ${response.body}");
    return response;
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
