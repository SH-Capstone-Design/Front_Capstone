// lib/services/chat_socket_service.dart
// STOMP(WebSocket) 기반 실시간 메시징 래퍼. ChatSocketPort 구현체.
// - 패키지: stomp_dart_client (pubspec.yaml에 추가 필요)
// - 용도: 방별 구독/발행, 재연결/재구독, 토큰 헤더 부착 등 공통 처리
// - 주의: 백엔드 경로/헤더 규격 확정 이후, topic/send 빌더만 맞추면 동작

import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:stomp_dart_client/stomp_handler.dart'; // StompUnsubscribe (구버전 호환)

import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';

/// STOMP(WebSocket) 구현체
class StompSocketService implements ChatSocketPort {
  StompSocketService({
    required String url,
    required String Function(String roomId) topicBuilder,
    required String Function(String roomId) sendDestinationBuilder,
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
  final String Function(String roomId) _topicBuilder;
  final String Function(String roomId) _sendDestBuilder;
  final FutureOr<Map<String, String>> Function()? _headersBuilder;
  final Duration _hbIn;
  final Duration _hbOut;
  final bool _debug;

  StompClient? _client;
  bool _connected = false;
  Completer<void>? _connecting;

  final Map<String, StreamController<ChatMessage>> _roomCtrls = <String, StreamController<ChatMessage>>{};
  final Map<String, void Function()> _roomUnsubs = <String, void Function()>{};

  // ---- ChatSocketPort impl ----

  @override
  Stream<ChatMessage> subscribe(String roomId) {
    final controller = _roomCtrls.putIfAbsent(
      roomId,
          () => StreamController<ChatMessage>.broadcast(),
    );

    _ensureConnected().then((_) => _subscribeRoom(roomId));
    return controller.stream;
  }

  @override
  Future<void> send({
    required String roomId,
    required String senderId,
    required String text,
    String type = 'text',
  }) async {
    await _ensureConnected();
    final dest = _sendDestBuilder(roomId);
    final payload = <String, dynamic>{
      'roomId': roomId,
      'senderId': senderId,
      'text': text,
      'type': type,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _client?.send(destination: dest, body: jsonEncode(payload));
    if (_debug) {
      // ignore: avoid_print
      print('[STOMP] SEND → $dest $payload');
    }
  }

  @override
  Future<void> unsubscribe(String roomId) async {
    final unsub = _roomUnsubs.remove(roomId);
    unsub?.call();
    await _roomCtrls[roomId]?.close();
    _roomCtrls.remove(roomId);
  }

  @override
  Future<void> dispose() async {
    for (final e in _roomUnsubs.values) {
      e();
    }
    _roomUnsubs.clear();
    for (final ctrl in _roomCtrls.values) {
      await ctrl.close();
    }
    _roomCtrls.clear();
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
            // ignore: avoid_print
            print('[STOMP] WS error: $err');
          }
          _connected = false;
        },
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        heartbeatIncoming: _hbIn, // ✅ Duration 그대로
        heartbeatOutgoing: _hbOut, // ✅ Duration 그대로
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
    return _connecting!.future;
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    if (_debug) {
      // ignore: avoid_print
      print('[STOMP] Connected headers=${frame.headers}');
    }
    // 재연결 시 기존 방들 재구독
    for (final roomId in _roomCtrls.keys) {
      _subscribeRoom(roomId);
    }
    _connecting?.complete();
    _connecting = null;
  }

  void _onStompError(StompFrame frame) {
    _connected = false;
    if (_debug) {
      // ignore: avoid_print
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

  void _subscribeRoom(String roomId) {
    if (!_connected || _client == null) return;

    // 이미 구독 중이면 먼저 해제
    _roomUnsubs.remove(roomId)?.call();

    final topic = _topicBuilder(roomId);
    final ctrl = _roomCtrls[roomId];
    if (ctrl == null) return;

    // ✅ 버전 호환: subscribe 반환값이 Function 또는 StompUnsubscribe 일 수 있음
    final unsub = _client!.subscribe(
      destination: topic,
      callback: (StompFrame frame) {
        try {
          if (frame.body == null) return;
          final Map<String, dynamic> jsonMap = json.decode(frame.body!) as Map<String, dynamic>;
          final msg = ChatMessage.fromJson(jsonMap);
          if (!ctrl.isClosed) ctrl.add(msg);
          if (_debug) {
            // ignore: avoid_print
            print('[STOMP] RECV ← $topic $jsonMap');
          }
        } catch (e) {
          if (_debug) {
            // ignore: avoid_print
            print('[STOMP] parse error: $e');
          }
        }
      },
    );

    // unsubscribe 핸들러 저장 (버전별 안전 처리)
    _roomUnsubs[roomId] = () {
      try {
        // 0.4.x 기준: subscribe가 반환하는 값은 typedef StompUnsubscribe = void Function()
        // 즉, 해제는 메서드 호출이 아니라 함수 호출로 해야 함.
        if (unsub is void Function()) {
          unsub(); // 함수 자체를 호출하여 구독 해제
        }
        // 오래된 버전에서 class 기반일 가능성까지 고려하면 아래처럼 동적 호출을 추가할 수도 있음.
        // (현재 0.4.x에서는 필요 없음)
        // else {
        //   final dyn = unsub as dynamic;
        //   try { dyn.unsubscribe?.call(); } catch (_) {}
        // }
      } catch (_) {}
    };

    if (_debug) {
      // ignore: avoid_print
      print('[STOMP] SUBSCRIBE → $topic');
    }
  }
}