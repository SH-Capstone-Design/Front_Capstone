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

              // 초대 수락 시 자동 join + 구독
              await sendJoin(chatSessionId: chatSessionId);
            }
          }
        } catch (e, st) {
          debugPrint("⚠️ onPersonalEvent 처리 실패: $e\n$st");
        }
      },
    );
  }

  Future<void> subscribeRoom({required String chatSessionId}) async {
    if (_isDisposed) return;
    if (_subscribedRooms.contains(chatSessionId)) return;

    _subscribedRooms.add(chatSessionId);

    await socket.subscribeRoom(
      chatSessionId: chatSessionId,
      onRoomEvent: (data) {
        try {
          if (data.containsKey("eventType")) {
            final event = ChatRoomEvent.fromJson(data);
            _eventController.add(event);
          } else if (data.containsKey("senderId") && data.containsKey("content")) {
            final msg = ChatMessage.fromJson(data);

            // 중복 메시지 체크
            final alreadyExists = _messages.any(
                  (m) => m.senderId == msg.senderId && m.content == msg.content,
            );

            if (!alreadyExists) {
              _messages.add(msg);
              _messageController.add(msg);
            }
          }
        } catch (e) {
          debugPrint("⚠️ onRoomEvent 처리 실패: $e");
        }
      },
    );

    debugPrint("🔔 방 구독 완료 → $chatSessionId");
  }

  bool isSubscribed(String chatSessionId) => _subscribedRooms.contains(chatSessionId);

  Stream<ChatMessage> subscribeMessages(String chatSessionId) => _messageController.stream;
  Stream<ChatRoomEvent> subscribeEvents(String chatSessionId) => _eventController.stream;

  @override
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  }) async {
    if (_isDisposed) return;

    debugPrint("📤 [메시지 전송] → $chatSessionId : $content");

    // 서버 전송
    socket.sendMessage(
      chatSessionId: chatSessionId,
      senderId: senderId,
      content: content,
    );

    // 로컬에도 즉시 반영 (중복 메시지 방지)
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

  /// ✅ 초대 수락 시 join + 구독
  Future<void> sendJoin({required String chatSessionId}) async {
    if (_isDisposed) return;

    debugPrint("📤 [참여 요청] → $chatSessionId");
    socket.sendJoin(chatSessionId: chatSessionId);

    if (!_subscribedRooms.contains(chatSessionId)) {
      await subscribeRoom(chatSessionId: chatSessionId);
    }
  }

  @override
  Future<void> closeSession(String chatSessionId) async {
    await api.closeSession(chatSessionId);
    disconnect();
  }

  void disconnect() {
    if (_isDisposed) return;
    _isDisposed = true;
    try {
      socket.disconnect();
      if (!_messageController.isClosed) _messageController.close();
      if (!_eventController.isClosed) _eventController.close();
      debugPrint("🔌 WebSocket 및 Stream 닫힘");
    } catch (e) {
      debugPrint("⚠️ disconnect 중 오류: $e");
    }
  }

  Stream<ChatRoomEvent> get eventStream => _eventController.stream;
}
