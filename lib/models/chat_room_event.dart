// lib/models/chat_room_event.dart

/// 채팅방 내에서 발생하는 시스템 이벤트 모델.
/// - eventType: 이벤트 종류 (INVITATION, USER_JOINED, CONVERSATION_STARTED, CONVERSATION_ENDED 등)
/// - payload: 이벤트에 따라 달라지는 데이터(Map 또는 String 등)
class ChatRoomEvent {
  /// 이벤트 타입 (예: "INVITATION", "USER_JOINED", "CONVERSATION_ENDED")
  final String eventType;

  /// 이벤트 데이터 (상황별로 구조가 다르므로 dynamic 처리)
  final dynamic payload;

  ChatRoomEvent({
    required this.eventType,
    required this.payload,
  });

  /// JSON → ChatRoomEvent 변환
  factory ChatRoomEvent.fromJson(Map<String, dynamic> json) {
    return ChatRoomEvent(
      eventType: json['eventType'] as String,
      payload: json['payload'],
    );
  }

  /// ChatRoomEvent → JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType,
      'payload': payload,
    };
  }

  @override
  String toString() => 'ChatRoomEvent(eventType: $eventType, payload: $payload)';
}
