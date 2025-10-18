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

/// =======================
/// 🔌 ChatSocketPort (WebSocket 추상화)
/// =======================
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

/// =======================
/// 💬 ChatRepository 구현체 (A ↔ B 실시간 통신)
/// =======================
class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService api;
  final ChatSocketPort socket;
  final Ref ref;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _eventController = StreamController<ChatRoomEvent>.broadcast();

  bool _isDisposed = false;

  ChatRepositoryImpl({
    required this.api,
    required this.socket,
    required this.ref,
  });

  // ---------------------------------------------------------------------------
  // ✅ 1️⃣ 세션 생성 (REST)
  // ---------------------------------------------------------------------------
  @override
  Future<ChatRoom> startSession() async {
    final room = await api.startSession();
    ref.read(sessionControllerProvider.notifier).setSession(room.chatSessionId);
    print("✅ 세션 생성 완료 → ${room.chatSessionId}");
    return room;
  }

  // ---------------------------------------------------------------------------
  // ✅ 2️⃣ 개인 큐(WebSocket) 연결 — 초대 수신 대기
  // ---------------------------------------------------------------------------
  Future<void> connectBase() async {
    if (_isDisposed) return;

    await socket.connectBase(
      onPersonalEvent: (data) async {
        try {
          if (!data.containsKey("eventType")) return;
          final event = ChatRoomEvent.fromJson(data);
          _eventController.add(event);

          // ✅ [B측] 초대 수신 시 자동 join
          if (event.eventType == "INVITATION") {
            final chatSessionId = event.payload?['chatSessionId'] as String?;
            final inviterId = event.payload?['inviterId'] as String?;

            if (chatSessionId != null) {
              print("📨 초대 수신 → 자동 join 시도: $chatSessionId (초대한 사람: $inviterId)");

              // ✅ 세션 상태 저장
              ref.read(sessionControllerProvider.notifier).setSession(chatSessionId);

              // ✅ 방 구독 및 참여
              await subscribeRoom(chatSessionId: chatSessionId);
              await sendJoin(chatSessionId: chatSessionId);

              print("✅ 초대 수락 및 방 참여 완료: $chatSessionId");
            } else {
              print("⚠️ 초대 이벤트에 chatSessionId 없음: ${event.payload}");
            }
          }
        } catch (e, st) {
          print("⚠️ onPersonalEvent 처리 실패: $e");
          print(st);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ✅ 3️⃣ 방 구독 (/topic/chat/room/{chatSessionId})
  // ---------------------------------------------------------------------------
  Future<void> subscribeRoom({required String chatSessionId}) async {
    if (_isDisposed) return;

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

  // ---------------------------------------------------------------------------
  // ✅ 4️⃣ 메시지 스트림 구독
  // ---------------------------------------------------------------------------
  @override
  Stream<ChatMessage> subscribeMessages(String chatSessionId) {
    return _messageController.stream;
  }

  // ---------------------------------------------------------------------------
  // ✅ 5️⃣ 이벤트 스트림 구독
  // ---------------------------------------------------------------------------
  @override
  Stream<ChatRoomEvent> subscribeEvents(String chatSessionId) {
    return _eventController.stream;
  }

  // ---------------------------------------------------------------------------
  // ✅ 6️⃣ 메시지 전송 (A ↔ B)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // ✅ 7️⃣ 초대 전송 (A → B)
  // ---------------------------------------------------------------------------
  Future<void> sendInvite({
    required String chatSessionId,
    required String inviteeId,
  }) async {
    if (inviteeId == "unknown" || inviteeId.isEmpty) {
      print("⚠️ 초대 실패: 상대방 ID가 없습니다.");
      return;
    }
    print("📤 [초대 전송] → $inviteeId");
    socket.sendInvite(chatSessionId: chatSessionId, inviteeId: inviteeId);
  }

  // ---------------------------------------------------------------------------
  // ✅ 8️⃣ 참여 요청 (B → STOMP)
  // ---------------------------------------------------------------------------
  Future<void> sendJoin({
    required String chatSessionId,
  }) async {
    print("📤 [참여 요청] → $chatSessionId");
    socket.sendJoin(chatSessionId: chatSessionId);
  }

  // ---------------------------------------------------------------------------
  // ✅ 9️⃣ 세션 참여 (B → REST /api/chat/join)
  // ---------------------------------------------------------------------------
  Future<void> joinRoom(String chatSessionId) async {
    try {
      final token = await api.getToken();
      if (token == null) throw Exception("토큰이 없습니다. 로그인 필요.");

      final url = Uri.parse("${api.baseUrl}/chat/join");
      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };
      final body = jsonEncode({'chatSessionId': chatSessionId});

      print("📡 [JOIN 요청] → $url");
      print("📡 [JOIN body] → $body");

      final res = await http.post(url, headers: headers, body: body);

      print("📡 [JOIN status] → ${res.statusCode}");
      print("📡 [JOIN response] → ${res.body}");

      if (res.statusCode == 200) {
        print("✅ 세션 참여 성공: $chatSessionId");
      } else {
        throw Exception("세션 참여 실패 (${res.statusCode}): ${res.body}");
      }
    } catch (e) {
      print("❌ joinRoom 실패: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 🔟 연결 해제 및 Stream 닫기
  // ---------------------------------------------------------------------------
  void disconnect() {
    if (_isDisposed) {
      print("⚠️ 이미 dispose된 ChatRepositoryImpl — 중복 disconnect 무시");
      return;
    }
    _isDisposed = true;
    try {
      socket.disconnect();
      if (!_messageController.isClosed) _messageController.close();
      if (!_eventController.isClosed) _eventController.close();
      print("🔌 ChatRepositoryImpl: WebSocket 종료 및 Stream 닫힘");
    } catch (e, st) {
      print("⚠️ disconnect 중 오류: $e\n$st");
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 11️⃣ 세션 종료 (REST)
  // ---------------------------------------------------------------------------
  @override
  Future<void> closeSession(String chatSessionId) async {
    await api.closeSession(chatSessionId);
    disconnect();
  }

  // ---------------------------------------------------------------------------
  // ✅ 12️⃣ eventStream Getter (chat_room_controller용)
  // ---------------------------------------------------------------------------
  Stream<ChatRoomEvent> get eventStream => _eventController.stream;
}
