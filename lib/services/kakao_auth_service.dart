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

bool _isLoggingIn = false; // ✅ 중복 로그인 방지용 플래그

/// ✅ 카카오 로그인 진입점 (자동 로그인 or 신규 로그인)
Future<void> signInWithKakao(BuildContext context) async {
  if (_isLoggingIn) {
    _logger.warning("⚠️ 이미 로그인 중입니다.");
    return;
  }
  _isLoggingIn = true;

  try {
    print("✅ signInWithKakao() 호출됨");

    // ✅ 1️⃣ 이미 토큰이 존재하면 유효성 검사
    if (await AuthApi.instance.hasToken()) {
      try {
        final tokenInfo = await UserApi.instance.accessTokenInfo();
        _logger.info('토큰 유효: ${tokenInfo.id} 만료까지: ${tokenInfo.expiresIn}초');

        final token = await TokenManagerProvider.instance.manager.getToken();
        if (token == null) throw Exception('토큰 없음');

        final userInfo = await _getUserInfo(accessToken: token.accessToken);
        if (userInfo != null) {
          await _checkCoupleConnection(context, userInfo);
          return;
        }
      } catch (e) {
        _logger.warning('⚠️ 기존 토큰이 만료되었거나 유효하지 않음: $e');
      }
    }

    // ✅ 2️⃣ 토큰이 없거나 만료된 경우 새 로그인 시도
    await _loginWithKakao(context);
  } catch (e) {
    _logger.severe("❌ signInWithKakao() 실패: $e");
  } finally {
    _isLoggingIn = false;
  }
}

/// ✅ 카카오 로그인 (앱 로그인 우선, 실패 시 웹 fallback)
Future<void> _loginWithKakao(BuildContext context) async {
  print("🔥 _loginWithKakao() 실행");

  bool isTalkInstalled = false;
  try {
    isTalkInstalled = await isKakaoTalkInstalled();
  } catch (e) {
    print("⚠️ 시뮬레이터에서는 isKakaoTalkInstalled() 호출 불가 → fallback 사용");
  }

  try {
    if (isTalkInstalled) {
      // ✅ 1️⃣ 카카오톡 앱 로그인 시도
      final OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
      _logger.info('✅ 카카오톡 로그인 성공: ${token.accessToken}');

      final userInfo = await _getUserInfo(accessToken: token.accessToken);
      if (userInfo != null) {
        await _checkCoupleConnection(context, userInfo);
      }
      return; // 👈 앱 로그인 성공 시 종료
    }

    // ✅ 2️⃣ fallback: 웹 로그인
    print("🌐 fallback: 카카오계정 로그인 실행");
    await _loginWithKakaoAccountFallback(context);

  } on PlatformException catch (e) {
    if (e.code == 'CANCELED') {
      print("⚠️ 사용자가 로그인 취소함");
      return;
    }
    _logger.severe("❌ PlatformException 발생: $e");
  } catch (e) {
    _logger.severe("❌ 카카오 로그인 중 오류: $e");
  }
}

/// ✅ fallback (카카오계정 웹 로그인)
Future<void> _loginWithKakaoAccountFallback(BuildContext context) async {
  try {
    final OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
    _logger.info('✅ 카카오계정 로그인 성공: ${token.accessToken}');

    final userInfo = await _getUserInfo(accessToken: token.accessToken);
    if (userInfo != null) {
      await _checkCoupleConnection(context, userInfo);
    }
  } catch (error) {
    _logger.severe('❌ 카카오계정 로그인 실패: $error');
    if (error.toString().contains('REDIRECT_URI_MISMATCH')) {
      print("⚠️ redirectUri 설정 확인 필요 (AndroidManifest or Kakao 콘솔)");
    }
  }
}

