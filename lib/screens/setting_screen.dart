import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import '../widgets/rounded_button.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoHeight = size.height * 0.2;
    final topPadding = size.height * 0.01;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          // SafeArea + 화면 내용
          SafeArea(
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

                  SizedBox(height: size.height * 0.01),

                  const Center(
                    child: Text(
                      '설정',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  RoundedButton(
                    text: "디데이 설정",
                    onPressed: () {
                      Navigator.pushNamed(context, '/coupledate');
                    },
                  ),

                  SizedBox(height: size.height * 0.03),

                  RoundedButton(
                    text: "커플 관리",
                    onPressed: () {
                      Navigator.pushNamed(context, '/couplemanage');
                    },
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
