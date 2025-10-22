import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/screens/emotion_result_screen.dart';
import '../providers/chat_repository_provider.dart';

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
          onPressed: () async {
            // 버튼 클릭 후 비동기 작업이 진행될 때 UI가 계속 마운트되어 있는지 체크
            if (!context.mounted) return;

            try {
              // chatRepositoryProvider로 채팅 종료 요청
              final repo = ref.read(chatRepositoryProvider);
              await repo.sendEndChat(chatSessionId: chatSessionId);
              debugPrint('✅ 채팅 종료 요청 완료');

              // WebSocket 연결 종료
              await ref.read(chatSocketControllerProvider.notifier)
                  .disconnect(chatSessionId);
            } catch (e) {
              debugPrint('⚠️ 채팅 종료 요청 실패: $e');
            }

            // 종료 후 EmotionResultScreen으로 이동
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const EmotionResultScreen(),
                ),
              );
            }
          },
          child: const Text('예'),
        ),
        TextButton(
          onPressed: () {
            if (context.mounted) {
              Navigator.of(context).pop(false);
            }
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
