// lib/widgets/message_bubble.dart
// 말풍선 UI. isMine 여부에 따라 정렬/색상/꼬리 모양이 달라집니다.

import 'package:connectbeat/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:connectbeat/services/chat_repository.dart'; // ChatMessage 모델 참조

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTime = true,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final bgColor = isMine ? Colors.pinkAccent.shade100 : Colors.white;
    final textColor = Colors.black87;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAxis = isMine ? MainAxisAlignment.end : MainAxisAlignment.start;

    final radius = isMine
        ? const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Column(
        crossAxisAlignment: align,
        children: <Widget>[
          Row(
            mainAxisAlignment: mainAxis,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: radius,
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    child: Text(
                      message.content, // ✅ text → content
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
