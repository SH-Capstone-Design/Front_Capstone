import 'package:connectbeat/models/chat_message.dart';
import 'package:flutter/material.dart';

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
    final bgColor = isMine
        ? Colors.white
        : const Color(0xFFFFDEFF); // 연한 파스텔 핑크
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
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: radius,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    child: Text(
                      message.content,
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
                _formatTime(DateTime.now()),
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
