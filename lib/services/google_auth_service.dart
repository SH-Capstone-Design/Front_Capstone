import 'package:connectbeat/services/couple_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'auth_service.dart';
import 'auth_repository.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);

final AuthRepository _authRepository = AuthRepository();

/// ✅ 구글 로그인 후 커플 상태 확인 및 화면 이동
Future<void> _checkCoupleConnectionGoogle(
    BuildContext context, Map<String, dynamic> userInfo) async {
  final coupleStatus = await CoupleService.fetchCoupleStatus();

  if (coupleStatus != null && coupleStatus["status"] == "ACTIVE") {
    debugPrint('💞 커플 연결됨 → 홈으로 이동');
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    debugPrint('🧍 연결 안 됨 → 프로필 설정 화면으로 이동');
    Navigator.pushReplacementNamed(
      context,
      '/profile-setup',
      arguments: userInfo,
    );
  }
}

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final account = await _googleSignIn.signIn();

    if (account == null) {
      debugPrint('❗ 사용자가 Google 로그인을 취소했습니다.');
      return;
    }

    final nickname = account.displayName ?? '';
    final photoUrl = account.photoUrl;

    final authentication = await account.authentication;
    final idToken = authentication.idToken;

    debugPrint('✅ 구글 로그인 성공');
    debugPrint('🔑 idToken: $idToken');

    if (idToken == null) {
      debugPrint('❌ idToken이 없습니다. 로그인 실패');
      return;
    }

    final response = await _authRepository.sendGoogleUserToBackend(
      idToken: idToken,
    );

    if (response.statusCode == 200) {
      debugPrint('✅ 백엔드 로그인 성공');
      final body = jsonDecode(response.body);
      final token = body['token'];
      final jwtToken = body['jwtToken'];

      if (jwtToken != null) await AuthService.saveToken(jwtToken);
      if (token != null) await AuthService.saveToken(token);

      // ✅ 커플 상태 확인 후 화면 이동
      final userInfo = {
        'nickname': nickname,
        'profileImageUrl': photoUrl,
      };
      await _checkCoupleConnectionGoogle(context, userInfo);
    } else {
      debugPrint('❌ 구글 백엔드 로그인 실패: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('🔥 구글 로그인 에러: $e');
  }
}
