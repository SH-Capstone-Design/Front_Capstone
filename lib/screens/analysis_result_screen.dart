// lib/screens/analysis_result_screen.dart
import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoHeight = size.height * 0.1; // 화면 높이의 10% 크기

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC), // 연한 핑크 배경
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.04),
            // 상단 로고
            Center(
              child: Image.asset(
                AppConstants.logoPath,
                height: logoHeight,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            // ✅ 나중에 감정 분석 결과 UI 요소들 들어갈 자리
            const Expanded(
              child: Center(
                child: Text(
                  '감정 분석 결과가 여기에 표시됩니다.',
                  style: TextStyle(color: Colors.black45, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
