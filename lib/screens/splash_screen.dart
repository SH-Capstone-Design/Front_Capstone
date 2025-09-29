// splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

    if (token != null) {
      // 토큰 검증
      final isValid = await _validateToken(token);
      if (isValid && coupleCode != null) {
        Navigator.pushReplacementNamed(context, '/home-screen');
        return;
      }
    }

    Navigator.pushReplacementNamed(context, '/main-screen');
  }

  Future<bool> _validateToken(String token) async {
    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final res = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/users/me'),
        headers: headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
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
