// lib/services/chat_socket_service.dart
// STOMP(WebSocket) 기반 실시간 메시징 래퍼. ChatSocketPort 구현체.

import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';

/// STOMP(WebSocket) 구현체
class StompSocketService implements ChatSocketPort {
  StompSocketService({
    required String url,
    required String Function(String chatSessionId) topicBuilder,
    required String Function(String chatSessionId) sendDestinationBuilder,
    FutureOr<Map<String, String>> Function()? headersBuilder,
    Duration heartbeatIncoming = const Duration(seconds: 10),
    Duration heartbeatOutgoing = const Duration(seconds: 10),
    bool printDebugLog = false,
  })  : _url = url,
        _topicBuilder = topicBuilder,
        _sendDestBuilder = sendDestinationBuilder,
        _headersBuilder = headersBuilder,
        _hbIn = heartbeatIncoming,
        _hbOut = heartbeatOutgoing,
        _debug = printDebugLog;

  final String _url;
  final String Function(String chatSessionId) _topicBuilder;
  final String Function(String chatSessionId) _sendDestBuilder;
  final FutureOr<Map<String, String>> Function()? _headersBuilder;
  final Duration _hbIn;
  final Duration _hbOut;
  final bool _debug;

  StompClient? _client;
  bool _connected = false;
  Completer<void>? _connecting;

  final Map<String, StreamController<ChatMessage>> _sessionCtrls =
  <String, StreamController<ChatMessage>>{};
  final Map<String, void Function()> _sessionUnsubs =
  <String, void Function()>{};

  // ---- ChatSocketPort impl ----

  @override
  Stream<ChatMessage> subscribe(String chatSessionId) {
    final controller = _sessionCtrls.putIfAbsent(
      chatSessionId,
          () => StreamController<ChatMessage>.broadcast(),
    );

    _ensureConnected().then((_) => _subscribeSession(chatSessionId));
    return controller.stream;
  }

  @override
  Future<void> send({
    required String chatSessionId,
    required String senderId,
    required String content,
  }) async {
    await _ensureConnected();
    final dest = _sendDestBuilder(chatSessionId); // → "/app/chat/message"
    final payload = <String, dynamic>{
      'chatSessionId': chatSessionId,
      'senderId': senderId,
      'content': content,
    };
    _client?.send(destination: dest, body: jsonEncode(payload));
    if (_debug) {
      print('[STOMP] SEND → $dest $payload');
    }
  }

  @override
  Future<void> unsubscribe(String chatSessionId) async {
    final unsub = _sessionUnsubs.remove(chatSessionId);
    unsub?.call();
    await _sessionCtrls[chatSessionId]?.close();
    _sessionCtrls.remove(chatSessionId);
  }

  @override
  Future<void> dispose() async {
    for (final e in _sessionUnsubs.values) {
      e();
    }
    _sessionUnsubs.clear();
    for (final ctrl in _sessionCtrls.values) {
      await ctrl.close();
    }
    _sessionCtrls.clear();
    _client?.deactivate();
    _connected = false;
  }

  // ---- internals ----

  Future<void> _ensureConnected() async {
    if (_connected) return;
    if (_connecting != null) return _connecting!.future;

    _connecting = Completer<void>();
    final headers = await _safeHeaders();

    _client = StompClient(
      config: StompConfig(
        url: _url,
        onConnect: _onConnect,
        onStompError: _onStompError,
        onWebSocketError: (dynamic err) {
          if (_debug) {
            print('[STOMP] WS error: $err');
          }
          _connected = false;
        },
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        heartbeatIncoming: _hbIn,
        heartbeatOutgoing: _hbOut,
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
    return _connecting!.future;
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    if (_debug) {
      print('[STOMP] Connected headers=${frame.headers}');
    }
    // 재연결 시 기존 세션들 재구독
    for (final chatSessionId in _sessionCtrls.keys) {
      _subscribeSession(chatSessionId);
    }
    _connecting?.complete();
    _connecting = null;
  }

  void _onStompError(StompFrame frame) {
    _connected = false;
    if (_debug) {
      print('[STOMP] STOMP error: cmd=${frame.command} body=${frame.body}');
    }
  }

  Future<Map<String, String>> _safeHeaders() async {
    try {
      final h = await _headersBuilder?.call();
      return <String, String>{
        if (h != null) ...h,
      };
    } catch (_) {
      return const <String, String>{};
    }
  }

  void _subscribeSession(String chatSessionId) {
    if (!_connected || _client == null) return;

    // 이미 구독 중이면 먼저 해제
    _sessionUnsubs.remove(chatSessionId)?.call();

    final topic = _topicBuilder(chatSessionId); // → "/topic/chat/session/{id}"
    final ctrl = _sessionCtrls[chatSessionId];
    if (ctrl == null) return;

    final unsub = _client!.subscribe(
      destination: topic,
      callback: (StompFrame frame) {
        try {
          if (frame.body == null) return;
          final Map<String, dynamic> jsonMap =
          json.decode(frame.body!) as Map<String, dynamic>;
          final msg = ChatMessage.fromJson(jsonMap);
          if (!ctrl.isClosed) ctrl.add(msg);
          if (_debug) {
            print('[STOMP] RECV ← $topic $jsonMap');
          }
        } catch (e) {
          if (_debug) {
            print('[STOMP] parse error: $e');
          }
        }
      },
    );

    _sessionUnsubs[chatSessionId] = () {
      try {
        if (unsub is void Function()) {
          unsub();
        }
      } catch (_) {}
    };

    if (_debug) {
      print('[STOMP] SUBSCRIBE → $topic');
    }
  }
}
