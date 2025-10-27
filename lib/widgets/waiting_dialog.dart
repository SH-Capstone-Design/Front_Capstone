import 'package:flutter/material.dart';

class WaitingDialog extends StatelessWidget {
  final String message;

  const WaitingDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 다이얼로그 닫고 홈 화면으로 이동
            Navigator.of(context).pop(); // 다이얼로그 닫기
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', // 홈 화면 라우트 이름
                  (route) => false, // 기존 화면 모두 제거
            );
          },
          child: const Text(
            '취소',
            style: TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
