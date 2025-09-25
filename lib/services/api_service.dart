// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'package:connectbeat/providers/current_user_provider.dart';

class ApiService {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// 🔐 소셜 로그인 API (JWT 토큰 저장 + 사용자 상태 업데이트)
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

      // ✅ JWT 토큰 저장
      final token = data['token'];
      await AuthService.saveToken(token);

      // ✅ 사용자 정보 저장
      final userId = data['userId'];
      ref.read(currentUserProvider.notifier).state = userId;

      print("✅ Login success, userId = $userId");
      print("🔑 Token saved: $token");
    } else {
      print("❌ Login failed: ${response.statusCode}, ${response.body}");
    }
  }

  /// 🔐 인증 토큰 포함 GET 요청
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

  /// 🔐 인증 토큰 포함 POST 요청
  static Future<http.Response> postWithAuth(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    final token = await AuthService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // ✅ 디버그 로그
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

  /// 🔐 인증 토큰 포함 PUT 요청
  static Future<http.Response> putWithAuth(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    final token = await AuthService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return response;
  }
}
