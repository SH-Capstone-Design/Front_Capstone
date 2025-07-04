import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import '../../widgets/rounded_button.dart';

class CoupleCodeScreen extends StatelessWidget {
  const CoupleCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final logoHeight = size.height * 0.2;
    final topPadding = size.height * 0.01;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topPadding),

              // 로고: 위쪽에 고정 높이로 배치
              SizedBox(
                height: logoHeight,
                child: Image.asset(
                  AppConstants.logoPath,
                  fit: BoxFit.contain,
                ),
              ),

              const Spacer(flex: 1),

              // 커플 코드 생성 버튼
              RoundedButton(
                text: '커플 코드 생성하기',
                onPressed: () => Navigator.pushNamed(context, '/create-code'),
              ),

              SizedBox(height: size.height * 0.02),

              // 커플 코드 입력 버튼
              RoundedButton(
                text: '커플 코드 입력하기',
                onPressed: () => Navigator.pushNamed(context, '/input-code'),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
