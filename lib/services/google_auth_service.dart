import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'auth_service.dart';
import 'auth_repository.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
scopes: ['email', 'profile'],
);

final AuthRepository _authRepository = AuthRepository();

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
// accessToken은 선택사항, 필요 없으면 빼도 됨
// accessToken: authentication.accessToken,
);

if (response.statusCode == 200) {
debugPrint('✅ 백엔드 로그인 성공');
final body = jsonDecode(response.body);
final token = body['token'];
final jwtToken = body['jwtToken']; // ✅ 올바른 키 사용
if (jwtToken != null) {
  await AuthService.saveToken(jwtToken);
  await AuthService.saveGoogleIdToken(idToken); // 원하면 원본 토큰도 저장
}

if (token != null) {
await AuthService.saveToken(token);
await AuthService.saveGoogleIdToken(idToken);
}

Navigator.pushReplacementNamed(
context,
'/profile_setup',
arguments: {
'nickname': nickname,
'profileImageUrl': photoUrl,
},
);
} else {
debugPrint('❌ 구글 백엔드 로그인 실패: ${response.statusCode}');
}
} catch (e) {
debugPrint('🔥 구글 로그인 에러: $e');
}
}
