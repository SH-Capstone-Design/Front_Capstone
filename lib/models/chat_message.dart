// lib/models/chat_message.dart

import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  final String chatSessionId; // 어느 채팅방의 메시지인지
  final String senderId;      // 누가 보낸 메시지인지
  final String content;       // 메시지 내용
  final DateTime createdAt;   // 생성 시각

  const ChatMessage({
    required this.chatSessionId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      chatSessionId: json['chatSessionId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chatSessionId': chatSessionId,
    'senderId': senderId,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}
