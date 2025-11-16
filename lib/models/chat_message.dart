import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  final String chatSessionId;
  final String senderId;
  final String content;
  final String type;
  final String? nickname;
  final String? profileImage;
  final DateTime? sentAt;

  ChatMessage({
    required this.chatSessionId,
    required this.senderId,
    required this.content,
    required this.type,
    this.nickname,
    this.profileImage,
    this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      chatSessionId: json['chatSessionId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      type: json['messageType'] ?? json['type'] ?? 'TEXT', // ✅ 여기 핵심
      nickname: json['nickname'],
      profileImage: json['profileImage'],
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatSessionId': chatSessionId,
      'senderId': senderId,
      'content': content,
      'messageType': type,
      'nickname': nickname,
      'profileImage': profileImage,
      'sentAt': sentAt?.toIso8601String(),
    };
  }
}
