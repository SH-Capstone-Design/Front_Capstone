import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final String baseUrl = dotenv.env['BASE_URL']!;

  /// 구글 로그인용: provider = "google", idToken 필수, accessToken 옵션
  Future<http.Response> sendGoogleUserToBackend({
    required String idToken,
    String? accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');
    final bodyMap = {
      'provider': 'google',
      'idToken': idToken,
    };

    if (accessToken != null && accessToken.isNotEmpty) {
      bodyMap['accessToken'] = accessToken;
    }

    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bodyMap),
    );
  }

  /// 카카오 로그인용: provider = "kakao", accessToken 필수
  Future<http.Response> sendKakaoUserToBackend({
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');
    final bodyMap = {
      'provider': 'kakao',
      'accessToken': accessToken,
    };

    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bodyMap),
    );
  }

  /// ✅ 내 정보 조회 (/users/me)
  Future<Map<String, dynamic>> fetchMyInfo() async {
    final url = Uri.parse('$baseUrl/users/me');

    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("JWT 토큰이 없습니다. 로그인 후 다시 시도해주세요.");
    }

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes); // 👈 한글 깨짐 방지
      final data = jsonDecode(decodedBody);
      return data as Map<String, dynamic>;
    } else {
      throw Exception("Failed to load user info");
    }
  }

  /// ✅ 커플 해제 (/couple/unlink)
  Future<void> unlinkCouple() async {
    final url = Uri.parse('$baseUrl/couple/unlink');

    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("JWT 토큰이 없습니다.");
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("커플 해제 실패");
    }
  }
}
