// lib/services/chat_repository_impl.dart
import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_api_service.dart';

/// 소켓 추상화 인터페이스
abstract class ChatSocketPort {
  Future<void> connect({
    required void Function(Map<String, dynamic>) onRoomEvent,
    required void Function(Map<String, dynamic>) onPersonalEvent,
    required String chatSessionId,
    required String userId,
  });

  void sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  });

  void sendInvite({
    required String chatSessionId,
    required String inviteeId,
  });

  void sendJoin({
    required String chatSessionId,
  });

  void sendCategorySelect({
    required String chatSessionId,
    required int categoryId,
  });

  void disconnect();
}

/// ChatRepository 구현체
class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService api;
  final ChatSocketPort socket;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _eventController = StreamController<ChatRoomEvent>.broadcast();

  bool _connected = false;

  ChatRepositoryImpl({
    required this.api,
    required this.socket,
  });

  // ✅ 세션 생성 (REST)
  @override
  Future<ChatRoom> startSession() async {
    return await api.startSession();
  }

  // ✅ 소켓 연결 및 구독 시작
  Future<void> connectSocket({
    required String chatSessionId,
    required String userId,
  }) async {
    if (_connected) return;
    _connected = true;

    await socket.connect(
      chatSessionId: chatSessionId,
      userId: userId,
      onRoomEvent: (data) {
        try {
          // eventType이 있으면 ChatRoomEvent, 없으면 ChatMessage
          if (data.containsKey("eventType")) {
            final event = ChatRoomEvent.fromJson(data);
            _eventController.add(event);
          } else if (data.containsKey("senderId") &&
              data.containsKey("content")) {
            final msg = ChatMessage.fromJson(data);
            _messageController.add(msg);
          }
        } catch (e) {
          print("⚠️ onRoomEvent 처리 실패: $e");
        }
      },
      onPersonalEvent: (data) {
        try {
          if (data.containsKey("eventType")) {
            final event = ChatRoomEvent.fromJson(data);
            _eventController.add(event);

            if (event.eventType == "INVITATION") {
              print("📨 초대장 수신: ${event.payload}");
              // TODO: 필요 시 UI에서 자동 입장 로직 처리 가능
            }
          }
        } catch (e) {
          print("⚠️ onPersonalEvent 처리 실패: $e");
        }
      },
    );
  }

  // ✅ 메시지 스트림 구독
  @override
  Stream<ChatMessage> subscribeMessages(String chatSessionId) {
    return _messageController.stream;
  }

  // ✅ 이벤트 스트림 구독
  Stream<ChatRoomEvent> subscribeEvents() {
    return _eventController.stream;
  }

  // ✅ 메시지 전송
  @override
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  }) async {
    socket.sendMessage(
      chatSessionId: chatSessionId,
      senderId: senderId,
      content: content,
    );
  }

  // ✅ 초대 전송
  Future<void> sendInvite({
    required String chatSessionId,
    required String inviteeId,
  }) async {
    socket.sendInvite(
      chatSessionId: chatSessionId,
      inviteeId: inviteeId,
    );
  }

  // ✅ 참여 전송
  Future<void> sendJoin({
    required String chatSessionId,
  }) async {
    socket.sendJoin(chatSessionId: chatSessionId);
  }

  // ✅ 주제 선택
  Future<void> sendCategorySelect({
    required String chatSessionId,
    required int categoryId,
  }) async {
    socket.sendCategorySelect(
      chatSessionId: chatSessionId,
      categoryId: categoryId,
    );
  }

  // ✅ 세션 종료 (REST)
  @override
  Future<void> closeSession(String chatSessionId) async {
    await api.closeSession(chatSessionId);
    disconnect();
  }

  void disconnect() {
    socket.disconnect();
    _connected = false;

    if (!_messageController.isClosed) _messageController.close();
    if (!_eventController.isClosed) _eventController.close();

    print("🔌 ChatRepositoryImpl: WebSocket 연결 종료 및 StreamController 닫힘");
  }
}
