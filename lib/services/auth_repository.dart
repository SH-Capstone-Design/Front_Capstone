import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
}
