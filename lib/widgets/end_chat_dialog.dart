import 'package:connectbeat/screens/analysis_result_screen.dart';
import 'package:flutter/material.dart';

class EndChatDialog extends StatelessWidget {
  const EndChatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: const Text(
        '채팅을 종료하시겠습니까?',
        style: TextStyle(fontSize: 18),
      ),
      actions: [
        TextButton(
          // onPressed: () => Navigator.of(context).pop(true), // 예 → true 반환
          onPressed: () {
            // ✅ 바로 결과 화면으로 이동
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const AnalysisResultScreen(),
              ),
            );
          },
          child: const Text('예'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // 아니오 → false 반환
          child: const Text('아니오'),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
