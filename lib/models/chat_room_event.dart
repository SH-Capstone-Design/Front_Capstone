// lib/models/chat_room_event.dart

import 'package:flutter/foundation.dart';

@immutable
class ChatRoomEvent {
  final String eventType; // 예: "INVITATION", "USER_JOINED", "CONVERSATION_STARTED", "ERROR"
  final Map<String, dynamic> payload;

  const ChatRoomEvent({
    required this.eventType,
    required this.payload,
  });

  factory ChatRoomEvent.fromJson(Map<String, dynamic> json) {
    return ChatRoomEvent(
      eventType: json['eventType'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'eventType': eventType,
    'payload': payload,
  };
}
