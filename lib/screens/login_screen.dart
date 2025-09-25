import 'package:flutter/material.dart';
import '../widgets/login_button.dart';
import '../services/kakao_auth_service.dart';
import '../services/google_auth_service.dart';
import '../core/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final gifHeight = size.height * 0.2; // 로고 대신 GIF 높이
    final topPadding = size.height * 0.1;
    final buttonWidth = size.width * 0.55;
    final buttonHeight = 55.0;
    final elementSpacing = size.height * 0.02;
    final textToButtonSpacing = size.height * 0.05;

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
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topPadding),

                // GIF 로고
                SizedBox(
                  height: gifHeight,
                  child: Image.asset(
                    'assets/images/HeartBeat.gif',
                    fit: BoxFit.contain,
                  ),
                ),

                Spacer(flex: 2),

                // 텍스트
                const Center(
                  child: Text(
                    '소셜 로그인으로 시작하기',
                    style: TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: textToButtonSpacing),

                // 카카오 로그인 버튼
                LoginButton(
                  imagePath: 'assets/images/Kakao_login_button.png',
                  width: buttonWidth,
                  height: buttonHeight,
                  onPressed: () => signInWithKakao(context),
                ),

                SizedBox(height: elementSpacing),

                // 구글 로그인 버튼
                LoginButton(
                  imagePath: 'assets/images/Google_login_button.png',
                  width: buttonWidth,
                  height: buttonHeight,
                  onPressed: () => signInWithGoogle(context),
                ),

                // 남는 공간 채우기
                Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
