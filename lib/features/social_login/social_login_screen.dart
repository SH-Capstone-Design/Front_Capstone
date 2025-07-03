import 'package:connectbeat/features/post_login_setup/post_login_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/common/kakao_login_button.dart';
import '../../widgets/common/google_login_button.dart';
import '../../core/services/google_login_service.dart';

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
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostLoginSetupScreen(),
                      ),
                    );
                  } else {
                    print('구글 로그인 실패 또는 취소');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('구글 로그인 실패 또는 취소'),
                      ),
                    );
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
