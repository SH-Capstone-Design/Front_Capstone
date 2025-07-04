import 'package:flutter/material.dart';
import 'package:connectbeat/core/utils/constants.dart'; // 전역 상수 가져오기
import '../../widgets/common/rounded_button.dart';

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
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                RoundedButton(
                  text: '로그인 하기',
                  textStyle: TextStyle(
                    fontSize: 20,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/social_login'),
                ),
                const SizedBox(height: 16),
                /*RoundedButton(
                  textStyle: TextStyle(
                    fontSize: 20,
                  ),
                  text: '회원가입',
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                ),*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}
