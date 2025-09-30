// lib/models/chat_message.dart

import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  final String chatSessionId; // 채팅방 ID
  final String senderId;      // 보낸 사람 ID
  final String content;       // 메시지 내용

  const ChatMessage({
    required this.chatSessionId,
    required this.senderId,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      chatSessionId: json['chatSessionId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chatSessionId': chatSessionId,
    'senderId': senderId,
    'content': content,
  };
}
