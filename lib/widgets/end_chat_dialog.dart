import 'package:flutter/material.dart';

class EndChatDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const EndChatDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: const Text(
        '채팅을 종료하시겠습니까?',
        style: TextStyle(fontSize: 18),
      ),
      actions: [
        TextButton(
          onPressed: onConfirm,
          child: const Text('예'),
        ),
        TextButton(
          onPressed: onCancel,
          child: const Text('아니오'),
        ),

      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}