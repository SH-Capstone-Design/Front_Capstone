import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

final Logger _logger = Logger('Kakao Login');

final String baseUrl = dotenv.env['BASE_URL']!;
final String loginUrl = '$baseUrl/users/login';

/// 카카오 로그인 후 백엔드 로그인 및 토큰 저장
Future<Map<String, dynamic>?> _getUserInfo() async {
  try {
    User user = await UserApi.instance.me();

    final email = user.kakaoAccount?.email ?? '';
    final nickname = user.kakaoAccount?.profile?.nickname ?? '';
    final profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;
    final providerId = user.id.toString();
    final provider = 'kakao';

    final Map<String, dynamic> payload = {
      'email': email,
      'nickname': nickname,
      'provider': provider,
      'providerId': providerId,
    };

    _logger.info('사용자 정보 추출 성공: $payload');

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
      }

      return {
        'nickname': nickname,
        'profileImageUrl': profileImageUrl,
      };
    } else {
      _logger.warning('백엔드 로그인 실패: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (error) {
    _logger.severe('사용자 정보 요청 또는 백엔드 전송 실패: $error');
    return null;
  }
}

/// 메인 카카오 로그인 함수
Future<void> signInWithKakao(BuildContext context) async {
  if (await AuthApi.instance.hasToken()) {
    try {
      AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
      _logger.info('토큰 유효성 체크 성공: ${tokenInfo.id} ${tokenInfo.expiresIn}');
      final userInfo = await _getUserInfo();
      if (userInfo != null) {
        Navigator.pushReplacementNamed(
          context,
          '/profile_setup',
          arguments: userInfo,
        );
      }
    } catch (error) {
      if (error is KakaoException && error.isInvalidTokenError()) {
        _logger.warning('토큰 만료: $error');
      } else {
        _logger.severe('토큰 정보 조회 실패: $error');
      }
      await loginWithKakaoAccount(context);
    }
  } else {
    _logger.warning('발급된 토큰 없음');
    await loginWithKakaoAccount(context);
  }
}

/// 카카오톡으로 로그인 시도
Future<void> loginWithKakaoAccount(BuildContext context) async {
  if (await isKakaoTalkInstalled()) {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
      _logger.info('카카오톡으로 로그인 성공: ${token.accessToken}');
      final userInfo = await _getUserInfo();
      if (userInfo != null) {
        Navigator.pushReplacementNamed(
          context,
          '/profile_setup',
          arguments: userInfo,
        );
      }
    } catch (error) {
      _logger.severe('카카오톡으로 로그인 실패: $error');
      if (error is PlatformException && error.code == 'CANCELED') return;
      await _loginWithKakaoAccountFallback(context);
    }
  } else {
    await _loginWithKakaoAccountFallback(context);
  }
}

/// 카카오계정으로 로그인 (fallback)
Future<void> _loginWithKakaoAccountFallback(BuildContext context) async {
  try {
    OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
    _logger.info('카카오계정으로 로그인 성공: ${token.accessToken}');
    final userInfo = await _getUserInfo();
    if (userInfo != null) {
      Navigator.pushReplacementNamed(
        context,
        '/profile_setup',
        arguments: userInfo,
      );
    }
  } catch (error) {
    _logger.severe('카카오계정으로 로그인 실패: $error');
  }
}
