import 'package:flutter/material.dart';
import '../widgets/kakao_login_button.dart';
import '../widgets/google_login_button.dart';
import '../services/google_login_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialLoginScreen extends ConsumerWidget {
  const SocialLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final googleLoginService = GoogleLoginService();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
                margin: const EdgeInsets.only(bottom: 60),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Connect Beat',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              const Text(
                'Rectangle 52',
                style: TextStyle(
                  color: Color(0xFF6B3BF6),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              KakaoLoginButton(
                onPressed: () {
                  // TODO: 카카오 로그인 로직 연결
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Rectangle 53',
                style: TextStyle(
                  color: Color(0xFF6B3BF6),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              GoogleLoginButton(
                onPressed: () async {
                  final user = await googleLoginService.signInWithGoogle();
                  if (user != null) {
                    // 로그인 성공 시 동작 (예: 화면 이동, 토큰 저장 등)
                    print('구글 로그인 성공: ${user.email}');
                  } else {
                    // 로그인 실패/취소
                    print('구글 로그인 실패 또는 취소');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
