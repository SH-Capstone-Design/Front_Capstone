import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // 1~2초 정도 Splash 표시
    await Future.delayed(const Duration(seconds: 2));

    // JWT 토큰 확인
    final token = await AuthService.getToken();

    // SharedPreferences에서 커플 등록 여부 확인
    final prefs = await SharedPreferences.getInstance();
    final coupleCode = prefs.getString('coupleCode');

    if (token != null && coupleCode != null) {
      // 로그인 + 커플 등록 완료 → 홈 화면
      Navigator.pushReplacementNamed(context, '/home-screen');
    } else {
      // 로그인 안 됨 → 로그인 화면
      Navigator.pushReplacementNamed(context, '/main-screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 배경
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          // 로고
          Center(
            child: SizedBox(
              height: size.height * 0.2,
              child: Image.asset(
                AppConstants.logoPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
