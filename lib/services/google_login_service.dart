import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleLoginService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '712293359808-okcmufiksaui0tork9pvsk00ravljo2t.apps.googleusercontent.com',
  );

  /// 구글 로그인 → idToken → 서버에 전송 → JWT 반환
  Future<String?> signInAndGetJwtToken() async {
    try {
      // 1. 구글 OAuth 로그인
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // 사용자가 로그인 취소

      // 2. idToken 얻기
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        print('idToken 없음!');
        return null;
      }

      // 3. idToken을 백엔드로 전송 → JWT 발급 요청
      final response = await http.post(
        Uri.parse('http://13.238.142.9:8080//api/auth/google-login'), // 실제 엔드포인트로!
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      // 4. 응답이 성공이면 JWT 반환
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // {"token": "..."} 형태 응답 가정!
        return data['token'];
      } else {
        print('서버 오류: ${response.body}');
        return null;
      }
    } catch (e) {
      print('구글 로그인 또는 서버 요청 에러: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
