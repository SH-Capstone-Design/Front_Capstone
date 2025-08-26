// 현재 사용할 인메모리 목업(StreamController로 WebSocket 흉내).

// lib/services/chat_repository_mock.dart
// 백엔드 없이 로컬에서 채팅 플로우를 테스트하기 위한 인메모리 목업 구현입니다.
// StreamController로 WebSocket을 흉내내며, 나중에 Impl로 교체만 하면 됩니다.

//실제 연결 시 chat_repository_provider에서
// ChatRepositoryMock() → ChatRepositoryImpl(...)로 교체만 하면 UI/Provider는 수정 불필요.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'chat_repository.dart';

@immutable
class ChatRepositoryMock implements ChatRepository {
  ChatRepositoryMock();

  /// roomId → 메시지 브로드캐스트 스트림 컨트롤러
  final Map<String, StreamController<ChatMessage>> _controllers =
  <String, StreamController<ChatMessage>>{};

  /// roomId → 메시지 버퍼(간단한 히스토리 용도)
  final Map<String, List<ChatMessage>> _buffers =
  <String, List<ChatMessage>>{};

  @override
  Future<ChatRoom> createRoom({
    required String topicId,
    String? topicName,
  }) async {
    // TODO(backend): POST /chat/rooms {topicId} → roomId 수신
    final String roomId = DateTime.now().millisecondsSinceEpoch.toString();
    _controllers[roomId] = StreamController<ChatMessage>.broadcast();
    _buffers[roomId] = <ChatMessage>[];

    return ChatRoom(
      id: roomId,
      topicId: topicId,
      topicName: topicName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<ChatMessage> subscribeMessages(String roomId) {
    // TODO(backend): STOMP 구독으로 대체 (/topic/rooms/{roomId})
    final controller = _controllers[roomId];
    if (controller == null) {
      throw StateError('Room stream not found for id=$roomId');
    }
    return controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    // TODO(backend): STOMP publish (/app/rooms/{roomId}) 또는 REST POST
    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      roomId: roomId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    final controller = _controllers[roomId];
    final buffer = _buffers[roomId];
    if (controller == null || buffer == null) return;

    // 네트워크 지연 흉내 (선택)
    // await Future<void>.delayed(const Duration(milliseconds: 40));

    buffer.add(message);
    controller.add(message);
  }

  @override
  Future<void> closeRoom(String roomId) async {
    // TODO(backend): POST /chat/rooms/{roomId}/close → 분석 파이프라인 트리거
    await _controllers[roomId]?.close();
    _controllers.remove(roomId);
    _buffers.remove(roomId);
  }
}