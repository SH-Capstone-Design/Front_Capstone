import 'dart:async';
import 'dart:convert';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_api_service.dart';
import 'package:connectbeat/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final Set<String> _subscribedRooms = {}; // ✅ 중복 구독 방지용

  ChatRepositoryImpl({
    required this.api,
    required this.socket,
    required this.ref,
  });

  @override
  Future<ChatRoom> startSession() async {
    final room = await api.startSession();
    ref.read(sessionControllerProvider.notifier).setSession(room.chatSessionId);
    print("✅ 세션 생성 완료 → ${room.chatSessionId}");
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
              print("📨 초대 수신 → join: $chatSessionId (초대한 사람: $inviterId)");

              ref.read(sessionControllerProvider.notifier).setSession(chatSessionId);

              // ✅ 이전 대화 불러오기 (초대받은 사람도 바로 표시)
              final pastMessages = await api.getMessages(chatSessionId);
              for (final msg in pastMessages) {
                _messageController.add(msg);
              }

              // ✅ WebSocket 구독 및 참여
              await subscribeRoom(chatSessionId: chatSessionId);
              await sendJoin(chatSessionId: chatSessionId);

              print("✅ 초대 수락 및 방 참여 완료: $chatSessionId");
            }
          }
        } catch (e, st) {
          print("⚠️ onPersonalEvent 처리 실패: $e\n$st");
        }
      },
    );
  }

  Future<void> subscribeRoom({required String chatSessionId}) async {
    if (_isDisposed) return;
    if (_subscribedRooms.contains(chatSessionId)) {
      print("⚠️ 이미 구독 중인 방 → 중복 subscribeRoom() 무시");
      return;
    }

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
            _messageController.add(msg);
          }
        } catch (e) {
          print("⚠️ onRoomEvent 처리 실패: $e");
        }
      },
    );
    print("🔔 방 구독 완료 → $chatSessionId");
  }

  @override
  Stream<ChatMessage> subscribeMessages(String chatSessionId) =>
      _messageController.stream;

  @override
  Stream<ChatRoomEvent> subscribeEvents(String chatSessionId) =>
      _eventController.stream;

  @override
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  }) async {
    print("📤 [메시지 전송] → $chatSessionId : $content");
    socket.sendMessage(
      chatSessionId: chatSessionId,
      senderId: senderId,
      content: content,
    );
  }

  Future<void> sendInvite({
    required String chatSessionId,
    required String inviteeId,
  }) async {
    if (inviteeId.isEmpty || inviteeId == "unknown") {
      print("⚠️ 초대 실패: 잘못된 ID");
      return;
    }
    print("📤 [초대 전송] → $inviteeId");
    socket.sendInvite(chatSessionId: chatSessionId, inviteeId: inviteeId);
  }

  Future<void> sendJoin({required String chatSessionId}) async {
    print("📤 [참여 요청] → $chatSessionId");
    socket.sendJoin(chatSessionId: chatSessionId);
  }

  Future<void> joinRoom(String chatSessionId) async {
    try {
      final token = await api.getToken();
      if (token == null) throw Exception("토큰 없음");

      final url = Uri.parse("${api.baseUrl}/chat/join");
      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };
      final body = jsonEncode({'chatSessionId': chatSessionId});
      final res = await http.post(url, headers: headers, body: body);

      print("📡 JOIN 응답: ${res.statusCode}");
      if (res.statusCode != 200) throw Exception(res.body);
    } catch (e) {
      print("❌ joinRoom 실패: $e");
      rethrow;
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
      print("🔌 WebSocket 및 Stream 닫힘");
    } catch (e) {
      print("⚠️ disconnect 중 오류: $e");
    }
  }

  Stream<ChatRoomEvent> get eventStream => _eventController.stream;
}
