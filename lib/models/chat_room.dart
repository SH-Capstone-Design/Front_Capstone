/// 채팅방 정보를 표현하는 모델.
/// 서버에서 세션 생성 시 내려주는 chatSessionId만 포함.
class ChatRoom {
  /// 채팅방 세션 고유 ID (서버에서 발급)
  final String chatSessionId;

  ChatRoom({required this.chatSessionId});

  /// JSON → ChatRoom 변환
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final sessionId = json['chatSessionId']
        ?? json['sessionId']
        ?? json['id'];

    if (sessionId == null || (sessionId is String && sessionId.isEmpty)) {
      throw Exception("❌ ChatRoom.fromJson 실패: 올바른 세션 ID가 없음. 응답: $json");
    }

    return ChatRoom(
      chatSessionId: sessionId as String,
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
