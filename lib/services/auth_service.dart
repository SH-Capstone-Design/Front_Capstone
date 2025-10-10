import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserModel {
  final String id;
  final String status;
  final String? nickname;
  final String? profileImageUrl;
  final String? coupleId;
  final String? partnerNickname;

  UserModel({
    required this.id,
    required this.status,
    this.nickname,
    this.profileImageUrl,
    this.coupleId,
    this.partnerNickname,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      status: json['status'] ?? '',
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
      coupleId: json['coupleId']?.toString(),
      partnerNickname: json['partnerNickname'],
    );
  }
}

class AuthService {
  static final _storage = FlutterSecureStorage();
  static final String baseUrl = dotenv.env['BASE_URL'] ?? "";

  // ✅ JWT 저장/조회/삭제
  static Future<void> saveToken(String token) async =>
      _storage.write(key: 'jwt_token', value: token);

  static Future<String?> getToken() async =>
      _storage.read(key: 'jwt_token');

  static Future<void> deleteToken() async =>
      _storage.delete(key: 'jwt_token');

  // ✅ Google ID 토큰
  static Future<void> saveGoogleIdToken(String idToken) async =>
      _storage.write(key: 'google_id_token', value: idToken);

  static Future<String?> getGoogleIdToken() async =>
      _storage.read(key: 'google_id_token');

  static Future<void> deleteGoogleIdToken() async =>
      _storage.delete(key: 'google_id_token');

  // ✅ Authorization 헤더 생성
  static Future<Map<String, String>> buildAuthHeader() async {
    final token = await getToken();
    if (token != null) {
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  // ✅ 로그아웃
  static Future<void> logout(BuildContext context) async {
    try {
      await UserApi.instance.logout();
      await deleteToken();
      await deleteGoogleIdToken();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }

  // ✅ JWT에서 userId 추출
  static Future<String?> getUserId() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(payload)['sub']?.toString();
    } catch (e) {
      print('JWT 디코딩 오류: $e');
      return null;
    }
  }

  // ✅ 사용자 프로필 가져오기
  static Future<UserModel?> getUserProfile() async {
    try {
      final headers = await buildAuthHeader();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else if (response.statusCode == 403) {
        print("⚠️ 인증 실패(403): 토큰 만료 가능성");
        await deleteToken();
        return null;
      } else {
        print('프로필 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('프로필 조회 오류: $e');
      return null;
    }
  }

  // ✅ 커플 상태 조회
  static Future<UserModel?> fetchCoupleStatus() async {
    try {
      final headers = await buildAuthHeader();
      final response = await http.get(
        Uri.parse('$baseUrl/couples/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        print('커플 상태 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('커플 상태 조회 오류: $e');
      return null;
    }
  }
}
