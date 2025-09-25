import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class AuthService {
  static final _storage = FlutterSecureStorage();

  // JWT 토큰 저장/조회/삭제
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // Google ID 토큰 저장/조회/삭제
  static Future<void> saveGoogleIdToken(String idToken) async {
    await _storage.write(key: 'google_id_token', value: idToken);
  }

  static Future<String?> getGoogleIdToken() async {
    return await _storage.read(key: 'google_id_token');
  }

  static Future<void> deleteGoogleIdToken() async {
    await _storage.delete(key: 'google_id_token');
  }

  // Authorization 헤더 생성
  static Future<Map<String, String>> buildAuthHeader() async {
    final token = await getToken();
    if (token != null) {
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    } else {
      return {'Content-Type': 'application/json'};
    }
  }

  // 전체 로그아웃 처리
  static Future<void> logout(BuildContext context) async {
    try {
      // 카카오 로그아웃
      await UserApi.instance.logout();

      // 저장된 모든 토큰 삭제
      await deleteToken();
      await deleteGoogleIdToken();

      // 로그인 화면으로 이동 (기존 화면 제거)
      Navigator.pushNamedAndRemoveUntil(
          context, '/main-screen', (route) => false);
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }
}
