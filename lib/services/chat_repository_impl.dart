import 'dart:async';
import 'dart:io';
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
  Future<void> connectBase({required void Function(Map<String, dynamic>) onPersonalEvent});
  Future<void> subscribeRoom({required String chatSessionId, required void Function(Map<String, dynamic>) onRoomEvent});
  void sendMessage({required String chatSessionId, required String senderId, required String content, required String messageType});
  void sendInvite({required String chatSessionId, required String inviteeId});
  void sendJoin({required String chatSessionId});
  void sendEndChat({required String chatSessionId});
  void sendCancel({required String chatSessionId});
  void sendImageMessage({required String chatSessionId, required String senderId, required String imageUrl});
  void sendEmoticonMessage({required String chatSessionId, required String senderId, required String emoticonUrl});
  void disconnect();
}

class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService api;
  final ChatSocketPort socket;
  final Ref ref;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _eventController = StreamController<ChatRoomEvent>.broadcast();

  bool _isDisposed = false;
  final Set<String> _subscribedRooms = {};
  final List<ChatMessage> _messages = [];

  ChatRepositoryImpl({
    required this.api,
    required this.socket,
    required this.ref,
  });

  void _checkDisposed() {
    if (_isDisposed) throw StateError("ChatRepository is disposed");
  }

  Stream<ChatRoomEvent> get eventStream => _eventController.stream;

  /// 세션 시작
  @override
  Future<ChatRoom> startSession() async {
    _checkDisposed();
    final room = await api.startSession();
    ref.read(sessionControllerProvider.notifier).setSession(room.chatSessionId);
    debugPrint("✅ 세션 생성 완료 → ${room.chatSessionId}");
    return room;
  }

  /// WebSocket 기본 연결
  Future<void> connectBase() async {
    _checkDisposed();
    await socket.connectBase(
      onPersonalEvent: (data) async {
        try {
          if (!data.containsKey("eventType")) return;
          final event = ChatRoomEvent.fromJson(data);
          _eventController.add(event);

          switch (event.eventType) {
            case "INVITATION":
              final chatSessionId = event.payload['chatSessionId'] as String?;
              final inviterId = event.payload['inviterId'] as String?;
              if (chatSessionId != null) {
                debugPrint("📨 초대 수신 → $chatSessionId (초대한 사람: $inviterId)");
                ref.read(sessionControllerProvider.notifier).setSession(chatSessionId);
              }
              break;
            case "INVITATION_CANCELED":
            case "INVITATION_REJECTED":
              final chatSessionId = event.payload['chatSessionId'] as String?;
              if (chatSessionId != null) {
                debugPrint("🚫 초대 취소/거절 → ${event.eventType}");
                _subscribedRooms.remove(chatSessionId);
              }
              break;
          }
        } catch (e, st) {
          debugPrint("⚠️ onPersonalEvent 처리 실패: $e\n$st");
        }
      },
    );
  }

  /// 채팅방 구독
  Future<void> subscribeRoom({required String chatSessionId}) async {
    _checkDisposed();
    if (_subscribedRooms.contains(chatSessionId)) return;

    _subscribedRooms.add(chatSessionId);
    debugPrint("📡 방 구독 완료 → $chatSessionId");

    await socket.subscribeRoom(
      chatSessionId: chatSessionId,
      onRoomEvent: (data) {
        try {
          if (data.containsKey("eventType")) {
            final event = ChatRoomEvent.fromJson(data);
            _eventController.add(event);

            if (event.eventType == "CONVERSATION_ENDED") {
              _subscribedRooms.remove(chatSessionId);
              _messages.removeWhere((m) => m.chatSessionId == chatSessionId);
              debugPrint("❌ 대화 종료 → $chatSessionId");
            }
          } else if (data.containsKey("senderId") && data.containsKey("content")) {
            final typeStr = (data['messageType'] as String?)?.toUpperCase() ?? 'TEXT';
            final msg = ChatMessage(
              chatSessionId: data['chatSessionId'] as String,
              senderId: data['senderId'] as String,
              content: data['content'] as String,
              type: typeStr,
              nickname: data['NickName'] as String?,
              profileImage: data['profileImage'] as String?,
              sentAt: data['sentAt'] != null ? DateTime.parse(data['sentAt']) : null,
            );

            if (!_messages.any((m) => m.senderId == msg.senderId && m.content == msg.content)) {
              _messages.add(msg);
              _messageController.add(msg);
              debugPrint("💬 새 메시지 수신 (${msg.type}): ${msg.content}");
            }
          }
        } catch (e, st) {
          debugPrint("⚠️ onRoomEvent 처리 실패: $e\n$st");
        }
      },
    );
  }

  bool isSubscribed(String chatSessionId) => _subscribedRooms.contains(chatSessionId);

  @override
  Stream<ChatMessage> subscribeMessages(String chatSessionId) => _messageController.stream;
  @override
  Stream<ChatRoomEvent> subscribeEvents(String chatSessionId) => _eventController.stream;

  /// 일반 메시지 전송
  @override
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
    String type = 'TEXT',
  }) async {
    _checkDisposed();
    socket.sendMessage(
      chatSessionId: chatSessionId,
      senderId: senderId,
      content: content,
      messageType: type.toUpperCase(),
    );

    if (!_messages.any((m) => m.senderId == senderId && m.content == content)) {
      final msg = ChatMessage(
        chatSessionId: chatSessionId,
        senderId: senderId,
        content: content,
        type: type.toUpperCase(),
      );
      _messages.add(msg);
      _messageController.add(msg);
      debugPrint("💬 메시지 전송 (${type.toUpperCase()}): $content");
    }
  }

  /// 이미지 메시지 전송
  Future<void> sendImageMessage({
    required String chatSessionId,
    required String senderId,
    required File imageFile,
  }) async {
    _checkDisposed();
    final imageUrl = await api.uploadChatImage(imageFile);

    await sendMessage(
      chatSessionId: chatSessionId,
      senderId: senderId,
      content: imageUrl,
      type: 'IMAGE',
    );
  }

  /// 이모티콘 메시지 전송
  Future<void> sendEmoticonMessage({
    required String chatSessionId,
    required String senderId,
    required String emoticonUrl,
  }) async {
    _checkDisposed();
    await sendMessage(
      chatSessionId: chatSessionId,
      senderId: senderId,
      content: emoticonUrl,
      type: 'EMOTICON',
    );
  }

  /// 초대 관련
  Future<void> sendInvite({required String chatSessionId, required String inviteeId}) async {
    _checkDisposed();
    if (inviteeId.isEmpty || inviteeId == "unknown") return;
    if (!_subscribedRooms.contains(chatSessionId)) {
      await subscribeRoom(chatSessionId: chatSessionId);
    }
    socket.sendInvite(chatSessionId: chatSessionId, inviteeId: inviteeId);
    debugPrint("📨 초대 전송 → $chatSessionId to $inviteeId");
  }

  /// 거절 및 취소 공용
  Future<void> sendCancelInvitation({required String chatSessionId}) async {
    await sendCancel(chatSessionId: chatSessionId);
  }

  Future<void> sendCancel({required String chatSessionId}) async {
    _checkDisposed();
    socket.sendCancel(chatSessionId: chatSessionId);
  }

  Future<void> sendJoin({required String chatSessionId}) async {
    _checkDisposed();
    socket.sendJoin(chatSessionId: chatSessionId);
  }

  /// 채팅 종료
  @override
  Future<void> sendEndChat({required String chatSessionId}) async {
    _checkDisposed();
    socket.sendEndChat(chatSessionId: chatSessionId);

    final event = ChatRoomEvent(eventType: "CONVERSATION_ENDED", payload: {"chatSessionId": chatSessionId});
    _eventController.add(event);
    _subscribedRooms.remove(chatSessionId);
    _messages.removeWhere((m) => m.chatSessionId == chatSessionId);
  }

  /// 세션 종료 + 리포트 생성
  @override
  Future<void> closeSession(String chatSessionId) async {
    _checkDisposed();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final report = await generateReportWithRetry(chatSessionId: chatSessionId);
      if (report != null) debugPrint("✅ 리포트 생성 성공: ${report['reportId']}");

      socket.sendEndChat(chatSessionId: chatSessionId);
      debugPrint("📤 WebSocket → 대화 종료 요청 전송 ($chatSessionId)");
    } catch (e, st) {
      debugPrint("🚨 closeSession 오류: $e\n$st");
    } finally {
      disconnect();
    }
  }

  /// 리포트 재시도 조회
  @override
  Future<Map<String, dynamic>?> generateReportWithRetry({
    required String chatSessionId,
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 1),
  }) async {
    _checkDisposed();
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      final report = await ChatReportService.getReportBySession(chatSessionId);
      if (report != null) return report;
      await Future.delayed(interval);
    }
    return null;
  }

  /// 대기 중 초대 확인
  @override
  Future<Map<String, dynamic>?> checkPendingInvitation() async {
    _checkDisposed();
    try {
      final pending = await api.checkPendingInvitation();
      if (pending != null) {
        debugPrint("📬 대기 중 초대 발견 → ${pending['chatSessionId']}");
      } else {
        debugPrint("✅ 대기 중 초대 없음");
      }
      return pending;
    } catch (e) {
      debugPrint("⚠️ checkPendingInvitation 실패: $e");
      return null;
    }
  }

  /// 연결 해제
  void disconnect() {
    if (_isDisposed) return;
    _isDisposed = true;

    socket.disconnect();
    if (!_messageController.isClosed) _messageController.close();
    if (!_eventController.isClosed) _eventController.close();

    _subscribedRooms.clear();
    _messages.clear();
    debugPrint("🔌 WebSocket 및 Stream 닫힘");
  }
}
