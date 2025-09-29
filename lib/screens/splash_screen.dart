// splash_screen.dart
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
    await Future.delayed(const Duration(seconds: 2));

    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final coupleCode = prefs.getString('coupleCode');

    if (token != null && coupleCode != null) {
      // 토큰 + 커플 등록 완료 → 홈 화면으로 이동
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
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
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
