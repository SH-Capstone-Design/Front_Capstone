// lib/services/chat_repository_impl.dart
// REST(ChatApiService) + (옵션) WebSocket/STOMP(SocketPort) 조합 리포지토리 구현.
// - ChatRepositoryMock는 로컬 테스트용, 본 파일은 실연동용 진입점입니다.
// - 소켓 미연동 상태에서도 동작하도록 REST 전송 + 로컬 broadcast로 폴백합니다.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_api_service.dart';

/// 소켓 구현이 준비되면 이 포트를 구현해서 주입하세요.
/// (별도 파일로 chat_socket_service.dart를 만들고, STOMP 패키지 연동을 권장)
abstract class ChatSocketPort {
  /// 방 구독 시작. 서버에서 발행되는 메시지를 스트림으로 수신.
  Stream<ChatMessage> subscribe(String roomId);

  /// 메시지 발행(전송)
  Future<void> send({
    required String roomId,
    required String senderId,
    required String text,
    String type = 'text',
  });

  /// 방 구독 해제(옵션)
  Future<void> unsubscribe(String roomId) async {}

  /// 전체 소켓 리소스 정리(옵션)
  Future<void> dispose() async {}
}

@immutable
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatApiService api,
    ChatSocketPort? socket,
  })  : _api = api,
        _socket = socket;

  final ChatApiService _api;
  final ChatSocketPort? _socket;

  /// 소켓 미제공 시 REST 전송 후 UI 업데이트를 위한 로컬 브로드캐스트 컨트롤러
  final Map<String, StreamController<ChatMessage>> _fallbackControllers =
  <String, StreamController<ChatMessage>>{};

  StreamController<ChatMessage> _ctrl(String roomId) {
    return _fallbackControllers.putIfAbsent(
      roomId,
          () => StreamController<ChatMessage>.broadcast(),
    );
  }

  @override
  Future<ChatRoom> createRoom({
    required String topicId,
    String? topicName,
  }) async {
    // REST로 방 생성
    final room = await _api.createRoom(topicId: topicId, topicName: topicName);

    // 소켓을 사용하는 경우, 보통 화면에서 subscribeMessages(room.id)로 구독을 시작합니다.
    // 여기에선 즉시 구독하지 않고 호출측(Provider/Screen)에서 통일된 패턴으로 시작하도록 합니다.
    return room;
  }

  @override
  Stream<ChatMessage> subscribeMessages(String roomId) {
    // 소켓이 있으면 서버 스트림을 그대로 반환
    final socket = _socket;
    if (socket != null) {
      return socket.subscribe(roomId);
    }
    // 없으면 로컬 폴백 스트림 반환(REST 전송 성공 시 내가 보낸 메시지라도 UI에 반영)
    return _ctrl(roomId).stream;
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    // 소켓 우선 전송
    final socket = _socket;
    if (socket != null) {
      await socket.send(roomId: roomId, senderId: senderId, text: text);
      return;
    }

    // 소켓 없으면 REST 전송으로 대체
    await _api.sendMessageRest(roomId: roomId, text: text);

    // 그리고 폴백 스트림으로는 내가 보낸 메시지를 즉시 뿌려 UI 지연 최소화
    final msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      roomId: roomId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    _ctrl(roomId).add(msg);
  }

  @override
  Future<void> closeRoom(String roomId) async {
    // REST로 세션 종료(분석 파이프라인 트리거)
    await _api.closeRoom(roomId);

    // 소켓 구독 해제(있다면)
    await _socket?.unsubscribe(roomId);

    // 로컬 폴백 스트림 정리
    await _fallbackControllers[roomId]?.close();
    _fallbackControllers.remove(roomId);
  }
}