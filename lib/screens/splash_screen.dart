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
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    final token = await AuthService.getToken();
    debugPrint("🔥 JWT 토큰: $token");

    if (token == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/main");
      return;
    }

    // 유저 정보는 단순 조회
    final user = await AuthService.getUserProfile();

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacementNamed(context, "/login");
      return;
    }

    // ✅ 커플 상태 확인
    final couple = await AuthService.fetchCoupleStatus();
    final status = couple?.status ?? '';
    debugPrint("🔥 커플 상태: $status");

    if (status == "ACTIVE") {
      Navigator.pushReplacementNamed(context, "/home"); // 커플 연결 완료 → 홈
    } else {
      Navigator.pushReplacementNamed(context, "/couple-code"); // 커플 연결 안 됨 → 연결 페이지
    }
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(
          image: AssetImage("assets/images/ConnectBeat_logo.png"),
          width: 180,
          height: 180,
        ),
      ),
    );
  }
}
