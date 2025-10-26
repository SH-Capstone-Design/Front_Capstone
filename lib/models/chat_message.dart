import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  final String chatSessionId;  // 채팅방 ID
  final String senderId;       // 보낸 사람 ID
  final String content;        // 메시지 내용
  final String? senderName;    // 보낸 사람 닉네임
  final String? senderProfileUrl; // 프로필 이미지 URL
  final DateTime? sentTime;      // 전송 시간 (HH:mm 같은 문자열)

  const ChatMessage({
    required this.chatSessionId,
    required this.senderId,
    required this.content,
    this.senderName,
    this.senderProfileUrl,
    this.sentTime,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      chatSessionId: json['chatSessionId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      senderName: json['senderName'] as String?,
      senderProfileUrl: json['senderProfileUrl'] as String?,
      sentTime: json['sentTime'] != null
          ? DateTime.parse(json['sentTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chatSessionId': chatSessionId,
    'senderId': senderId,
    'content': content,
    'senderName': senderName,
    'senderProfileUrl': senderProfileUrl,
    'sentTime': sentTime,
  };
}
