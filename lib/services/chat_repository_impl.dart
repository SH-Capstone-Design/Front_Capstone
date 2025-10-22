import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_api_service.dart';
import 'package:connectbeat/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

abstract class ChatSocketPort {
  Future<void> connectBase({
    required void Function(Map<String, dynamic>) onPersonalEvent,
  });

  Future<void> subscribeRoom({
    required String chatSessionId,
    required void Function(Map<String, dynamic>) onRoomEvent,
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

  void sendEndChat({
    required String chatSessionId,
  });

  void disconnect();
}

class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService api;
  final ChatSocketPort socket;
  final Ref ref;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _eventController = StreamController<ChatRoomEvent>.broadcast();
  bool _isDisposed = false;
  final Set<String> _subscribedRooms = {}; // 중복 구독 방지용
  final List<ChatMessage> _messages = []; // 중복 메시지 체크용

  ChatRepositoryImpl({
    required this.api,
    required this.socket,
    required this.ref,
  });

  @override
  Future<ChatRoom> startSession() async {
    final room = await api.startSession();
    ref.read(sessionControllerProvider.notifier).setSession(room.chatSessionId);
    debugPrint("✅ 세션 생성 완료 → ${room.chatSessionId}");
    return room;
  }

  /// STOMP 연결
  Future<void> connectBase() async {
    if (_isDisposed) return;

    await socket.connectBase(
      onPersonalEvent: (data) async {
        try {
          if (!data.containsKey("eventType")) return;
          final event = ChatRoomEvent.fromJson(data);
          _eventController.add(event);

          if (event.eventType == "INVITATION") {
            final chatSessionId = event.payload['chatSessionId'] as String?;
            final inviterId = event.payload['inviterId'] as String?;

            if (chatSessionId != null) {
              debugPrint("📨 초대 수신 → $chatSessionId (초대한 사람: $inviterId)");
              ref.read(sessionControllerProvider.notifier).setSession(chatSessionId);
              // ❌ 자동 join 제거 → UI에서 수락 시 join 호출
            }
          }
        } catch (e, st) {
          debugPrint("⚠️ onPersonalEvent 처리 실패: $e\n$st");
        }
      },
    );
  }

  /// 채팅방 구독
  Future<void> subscribeRoom({required String chatSessionId}) async {
    if (_isDisposed) return;

    debugPrint("➡️ [subscribeRoom 호출] $chatSessionId");

    // ✅ 이미 구독 중인 방은 다시 구독하지 않음
    if (_subscribedRooms.contains(chatSessionId)) {
      debugPrint("⚠️ 이미 구독 중인 방입니다 → $chatSessionId");
      return;
    }

    _subscribedRooms.add(chatSessionId);
    debugPrint("📡 [구독 등록 완료] → $chatSessionId");

    try {
      await socket.subscribeRoom(
        chatSessionId: chatSessionId,
        onRoomEvent: (data) {
          try {
            // ✅ 이벤트 수신 로그
            debugPrint("📨 [RoomEvent 수신] → ${data.toString()}");

            if (data.containsKey("eventType")) {
              final eventType = data['eventType'];

              // 🔹 채팅 종료 이벤트 별도 처리
              if (eventType == "CONVERSATION_ENDED") {
                debugPrint("❌ [채팅 종료 감지] → $chatSessionId");

                // 이벤트 먼저 스트림에 전달
                final event = ChatRoomEvent.fromJson(data);
                _eventController.add(event);

                // 로컬 상태 정리
                _subscribedRooms.remove(chatSessionId);
                _messages.removeWhere((m) => m.chatSessionId == chatSessionId);

                return; // 종료 이벤트 처리 후 바로 리턴
              }

              // 일반 이벤트 처리
              final event = ChatRoomEvent.fromJson(data);
              debugPrint("🔥 [이벤트 타입 수신] → ${event.eventType}");
              _eventController.add(event);
            } else if (data.containsKey("senderId") && data.containsKey("content")) {
              final msg = ChatMessage.fromJson(data);

              // ✅ 중복 메시지 방지
              final alreadyExists = _messages.any(
                    (m) => m.senderId == msg.senderId && m.content == msg.content,
              );

              if (!alreadyExists) {
                _messages.add(msg);
                _messageController.add(msg);
                debugPrint("💬 [새 메시지 추가] ${msg.senderId}: ${msg.content}");
              } else {
                debugPrint("⚠️ [중복 메시지 무시] ${msg.content}");
              }
            }
          } catch (e, st) {
            debugPrint("⚠️ onRoomEvent 처리 실패: $e\n$st");
          }
        },
      );

      debugPrint("🔔 [STOMP 방 구독 완료] → $chatSessionId");
    } catch (e, st) {
      debugPrint("❌ subscribeRoom 실패: $e\n$st");
    }
  }

  bool isSubscribed(String chatSessionId) => _subscribedRooms.contains(chatSessionId);

  Stream<ChatMessage> subscribeMessages(String chatSessionId) => _messageController.stream;
  Stream<ChatRoomEvent> subscribeEvents(String chatSessionId) => _eventController.stream;
  Stream<ChatRoomEvent> get eventStream => _eventController.stream;

  @override
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  }) async {
    if (_isDisposed) return;

    debugPrint("📤 [메시지 전송] → $chatSessionId : $content");

    socket.sendMessage(
      chatSessionId: chatSessionId,
      senderId: senderId,
      content: content,
    );

    final alreadyExists = _messages.any(
          (m) => m.senderId == senderId && m.content == content,
    );

    if (!alreadyExists) {
      final msg = ChatMessage(
        chatSessionId: chatSessionId,
        senderId: senderId,
        content: content,
      );
      _messages.add(msg);
      _messageController.add(msg);
    }
  }

  Future<void> sendInvite({required String chatSessionId, required String inviteeId}) async {
    if (inviteeId.isEmpty || inviteeId == "unknown") return;
    socket.sendInvite(chatSessionId: chatSessionId, inviteeId: inviteeId);
  }

  Future<void> sendJoin({required String chatSessionId}) async {
    if (_isDisposed) return;
    debugPrint("📤 [참여 요청] → $chatSessionId");
    socket.sendJoin(chatSessionId: chatSessionId);
  }

  /// 🔹 채팅 종료
  @override
  Future<void> sendEndChat({required String chatSessionId}) async {
    if (_isDisposed) return;

    debugPrint("📤 [채팅 종료 요청] → $chatSessionId");

    // 1️⃣ 서버 종료 이벤트 전송
    socket.sendEndChat(chatSessionId: chatSessionId);

    // 2️⃣ 로컬 상태 정리만 수행 (UI 갱신은 서버 브로드캐스트 이벤트로)
    _subscribedRooms.remove(chatSessionId);
    _messages.removeWhere((m) => m.chatSessionId == chatSessionId);
  }

  /// 🔹 세션 종료
  @override
  Future<void> closeSession(String chatSessionId) async {
    if (_isDisposed) return;

    try {
      await sendEndChat(chatSessionId: chatSessionId); // 서버 종료 + 로컬 정리
      await api.closeSession(chatSessionId);          // 서버 DB 종료
      disconnect();                                    // WebSocket 종료
    } catch (e) {
      debugPrint("❌ closeSession 오류: $e");
    }
  }

  /// 🔹 연결 해제
  void disconnect() {
    if (_isDisposed) return;
    _isDisposed = true;

    try {
      socket.disconnect();

      if (!_messageController.isClosed) _messageController.close();
      if (!_eventController.isClosed) _eventController.close();

      _subscribedRooms.clear();
      _messages.clear();

      debugPrint("🔌 WebSocket 및 Stream 닫힘");
    } catch (e) {
      debugPrint("⚠️ disconnect 중 오류: $e");
    }
  }
}
