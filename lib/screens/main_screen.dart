import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 화면 세로 길이의 20%를 로고 높이로 설정
    final logoHeight = size.height * 0.2;
    // 위쪽 여백: 화면 세로 길이의 1%
    final topPadding = size.height * 0.01;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          // 좌우 여백은 고정 24픽셀
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            // 가로 폭 꽉 채우기
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 위쪽 여백
              SizedBox(height: topPadding),

              // 로고: 화면 높이 비율로 크기 조절
              SizedBox(
                height: logoHeight,
                child: Image.asset(
                  AppConstants.logoPath,
                  fit: BoxFit.contain,
                ),
              ),

              // 로고와 버튼 사이 여백을 flex 비율로 유동적으로 조절
              const Spacer(flex: 1),

              // 로그인 버튼
              RoundedButton(
                text: '우리의 추억 쌓으러 가기',
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),

              // 버튼 사이 고정 여백 16px
              const SizedBox(height: 16),

              // 아래쪽 여백 더 넉넉히 flex 2로 설정
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
