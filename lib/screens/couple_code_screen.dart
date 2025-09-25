import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';

class CoupleCodeScreen extends StatelessWidget {
  const CoupleCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoHeight = size.height * 0.2;
    final topPadding = size.height * 0.02; // 상단 여백
    final textSpacing = size.height * 0.02; // 로고와 텍스트 간격
    final buttonSpacing = size.height * 0.02; // 버튼 간 간격

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

                SizedBox(height: textSpacing),

                // 커플 연결 텍스트
                const Center(
                  child: Text(
                    '커플 연결하기',
                    style: TextStyle(
                      fontFamily: 'GowunBatang',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Spacer를 활용해 버튼 위치 조절
                Spacer(flex: 2),

                // 커플 코드 생성 버튼
                RoundedButton(
                  text: '커플 코드 생성하기',
                  onPressed: () => Navigator.pushNamed(context, '/create-code'),
                ),

                SizedBox(height: buttonSpacing),

                // 커플 코드 입력 버튼
                RoundedButton(
                  text: '커플 코드 입력하기',
                  onPressed: () => Navigator.pushNamed(context, '/input-code'),
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
