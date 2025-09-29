// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // ✅ UTF-8로 디코딩
      final data = jsonDecode(utf8.decode(response.bodyBytes));

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

  /// 👤 현재 로그인한 사용자 정보 가져오기
  static Future<Map<String, dynamic>?> fetchUserInfo() async {
    final token = await AuthService.getToken();
    print("🛠 Debug: JWT token = $token");

    final response = await getWithAuth('/users/me');
    print("🛠 Debug: Response code = ${response.statusCode}");
    print("🛠 Debug: Response body = ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      print("👤 User info: $data");
      return data;
    } else {
      print("❌ Failed to fetch user info: ${response.statusCode}, ${response.body}");
      return null;
    }
  }

  /// 👤 사용자 정보 업데이트
  static Future<Map<String, dynamic>?> updateUserInfo({
    required String nickname,
    String? profileImage,
  }) async {
    final body = {
      'nickname': nickname,
      if (profileImage != null) 'profileImage': profileImage,
    };

    final response = await putWithAuth('/users/me', body: body);

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        print("✅ User updated (empty response)");
        return null; // 서버가 아무 것도 안 보내면 null 반환
      }

      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print("✅ User updated: $data");
        return data;
      } catch (e) {
        print("⚠️ Failed to parse response: $e");
        return null;
      }
    } else {
      print("❌ Failed to update user: ${response.statusCode}, ${response.body}");
      return null;
    }
  }
}
