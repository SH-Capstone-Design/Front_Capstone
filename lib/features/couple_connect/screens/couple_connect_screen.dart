import 'package:flutter/material.dart';
import '../widgets/couple_code_create_button.dart';
import '../widgets/couple_code_input_button.dart';

class CoupleCodeScreen extends StatelessWidget {
  const CoupleCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: null, // 기능 없음 (아직)
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
                margin: const EdgeInsets.only(bottom: 60),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              CoupleCodeCreateButton(
                onPressed: () {
                  // TODO: 커플 코드 생성 기능 연결
                },
              ),
              const SizedBox(height: 20),
              CoupleCodeInputButton(
                onPressed: () {
                  // TODO: 커플 코드 입력 기능 연결
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
