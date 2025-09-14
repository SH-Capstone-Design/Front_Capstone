import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_api_service.dart';

/// WebSocket/STOMP용 포트 (필요 시 구현)
abstract class ChatSocketPort {
  Stream<ChatMessage> subscribe(String chatSessionId);
  Future<void> send({
    required String chatSessionId,
    required String senderId,
    required String content,
  });
  Future<void> unsubscribe(String chatSessionId) async {}
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

  final Map<String, StreamController<ChatMessage>> _fallbackControllers =
  <String, StreamController<ChatMessage>>{};

  StreamController<ChatMessage> _ctrl(String chatSessionId) {
    return _fallbackControllers.putIfAbsent(
      chatSessionId,
          () => StreamController<ChatMessage>.broadcast(),
    );
  }

  @override
  Future<ChatRoom> startSession() async {
    return await _api.startSession();
  }

  @override
  Stream<ChatMessage> subscribeMessages(String chatSessionId) {
    final socket = _socket;
    if (socket != null) {
      return socket.subscribe(chatSessionId);
    }
    return _ctrl(chatSessionId).stream;
  }

  @override
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  }) async {
    final socket = _socket;
    if (socket != null) {
      await socket.send(
        chatSessionId: chatSessionId,
        senderId: senderId,
        content: content,
      );
      return;
    }

    await _api.sendMessageRest(
      chatSessionId: chatSessionId,
      senderId: senderId,
      content: content,
    );

    final msg = ChatMessage(
      chatSessionId: chatSessionId,
      senderId: senderId,
      content: content,
      createdAt: DateTime.now(),
    );
    _ctrl(chatSessionId).add(msg);
  }

  @override
  Future<void> closeSession(String chatSessionId) async {
    await _api.closeSession(chatSessionId);
    await _socket?.unsubscribe(chatSessionId);

    await _fallbackControllers[chatSessionId]?.close();
    _fallbackControllers.remove(chatSessionId);
  }
}
