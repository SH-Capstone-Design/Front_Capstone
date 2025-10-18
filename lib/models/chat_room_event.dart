// lib/models/chat_room_event.dart

import 'package:flutter/foundation.dart';

@immutable
class ChatRoomEvent {
  final String eventType; // 예: "INVITATION", "USER_JOINED", "CONVERSATION_STARTED", "ERROR"
  final String? chatSessionId; // payload 안에 있으면 꺼내서 저장
  final Map<String, dynamic> payload;

  const ChatRoomEvent({
    required this.eventType,
    this.chatSessionId,
    required this.payload,
  });

  factory ChatRoomEvent.fromJson(Map<String, dynamic> json) {
    final payload = Map<String, dynamic>.from(json['payload'] as Map);
    return ChatRoomEvent(
      eventType: json['eventType'] as String,
      chatSessionId: payload['chatSessionId']?.toString(), // payload에서 chatSessionId 추출
      payload: payload,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'eventType': eventType,
    'payload': payload,
  };
}
