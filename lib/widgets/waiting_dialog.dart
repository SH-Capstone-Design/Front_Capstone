import 'package:flutter/material.dart';

class WaitingDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onCancel; // 추가

  const WaitingDialog({super.key, required this.message, this.onCancel});

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
            Navigator.of(context).pop(); // 다이얼로그 닫기
            if (onCancel != null) onCancel!(); // 서버로 취소 이벤트 보내기
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
