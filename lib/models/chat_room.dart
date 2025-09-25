// lib/models/chat_room.dart

/// 채팅방 정보를 표현하는 모델.
/// 서버에서 세션 생성 시 내려주는 chatSessionId만 포함.
class ChatRoom {
  /// 채팅방 세션 고유 ID (서버에서 발급)
  final String chatSessionId;

  ChatRoom({required this.chatSessionId});

  /// JSON → ChatRoom 변환
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      chatSessionId: json['chatSessionId'] as String,
    );
  }

  /// ChatRoom → JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'chatSessionId': chatSessionId,
    };
  }

  @override
  String toString() => 'ChatRoom(chatSessionId: $chatSessionId)';
}
