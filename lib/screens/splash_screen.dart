import 'dart:async';
import 'package:connectbeat/services/couple_service.dart';
import 'package:flutter/material.dart';
import 'package:connectbeat/services/auth_service.dart';

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
    // 로고 보여주는 딜레이
    await Future.delayed(const Duration(seconds: 1));

    final token = await AuthService.getToken();
    debugPrint("🔥 JWT 토큰: $token");

    // 1️⃣ 토큰 없으면 메인으로 이동
    if (token == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/main");
      return;
    }

    // 2️⃣ 토큰은 있는데 유저 정보 조회 실패 → 토큰 만료로 판단 → 로그인 이동
    final user = await AuthService.getUserProfile();
    if (!mounted) return;

    if (user == null) {
      debugPrint("❌ 유저 정보 없음 → 토큰 만료로 판단");
      Navigator.pushReplacementNamed(context, "/login");
      return;
    }

    // 3️⃣ 커플 상태 조회
    final couple = await CoupleService.fetchCoupleStatus();
    if (!mounted) return;

    if (couple == null) {
      debugPrint("❌ 커플 정보 조회 실패 → 메인");
      Navigator.pushReplacementNamed(context, "/main");
      return;
    }

    debugPrint("🔥 커플 상태: ${couple["status"]}");

    final status = couple["status"]?.toString() ?? "";

    // 4️⃣ 상태 분기
    if (status == "ACTIVE") {
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      Navigator.pushReplacementNamed(context, "/couple-code");
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
