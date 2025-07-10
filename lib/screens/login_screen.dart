import 'package:flutter/material.dart';
import '../widgets/login_button.dart';
import '../services/kakao_auth_service.dart';
import '../core/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 화면 세로 크기의 20%를 로고 높이로 설정
    final logoHeight = size.height * 0.2;
    // 위쪽 여백 (필요시 사용 가능)
    final topPadding = size.height * 0.01;

    return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppConstants.backgroundPath),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topPadding),

                  SizedBox(
                    height: logoHeight,
                    child: Image.asset(
                      AppConstants.logoPath,
                      fit: BoxFit.contain,
                    ),
                  ),



                  // 로고와 버튼 사이 공간 (flex 비율로 동적 조절)
                  const Spacer(flex: 1),

                  // 카카오 로그인 버튼: 고정 높이 55
                  LoginButton(
                    imagePath: 'assets/images/kakao_login.png',
                    height: 55,
                    onPressed: () => signInWithKakao(context),
                  ),

                  // 버튼 아래 공간 더 넉넉히 주기 (flex 2)
                  const Spacer(flex: 2),

                ], // 나중에 Google 로그인 버튼 등 추가 가능
              ),
            ),
          ),
        ),
    );
  }
}
