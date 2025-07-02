import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/common/kakao_login_button.dart';
import '../widgets/common/google_login_button.dart';
import '../services/google_login_service.dart';

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
              // ...생략 (UI 코드는 동일)...
              KakaoLoginButton(
                onPressed: () {
                  // TODO: 카카오 로그인 연결
                },
              ),
              const SizedBox(height: 20),
              GoogleLoginButton(
                onPressed: () async {
                  final user = await googleLoginService.signInWithGoogle();
                  if (user != null) {
                    print('구글 로그인 성공: ${user.email}');
                  } else {
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
