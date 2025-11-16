import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 화면 비율 기반 설정
    final logoHeight = size.height * 0.2;       // 로고 높이
    final topPadding = size.height * 0.1;       // 상단 여백
    final textSpacing = size.height * 0.02;     // 텍스트 간격
    final buttonHeight = size.height * 0.07;    // 버튼 높이
    final buttonFontSize = size.height * 0.025; // 버튼 글자 크기
    final titleFontSize = size.height * 0.03;   // 텍스트 글자 크기

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topPadding),

                // 로고
                SizedBox(
                  height: logoHeight,
                  child: Image.asset(
                    AppConstants.logoPath,
                    fit: BoxFit.contain,
                  ),
                ),

                Spacer(flex: 2),

                // 감정 분석 멘트
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '하루 10분, 연인과 대화를 통해',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: textSpacing),
                    Text(
                      '오늘 하루 감정을 알아보다.',
                      style: TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.04),

                // 시작하기 버튼
                SizedBox(
                  height: buttonHeight,
                  child: RoundedButton(
                    text: '시작하기',
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
