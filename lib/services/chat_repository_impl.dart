import 'dart:async';
import 'dart:convert';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_api_service.dart';

/// =======================
/// 🔌 ChatSocketPort (WebSocket 추상화)
/// =======================
abstract class ChatSocketPort {
  /// ✅ 서버와 STOMP/WebSocket 연결
  Future<void> connect({
    required void Function(Map<String, dynamic>) onRoomEvent,
    required void Function(Map<String, dynamic>) onPersonalEvent,
    required String chatSessionId,
    required String userId,
  });

  /// ✅ 채팅 메시지 전송 (/app/chat/message)
  void sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  });

  /// ✅ 초대 전송 (/app/chat/invite)
  void sendInvite({
    required String chatSessionId,
    required String inviteeId,
  });

  /// ✅ 참여 전송 (/app/chat/join)
  void sendJoin({
    required String chatSessionId,
  });

  /// ✅ 주제 선택 전송 (/app/chat/category-select)
  void sendCategorySelect({
    required String chatSessionId,
    required int categoryId,
  });

  /// ✅ 연결 종료
  void disconnect();
}

/// =======================
/// 💬 ChatRepository 구현체
/// =======================
class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService api;
  final ChatSocketPort socket;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _eventController = StreamController<ChatRoomEvent>.broadcast();

  bool _connected = false;
  bool _isDisposed = false;

  ChatRepositoryImpl({
    required this.api,
    required this.socket,
  });

  /// ✅ 세션 생성 (REST: POST /api/chat/rooms)
  @override
  Future<ChatRoom> startSession() async {
    return await api.startSession();
  }

  /// ✅ WebSocket 연결
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
      onPersonalEvent: (data) async {
        try {
          if (!data.containsKey("eventType")) return;
          final event = ChatRoomEvent.fromJson(data);
          _eventController.add(event);

          // ✅ 초대 수신 시 자동 참가 로직
          if (event.eventType == "INVITATION") {
            final chatSessionId = event.payload['chatSessionId'] as String?;
            if (chatSessionId != null) {
              print("📨 초대 수신 → 자동 참가 시도: $chatSessionId");
              await sendJoin(chatSessionId: chatSessionId);
            } else {
              print("⚠️ 초대 이벤트 payload에 chatSessionId 없음: ${event.payload}");
            }
          }
        } catch (e) {
          print("⚠️ onPersonalEvent 처리 실패: $e");
        }
      },
    );
  }

  /// ✅ 메시지 스트림 구독
  @override
  Stream<ChatMessage> subscribeMessages(String chatSessionId) {
    return _messageController.stream;
  }

  /// ✅ 이벤트 스트림 구독
  @override
  Stream<ChatRoomEvent> subscribeEvents(String chatSessionId) {
    return _eventController.stream;
  }

  /// ✅ 메시지 전송
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

  /// ✅ 초대 전송
  Future<void> sendInvite({
    required String chatSessionId,
    required String inviteeId,
  }) async {
    print("📤 초대 전송: $inviteeId");
    socket.sendInvite(
      chatSessionId: chatSessionId,
      inviteeId: inviteeId,
    );
  }

  /// ✅ 참여 전송
  Future<void> sendJoin({
    required String chatSessionId,
  }) async {
    print("📤 자동 참여 전송: $chatSessionId");
    socket.sendJoin(chatSessionId: chatSessionId);
  }

  /// ✅ 주제 선택 전송
  @override
  Future<void> sendCategorySelect({
    required String chatSessionId,
    required int categoryId,
  }) async {
    socket.sendCategorySelect(
      chatSessionId: chatSessionId,
      categoryId: categoryId,
    );
  }

  /// ✅ 세션 종료 (REST)
  @override
  Future<void> closeSession(String chatSessionId) async {
    await api.closeSession(chatSessionId);
    disconnect();
  }

  /// ✅ 연결 종료 및 Stream 닫기
  void disconnect() {
    if (_isDisposed) {
      print("⚠️ 이미 dispose된 ChatRepositoryImpl. 중복 disconnect 무시");
      return;
    }
    _isDisposed = true;

    try {
      socket.disconnect();
      _connected = false;

      if (!_messageController.isClosed) _messageController.close();
      if (!_eventController.isClosed) _eventController.close();

      print("🔌 ChatRepositoryImpl: WebSocket 연결 종료 및 StreamController 닫힘");
    } catch (e, st) {
      print("⚠️ disconnect 중 오류 발생: $e");
      print(st);
    }
  }
}
