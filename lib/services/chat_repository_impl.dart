// lib/services/chat_repository_impl.dart
import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_api_service.dart';

/// 소켓 추상화 인터페이스
abstract class ChatSocketPort {
  /// 서버와 연결 (WebSocket/STOMP 등)
  Future<void> connect({
    required void Function(Map<String, dynamic>) onMessage,
  });

  /// 특정 채팅방 구독
  void subscribeChatRoom(
      String chatSessionId,
      void Function(Map<String, dynamic>) onMessage,
      );

  /// 메시지 전송 (STOMP → /app/chat/message)
  void sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  });

  /// 연결 종료
  void disconnect();
}

/// ChatRepository 구현체
class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService api;
  final ChatSocketPort socket;

  /// 실시간 메시지/이벤트를 흘려보내는 StreamController
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _eventController = StreamController<ChatRoomEvent>.broadcast();

  ChatRepositoryImpl({
    required this.api,
    required this.socket,
  });

  /// ✅ 채팅방 생성 (REST: POST /api/chat/rooms)
  @override
  Future<ChatRoom> startSession() async {
    return await api.startSession();
  }



  /// ✅ 일반 메시지 스트림 구독
  @override
  Stream<ChatMessage> subscribeMessages(String chatSessionId) {
    _ensureSocketConnection();

    socket.subscribeChatRoom(chatSessionId, (data) {
      try {
        if (data.containsKey("senderId") && data.containsKey("content")) {
          final msg = ChatMessage.fromJson(data);
          _messageController.add(msg);
        }
      } catch (e) {
        print("⚠️ 메시지 파싱 실패: $e");
      }
    });

    return _messageController.stream;
  }

  /// ✅ 이벤트 스트림 구독 (INVITATION, USER_JOINED, CONVERSATION_STARTED, CONVERSATION_ENDED, ERROR 등)
  Stream<ChatRoomEvent> subscribeEvents(String chatSessionId) {
    _ensureSocketConnection();

    socket.subscribeChatRoom(chatSessionId, (data) {
      try {
        if (data.containsKey("eventType")) {
          final event = ChatRoomEvent.fromJson(data);
          _eventController.add(event);
        }
      } catch (e) {
        print("⚠️ 이벤트 파싱 실패: $e");
      }
    });

    return _eventController.stream;
  }

  /// ✅ 메시지 전송 (WebSocket)
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

  /// ✅ 채팅방 종료 (REST: POST /api/chat/rooms/end)
  @override
  Future<void> closeSession(String chatSessionId) async {
    await api.closeSession(chatSessionId);

    socket.disconnect();

    // StreamController 안전 종료
    await _messageController.close();
    await _eventController.close();
  }

  /// 내부: 소켓 연결 보장 (중복 connect 방지)
  void _ensureSocketConnection() {
    if (_messageController.isClosed || _eventController.isClosed) {
      throw Exception("❌ StreamController가 이미 닫혀 있습니다.");
    }

    socket.connect(onMessage: (data) {
      try {
        if (data.containsKey("eventType")) {
          final event = ChatRoomEvent.fromJson(data);
          _eventController.add(event);
        } else if (data.containsKey("senderId") && data.containsKey("content")) {
          final msg = ChatMessage.fromJson(data);
          _messageController.add(msg);
        }
      } catch (e) {
        print("⚠️ WebSocket 메시지 처리 실패: $e");
      }
    });
  }
}
