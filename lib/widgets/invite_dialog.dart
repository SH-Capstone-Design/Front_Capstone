// lib/widgets/invite_dialog.dart
import 'package:flutter/material.dart';

class InviteDialog extends StatelessWidget {
  final String inviterName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const InviteDialog({
    super.key,
    required this.inviterName,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("초대 알림"),
      content: Text("$inviterName 님이 채팅을 초대했습니다."),
      actions: [
        TextButton(
          onPressed: () {
            onDecline();
            Navigator.of(context).pop();
          },
          child: const Text("거절"),
        ),
        ElevatedButton(
          onPressed: () {
            onAccept();
            Navigator.of(context).pop();
          },
          child: const Text("수락"),
        ),
      ],
    );
  }
}
