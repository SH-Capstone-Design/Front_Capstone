import 'dart:convert';
import 'dart:async';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'chat_repository_impl.dart';

class StompSocketService implements ChatSocketPort {
  final String url;
  final Future<Map<String, String>> Function() headersBuilder;
  final bool printDebugLog;

  StompClient? _stompClient;
  bool get isConnected => _stompClient?.connected ?? false;

  StompSocketService({
    required this.url,
    required this.headersBuilder,
    this.printDebugLog = false,
  });

  @override
  Future<void> connectBase({
    required void Function(Map<String, dynamic>) onPersonalEvent,
  }) async {
    if (isConnected) {
      if (printDebugLog) print("⚠️ 이미 STOMP 연결되어 있음. connectBase() 생략");
      return;
    }

    final headers = await headersBuilder();
    final completer = Completer<void>();

    _stompClient = StompClient(
      config: StompConfig(
        url: url,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: (frame) {
          if (printDebugLog) print("✅ STOMP 연결 성공");

          _stompClient!.subscribe(
            destination: '/user/queue/events',
            callback: (f) {
              if (f.body == null) return;
              try {
                final data = jsonDecode(f.body!);
                onPersonalEvent(data);
              } catch (e) {
                print("⚠️ PersonalEvent 파싱 실패: $e");
              }
            },
          );
          if (!completer.isCompleted) completer.complete();
        },
        onWebSocketError: (err) {
          if (!completer.isCompleted) completer.completeError(err);
        },
        onDisconnect: (_) {
          if (printDebugLog) print("🔌 STOMP 연결 종료됨");
        },
      ),
    );

    _stompClient!.activate();
    await completer.future;
  }

  @override
  Future<void> subscribeRoom({
    required String chatSessionId,
    required void Function(Map<String, dynamic>) onRoomEvent,
  }) async {
    if (!isConnected) {
      print("⚠️ STOMP 연결 안됨 → subscribeRoom 무시");
      return;
    }

    final destination = '/topic/chat/room/$chatSessionId';
    _stompClient!.subscribe(
      destination: destination,
      callback: (frame) {
        print('🔥 이벤트 수신: ${frame.body}');
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!);
          onRoomEvent(data);
        } catch (e) {
          print("⚠️ RoomEvent 파싱 실패: $e");
        }
      },
    );
    print('📡 방 구독 완료: /topic/chat/room/$chatSessionId');
    if (printDebugLog) print("📡 방 구독 완료: $destination");
  }

  @override
  void sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  }) {
    _send('/app/chat/message', {
      "chatSessionId": chatSessionId,
      "senderId": senderId,
      "content": content,
    });
  }

  @override
  void sendInvite({
    required String chatSessionId,
    required String inviteeId,
  }) {
    _send('/app/chat/invite', {
      "chatSessionId": chatSessionId,
      "inviteeId": inviteeId,
    });
  }

  @override
  void sendJoin({required String chatSessionId}) {
    _send('/app/chat/join', {"chatSessionId": chatSessionId});
  }


  void _send(String dest, Map<String, dynamic> data) {
    if (!isConnected) {
      print("⚠️ WebSocket 미연결, send() 스킵됨: $dest");
      return;
    }
    _stompClient!.send(destination: dest, body: jsonEncode(data));
  }

  @override
  void sendEndChat({required String chatSessionId}) {
    if (_stompClient == null || !_stompClient!.connected) {
      print("⚠️ STOMP 연결이 끊김, 종료 요청 실패");
      return;
    }
    _send('/app/chat/end', {"chatSessionId": chatSessionId});
    if (printDebugLog) print("📤 [SEND] /app/chat/end → $chatSessionId");
  }



  @override
  void disconnect() {
    if (_stompClient == null) return;
    if (_stompClient!.connected) {
      _stompClient!.deactivate();
      if (printDebugLog) print("🔌 STOMP 정상 종료");
    }
    _stompClient = null;
  }
}
