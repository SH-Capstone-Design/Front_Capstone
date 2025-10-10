import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

final Logger _logger = Logger('Kakao Login');

final String baseUrl = dotenv.env['BASE_URL']!;
final String loginUrl = '$baseUrl/users/login';

/// ✅ 카카오 로그인 후 백엔드 로그인 및 JWT 저장
Future<Map<String, dynamic>?> _getUserInfo({
  required String accessToken,
}) async {
  try {
    User user = await UserApi.instance.me();

    final kakaoNickname = user.kakaoAccount?.profile?.nickname ?? '';
    final kakaoProfileImageUrl = user.kakaoAccount?.profile?.profileImageUrl;

    _logger.info('카카오톡 프로필 - 닉네임: $kakaoNickname, 이미지: $kakaoProfileImageUrl');

    final payload = {
      'provider': 'kakao',
      'accessToken': accessToken,
    };

    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final resBody = jsonDecode(utf8.decode(response.bodyBytes));

      final token = resBody['token'];
      final userId = resBody['userId'];
      final nicknameFromBackend = resBody['nickname'];
      final profileImageFromBackend = resBody['profileImage'];

      if (token != null) {
        await AuthService.saveToken(token);
        _logger.info('✅ JWT 토큰 저장 완료');
      }

      return {
        'nickname': nicknameFromBackend ?? kakaoNickname,
        'profileImageUrl': profileImageFromBackend ?? kakaoProfileImageUrl,
        'userId': userId,
      };
    } else {
      _logger.warning('⚠️ 백엔드 로그인 실패: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    _logger.severe('❌ 카카오 로그인/백엔드 전송 실패: $e');
    return null;
  }
}

/// ✅ 로그인 후 서버에서 커플 상태 확인 후 화면 이동
Future<void> _checkCoupleConnection(
    BuildContext context, Map<String, dynamic> userInfo) async {
  final coupleStatus = await AuthService.fetchCoupleStatus();

  if (coupleStatus != null && coupleStatus.status == "ACTIVE") {
    _logger.info('💞 커플 연결됨 → 홈으로 이동');
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    _logger.info('🧍 연결 안 됨 → 프로필 설정 화면으로 이동');
    Navigator.pushReplacementNamed(
      context,
      '/profile-setup',
      arguments: userInfo,
    );
  }
}

/// ✅ 메인 카카오 로그인 함수
Future<void> signInWithKakao(BuildContext context) async {
  print("✅ signInWithKakao() 호출됨");

  if (await AuthApi.instance.hasToken()) {
    try {
      final tokenInfo = await UserApi.instance.accessTokenInfo();
      _logger.info('토큰 유효: ${tokenInfo.id} 만료까지: ${tokenInfo.expiresIn}');

      final OAuthToken? token =
      await TokenManagerProvider.instance.manager.getToken();
      if (token == null) throw Exception('토큰 없음');

      final userInfo = await _getUserInfo(accessToken: token.accessToken);
      print("✅ 로그인 완료. accessToken: ${token.accessToken}");

      if (userInfo != null) {
        await _checkCoupleConnection(context, userInfo);
      }
    } catch (error) {
      _logger.warning('⚠️ 토큰 정보 조회 실패: $error');
      await loginWithKakaoAccount(context);
    }
  } else {
    await loginWithKakaoAccount(context);
  }
}

/// ✅ 카카오톡 앱으로 로그인
Future<void> loginWithKakaoAccount(BuildContext context) async {
  print("🔥 loginWithKakaoAccount() 실행");

  if (await isKakaoTalkInstalled()) {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
      _logger.info('카카오톡 로그인 성공: ${token.accessToken}');

      final userInfo = await _getUserInfo(accessToken: token.accessToken);
      if (userInfo != null) {
        await _checkCoupleConnection(context, userInfo);
      }
    } catch (error) {
      if (error is PlatformException && error.code == 'CANCELED') return;
      await _loginWithKakaoAccountFallback(context);
    }
  } else {
    await _loginWithKakaoAccountFallback(context);
  }
}

/// ✅ 카카오계정 로그인 (Fallback)
Future<void> _loginWithKakaoAccountFallback(BuildContext context) async {
  try {
    OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
    _logger.info('카카오계정 로그인 성공: ${token.accessToken}');

    final userInfo = await _getUserInfo(accessToken: token.accessToken);
    if (userInfo != null) {
      await _checkCoupleConnection(context, userInfo);
    }
  } catch (error) {
    _logger.severe('❌ 카카오계정 로그인 실패: $error');
  }
}
