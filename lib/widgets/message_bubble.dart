import 'package:connectbeat/models/chat_message.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.nextMessage, // 바로 아래 메시지 (시간 비교용)
    this.showProfile = true,
  });

  final ChatMessage message;
  final ChatMessage? nextMessage;
  final bool isMine;
  final bool showProfile;

  bool get _shouldShowTime {
    if (nextMessage == null) return true; // 마지막 메시지는 항상 시간 표시
    if (message.sentAt == null || nextMessage!.sentAt == null) return true;

    // 같은 사람 & 같은 시/분이면 시간 숨김
    final sameSender = message.senderId == nextMessage!.senderId;
    final sameMinute =
        message.sentAt!.hour == nextMessage!.sentAt!.hour &&
            message.sentAt!.minute == nextMessage!.sentAt!.minute;
    return !(sameSender && sameMinute);
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = message.senderId == "system";

    final bgColor = isSystem
        ? Colors.black.withOpacity(0.3)
        : (isMine ? Colors.pinkAccent : const Color(0xFFFFDEFF));

    final textColor =
    isSystem ? Colors.white : (isMine ? Colors.white : Colors.black87);

    final align =
    isMine || isSystem ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAxis =
    isMine || isSystem ? MainAxisAlignment.end : MainAxisAlignment.start;

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
                    backgroundImage: message.profileImage != null
                        ? NetworkImage(message.profileImage!)
                        : null,
                    child: message.profileImage == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
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
                    padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    child: Column(
                      crossAxisAlignment: isMine || isSystem
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isMine && !isSystem && showProfile && message.nickname != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.nickname!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        _buildMessageContent(textColor),
                      ],
                    ),
                  ),
                ),
              ),
              if (isMine) const SizedBox(width: 32),
            ],
          ),
          if (_shouldShowTime && !isSystem && message.sentAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.sentAt!),
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Color textColor) {
    switch (message.type?.toUpperCase()) {
      case 'IMAGE':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.content,
            width: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 60, color: Colors.grey),
          ),
        );
      case 'EMOTICON':
        return Image.network(
          message.content,
          width: 80,
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.emoji_emotions_outlined,
              size: 40, color: Colors.grey),
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: textColor,
            fontSize: message.senderId == "system" ? 12 : 16,
            fontStyle:
            message.senderId == "system" ? FontStyle.italic : FontStyle.normal,
          ),
        );
    }
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
