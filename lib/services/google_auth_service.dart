import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart'; // JWT 저장 클래스

final Logger _logger = Logger('Google Login');

/// 환경 변수에서 BASE_URL 안전하게 가져오기
String getBaseUrl() {
  final String? baseUrl = dotenv.env['BASE_URL'];
  if (baseUrl == null || baseUrl.isEmpty) {
    throw Exception('BASE_URL 환경변수가 없습니다.');
  }
  return baseUrl;
}

class GoogleAuthService {
  // 싱글턴 패턴
  GoogleAuthService._privateConstructor();
  static final GoogleAuthService instance = GoogleAuthService._privateConstructor();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// 메인 구글 로그인 함수 (Firebase 인증, 서버 연동, 네비게이션 포함)
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _logger.warning('구글 로그인 실패 또는 취소');
        _showSnackBar(context, '구글 로그인을 취소했습니다.');
        return;
      }

      // Firebase 인증 추가
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      _logger.info('구글 로그인(Firebase 인증) 성공: ${account.email}');

      final userInfo = await _getGoogleUserInfo(account, context);
      if (userInfo != null) {
        Navigator.pushReplacementNamed(
          context,
          '/profile_setup',
          arguments: userInfo,
        );
      }
    } catch (error) {
      _logger.severe('구글 로그인 실패: $error');
      _showSnackBar(context, '구글 로그인 중 오류가 발생했습니다.');
    }
  }

  /// 구글 로그인 후 백엔드 로그인 및 토큰 저장
  Future<Map<String, dynamic>?> _getGoogleUserInfo(
      GoogleSignInAccount account, BuildContext context) async {
    try {
      final email = account.email;
      final nickname = account.displayName ?? '';
      final photoUrl = account.photoUrl;
      final providerId = account.id;
      final provider = 'google';

      final Map<String, dynamic> payload = {
        'email': email,
        'nickname': nickname,
        'provider': provider,
        'providerId': providerId,
      };

      _logger.info('구글 사용자 정보 추출 성공: $payload');

      final loginUrl = '${getBaseUrl()}/users/login';

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        _logger.info('백엔드 로그인 성공: $resBody');

        final token = resBody['token'];
        if (token != null) {
          await AuthService.saveToken(token);
          _logger.info('JWT 토큰 저장 완료');
        } else {
          _logger.warning('응답에 토큰이 없습니다.');
          _showSnackBar(context, '서버 응답에 토큰이 없습니다.');
        }

        return {
          'nickname': nickname,
          'profileImageUrl': photoUrl,
        };
      } else {
        _logger.warning('백엔드 로그인 실패: ${response.statusCode} - ${response.body}');
        _showSnackBar(context, '서버 로그인 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      _logger.severe('구글 사용자 정보 요청 또는 백엔드 전송 실패: $error');
      _showSnackBar(context, '서버와의 통신 중 오류가 발생했습니다.');
      return null;
    }
  }

  /// 로그아웃
  Future<void> logout(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      _showSnackBar(context, '로그아웃 되었습니다.');
    } catch (e) {
      _logger.severe('구글 로그아웃 실패: $e');
      _showSnackBar(context, '로그아웃 중 오류가 발생했습니다.');
    }
  }

  /// 스낵바로 사용자에게 메시지 표시
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
