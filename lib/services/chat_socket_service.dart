import 'dart:convert';
import 'dart:async';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'chat_repository_impl.dart';

/// ✅ STOMP(WebSocket) 기반 구현체
/// - /user/queue/events : 개인 이벤트 (초대, 알림 등)
/// - /topic/chat/room/{chatSessionId} : 방 전체 이벤트 (메시지, 입장, 종료)
/// - /app/chat/... : 서버로 전송 (invite, join, message)
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

  // ---------------------------------------------------------------------------
  // ✅ 1️⃣ STOMP 연결 (개인 채널 전용)
  // ---------------------------------------------------------------------------
  @override
  Future<void> connectBase({
    required void Function(Map<String, dynamic>) onPersonalEvent,
  }) async {
    final headers = await headersBuilder();
    final completer = Completer<void>(); // 연결 완료 신호

    // 이미 연결되어 있다면 재연결
    if (_stompClient?.connected == true) {
      if (printDebugLog) print("⚠️ 기존 STOMP 연결 해제 후 재연결 시도");
      _stompClient?.deactivate();
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: url,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: (StompFrame frame) {
          if (printDebugLog) {
            print("✅ STOMP 연결 성공 (개인 채널)");
            print("🔑 연결 헤더: ${frame.headers}");
          }

          // ✅ 개인 큐 구독 (/user/queue/events)
          _stompClient!.subscribe(
            destination: '/user/queue/events',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                try {
                  final data = jsonDecode(frame.body!);
                  if (printDebugLog) print("📬 Personal Event: $data");
                  onPersonalEvent(data);
                } catch (e) {
                  print("⚠️ PersonalEvent decode 실패: $e");
                }
              }
            },
          );

          // 연결 완료 신호
          if (!completer.isCompleted) completer.complete();
        },
        onStompError: (frame) {
          print("❌ STOMP Error: ${frame.body}");
          if (!completer.isCompleted) completer.completeError(frame.body ?? "STOMP Error");
        },
        onWebSocketError: (error) {
          print("❌ WebSocket Error: $error");
          if (!completer.isCompleted) completer.completeError(error);
        },
        onDisconnect: (_) {
          if (printDebugLog) print("🔌 STOMP 연결 종료됨");
        },
      ),
    );

    _stompClient!.activate();
    await completer.future; // 실제 연결 완료될 때까지 대기
  }

  // ---------------------------------------------------------------------------
  // ✅ 2️⃣ 채팅방 구독 (/topic/chat/room/{chatSessionId})
  // ---------------------------------------------------------------------------
  @override
  Future<void> subscribeRoom({
    required String chatSessionId,
    required void Function(Map<String, dynamic>) onRoomEvent,
  }) async {
    if (_stompClient?.connected != true) {
      print("⚠️ STOMP 연결 안 됨. 구독 불가");
      return;
    }

    final destination = '/topic/chat/room/$chatSessionId';
    _stompClient!.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            if (printDebugLog) print("📩 Room Event: $data");
            onRoomEvent(data);
          } catch (e) {
            print("⚠️ RoomEvent decode 실패: $e");
          }
        }
      },
    );

    if (printDebugLog) print("🔔 방 구독 완료 → $destination");
  }

  // ---------------------------------------------------------------------------
  // ✅ 3️⃣ 메시지 전송 (/app/chat/message)
  // ---------------------------------------------------------------------------
  @override
  void sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  }) {
    final body = jsonEncode({
      "chatSessionId": chatSessionId,
      "senderId": senderId,
      "content": content,
    });
    _send('/app/chat/message', body, label: "💬 메시지");
  }

  // ---------------------------------------------------------------------------
  // ✅ 4️⃣ 초대 전송 (/app/chat/invite)
  // ---------------------------------------------------------------------------
  @override
  void sendInvite({
    required String chatSessionId,
    required String inviteeId,
  }) {
    final body = jsonEncode({
      "chatSessionId": chatSessionId,
      "inviteeId": inviteeId,
    });
    _send('/app/chat/invite', body, label: "💌 초대");
  }

  // ---------------------------------------------------------------------------
  // ✅ 5️⃣ 참여 전송 (/app/chat/join)
  // ---------------------------------------------------------------------------
  @override
  void sendJoin({
    required String chatSessionId,
  }) {
    final body = jsonEncode({
      "chatSessionId": chatSessionId,
    });
    _send('/app/chat/join', body, label: "👥 참여");
  }

  // ---------------------------------------------------------------------------
  // ✅ 내부 공통 전송 로직
  // ---------------------------------------------------------------------------
  void _send(String destination, String body, {String? label}) {
    if (_stompClient == null || !_stompClient!.connected) {
      print("⚠️ WebSocket not connected. send() skipped. [$label]");
      return;
    }

    _stompClient!.send(destination: destination, body: body);

    if (printDebugLog) {
      print("📤 [$label] Sent → $destination");
      print("   └─ $body");
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 연결 해제
  // ---------------------------------------------------------------------------
  @override
  void disconnect() {
    if (_stompClient == null) return;
    if (_stompClient!.connected) {
      _stompClient!.deactivate();
      if (printDebugLog) print("🔌 WebSocket Disconnected (정상 종료)");
    } else {
      if (printDebugLog) print("⚠️ WebSocket 이미 종료 상태");
    }
  }
}
