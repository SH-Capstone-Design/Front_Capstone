import 'package:google_sign_in/google_sign_in.dart';

class GoogleLoginService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return null;
      }
      return googleUser;
    } catch (e) {
      print('구글 로그인 에러: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
