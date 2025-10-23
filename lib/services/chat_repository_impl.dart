import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_api_service.dart';
import 'package:connectbeat/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:connectbeat/services/chat_report_service.dart';

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
            debugPrint("📨 [RoomEvent 수신] → ${data.toString()}");

            if (data.containsKey("eventType")) {
              final eventType = data['eventType'];

              if (eventType == "CONVERSATION_ENDED") {
                debugPrint("❌ [채팅 종료 감지] → $chatSessionId");

                final event = ChatRoomEvent.fromJson(data);
                _eventController.add(event);

                _subscribedRooms.remove(chatSessionId);
                _messages.removeWhere((m) => m.chatSessionId == chatSessionId);
                return;
              }

              final event = ChatRoomEvent.fromJson(data);
              debugPrint("🔥 [이벤트 타입 수신] → ${event.eventType}");
              _eventController.add(event);
            } else if (data.containsKey("senderId") && data.containsKey("content")) {
              final msg = ChatMessage.fromJson(data);

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

  /// 🔹 채팅 종료 (STOMP 브로드캐스트)
  @override
  Future<void> sendEndChat({required String chatSessionId}) async {
    if (_isDisposed) return;
    debugPrint("📤 [채팅 종료 요청] → $chatSessionId");
    try {
      socket.sendEndChat(chatSessionId: chatSessionId);
      _subscribedRooms.remove(chatSessionId);
      _messages.removeWhere((m) => m.chatSessionId == chatSessionId);
    } catch (e) {
      debugPrint("⚠️ sendEndChat 실패: $e");
    }
  }

  /// 🔹 채팅 세션 종료 + 리포트 생성
  @override
  Future<void> closeSession(String chatSessionId) async {
    if (_isDisposed) return;
    try {
      // 1️⃣ 리포트 먼저 생성
      const feedback = "이번 대화의 감정 분석 결과입니다.";
      await Future.delayed(const Duration(milliseconds: 500)); // DB 커밋 대기
      final report = await ChatReportService.generateReport(
        chatSessionId: chatSessionId,
        feedback: feedback,
      );

      if (report != null) {
        debugPrint("✅ 리포트 생성 성공: ${report['reportId']}");
      } else {
        debugPrint("⚠️ 리포트 생성 실패 (null 응답)");
      }

      // 2️⃣ 세션 종료 API 호출
      await api.closeSession(chatSessionId);
      debugPrint("🛑 채팅 세션 종료 완료: $chatSessionId");
    } catch (e, st) {
      debugPrint("🚨 closeSession() 중 오류 발생: $e\n$st");
    } finally {
      disconnect();
      debugPrint("🔌 STOMP/WebSocket 연결 해제 완료");
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
