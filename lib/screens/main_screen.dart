import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart'; // 전역 상수 가져오기
import '../widgets/common/rounded_button.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  margin: const EdgeInsets.only(bottom: 60),
                  color: Colors.white,
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 48, // 원하는 크기로 조절 (예시)
                    fit: BoxFit.contain,
                  ),
                ),
                RoundedButton(
                  text: '로그인 하기',
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                ),
                const SizedBox(height: 16),
                RoundedButton(
                  text: '회원가입',
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
