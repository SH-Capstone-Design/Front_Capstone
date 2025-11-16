import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';

class CoupleCodeScreen extends StatelessWidget {
  const CoupleCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE6F3), Color(0xFFFDE6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),

              // 💌 상단 로고 + 타이틀
              Image.asset(
                AppConstants.logoPath,
                height: screenHeight * 0.15,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                '두 사람의 연결을 시작해볼까요?',
                style: TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: screenHeight * 0.025,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),
              // 💌 hello.png 이미지
              Image.asset(
                "assets/images/hello.png",
                width: screenWidth * 0.4,
                height: screenHeight * 0.2,
                fit: BoxFit.contain,
              ),
              SizedBox(height: screenHeight * 0.02),

              // 💬 안내 문구
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Text(
                  '한 사람은 “코드 생성하기”를,\n다른 한 사람은 “코드 입력하기”를 눌러주세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: screenHeight * 0.018,
                    color: Colors.black54,
                  ),
                ),
              ),

              Spacer(),

              // 💕 버튼 영역
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  children: [
                    RoundedButton(
                      text: '커플 코드 생성하기',
                      onPressed: () => Navigator.pushNamed(context, '/create-code'),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    RoundedButton(
                      text: '커플 코드 입력하기',
                      onPressed: () => Navigator.pushNamed(context, '/input-code'),
                    ),
                  ],
                ),
              ),

              Spacer(),

              // 💬 작은 문구
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.03),
                child: Text(
                  '서로의 마음이 닿을 때, 앱을 이용할 수 있습니다. 💞',
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: screenHeight * 0.016,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
