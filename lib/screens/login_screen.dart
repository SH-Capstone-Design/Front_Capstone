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
    final screenHeight = size.height;
    final screenWidth = size.width;

    final gifHeight = screenHeight * 0.22;
    final topPadding = screenHeight * 0.08;
    final buttonWidth = screenWidth * 0.65;
    final buttonHeight = screenHeight * 0.065;
    final elementSpacing = screenHeight * 0.025;
    final textToButtonSpacing = screenHeight * 0.05;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지 + 그라데이션
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppConstants.backgroundPath),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.pink.shade50.withOpacity(0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topPadding),

                  // GIF + 장식 아이콘
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: gifHeight * 0.1,
                        left: screenWidth * 0.2,
                        child: Icon(Icons.favorite,
                            color: Colors.pink.shade200.withOpacity(0.5),
                            size: screenHeight * 0.03),
                      ),
                      Positioned(
                        top: gifHeight * 0.05,
                        right: screenWidth * 0.25,
                        child: Icon(Icons.favorite,
                            color: Colors.pink.shade300.withOpacity(0.5),
                            size: screenHeight * 0.025),
                      ),
                      Positioned(
                        top: gifHeight * 0.3,
                        left: screenWidth * 0.22,
                        child: Icon(Icons.favorite,
                            color: Colors.pink.shade200.withOpacity(0.5),
                            size: screenHeight * 0.03),
                      ),
                      SizedBox(
                        height: gifHeight,
                        child: Image.asset(
                          'assets/images/HeartBeat.gif',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // 텍스트
                  Center(
                    child: Text(
                      '소셜 로그인으로 시작하기',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: textToButtonSpacing),

                  // 카카오 로그인 버튼
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.5),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: LoginButton(
                        imagePath: 'assets/images/Kakao_login_button.png',
                        width: buttonWidth,
                        height: buttonHeight,
                        onPressed: () => signInWithKakao(context),
                      ),
                    ),
                  ),

                  SizedBox(height: elementSpacing),

                  // 구글 로그인 버튼
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.5),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: LoginButton(
                        imagePath: 'assets/images/Google_login_button.png',
                        width: buttonWidth,
                        height: buttonHeight,
                        onPressed: () => signInWithGoogle(context),
                      ),
                    ),
                  ),

                  Spacer(flex: 3),

                  // 하단 감성 문구
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.03),
                    child: Text(
                      '시작을 위해 로그인을 해주세요 💞',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: screenHeight * 0.016,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
