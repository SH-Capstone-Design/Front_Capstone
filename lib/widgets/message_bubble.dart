import 'package:connectbeat/models/chat_message.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTime = true,
    this.showProfile = true, // 연속 메시지 시 false로 처리 가능
  });

  final ChatMessage message;
  final bool isMine;
  final bool showTime;
  final bool showProfile;

  @override
  Widget build(BuildContext context) {
    final isSystem = message.senderId == "system";

    final bgColor = isSystem
        ? Colors.black.withOpacity(0.3)
        : (isMine ? Colors.pinkAccent : const Color(0xFFFFDEFF));

    final textColor = isSystem
        ? Colors.white
        : (isMine ? Colors.white : Colors.black87);

    final align = isMine || isSystem ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAxis = isMine || isSystem ? MainAxisAlignment.end : MainAxisAlignment.start;

    final radius = isSystem
        ? BorderRadius.circular(12)
        : (isMine
        ? const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
    ));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: mainAxis,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMine && !isSystem && showProfile)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: message.senderProfileUrl != null
                        ? NetworkImage(message.senderProfileUrl!)
                        : null,
                    child: message.senderProfileUrl == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                ),
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
                    child: Column(
                      crossAxisAlignment: isMine || isSystem
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isMine && !isSystem && showProfile && message.senderName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.senderName!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        Text(
                          message.content,
                          style: TextStyle(
                            color: textColor,
                            fontSize: isSystem ? 12 : 16,
                            fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isMine) const SizedBox(width: 32),
            ],
          ),
          if (showTime && !isSystem && message.sentTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.sentTime!),
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
