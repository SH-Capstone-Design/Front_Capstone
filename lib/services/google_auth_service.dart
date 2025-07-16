import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'auth_service.dart';
import 'auth_repository.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
final AuthRepository _authRepository = AuthRepository();

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final account = await _googleSignIn.signIn();
    if (account == null) return;

    final email = account.email;
    final nickname = account.displayName ?? '';
    final providerId = account.id;

    // 구글 인증 정보 (idToken, accessToken) 가져오기
    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    final accessToken = authentication.accessToken;

    if (idToken == null || accessToken == null) {
      debugPrint('idToken 또는 accessToken이 없습니다. 로그인 실패');
      return;
    }

    final response = await _authRepository.sendGoogleUserToBackend(
      email: email,
      nickname: nickname,
      provider: 'google',
      providerId: providerId,
      profileImageUrl: account.photoUrl,
      idToken: idToken,
      accessToken: accessToken,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final token = body['token'];
      if (token != null) await AuthService.saveToken(token);
      await AuthService.saveGoogleIdToken(idToken);

      Navigator.pushReplacementNamed(
        context,
        '/profile_setup',
        arguments: {
          'nickname': nickname,
          'profileImageUrl': account.photoUrl,
        },
      );
    } else {
      debugPrint('구글 백엔드 로그인 실패: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('구글 로그인 에러: $e');
  }
}
