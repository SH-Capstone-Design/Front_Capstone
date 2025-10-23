import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EndChatDialog extends ConsumerWidget {
  final String chatSessionId;

  const EndChatDialog({super.key, required this.chatSessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      content: const Text(
        '채팅을 종료하시겠습니까?',
        style: TextStyle(fontSize: 18),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // ✅ 다이얼로그 닫기 & ChatRoomScreen 쪽에서 실제 종료 진행
            Navigator.of(context).pop(true);
          },
          child: const Text('예'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('아니오'),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
