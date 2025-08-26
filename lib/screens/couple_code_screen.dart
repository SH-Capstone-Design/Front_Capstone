import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';

class CoupleCodeScreen extends StatelessWidget {
  const CoupleCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoHeight = size.height * 0.2;
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

                const Spacer(flex: 2),

                // 커플 코드 생성 버튼
                RoundedButton(
                  text: '커플 코드 생성하기',
                  onPressed: () => Navigator.pushNamed(context, '/create-code'),
                ),

                SizedBox(height: size.height * 0.03),

                // 커플 코드 입력 버튼
                RoundedButton(
                  text: '커플 코드 입력하기',
                  onPressed: () => Navigator.pushNamed(context, '/input-code'),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
