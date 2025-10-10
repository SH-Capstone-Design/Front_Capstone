// lib/services/chat_socket_service.dart
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'chat_repository_impl.dart';

/// ✅ STOMP(WebSocket) 기반 구현체
/// - 서버 문서 명세에 따라 /topic/chat/room/{chatSessionId} 와
///   /user/{userId}/queue/events 두 채널을 구독.
/// - /app/chat/... 경로로 초대, 참여, 메시지, 주제 선택을 전송.
class StompSocketService implements ChatSocketPort {
  final String url;
  final Future<Map<String, String>> Function() headersBuilder;
  final String Function(String chatSessionId) topicBuilder;
  final String Function(String chatSessionId) sendDestinationBuilder;
  final bool printDebugLog;

  StompClient? _stompClient;
  bool get isConnected => _stompClient?.connected ?? false;

  StompSocketService({
    required this.url,
    required this.headersBuilder,
    required this.topicBuilder,
    required this.sendDestinationBuilder,
    this.printDebugLog = false,
  });

  /// ✅ WebSocket 연결
  @override
  Future<void> connect({
    required void Function(Map<String, dynamic>) onRoomEvent,
    required void Function(Map<String, dynamic>) onPersonalEvent,
    required String chatSessionId,
    required String userId,
  }) async {
    final headers = await headersBuilder();

    _stompClient = StompClient(
      config: StompConfig(
        url: url,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: (StompFrame frame) {
          if (printDebugLog) {
            print('✅ STOMP 연결 성공');
            print('🔑 연결 헤더: ${frame.headers}');
          }

          // ✅ 공용 채널 구독 (/topic/chat/room/{chatSessionId})
          _stompClient!.subscribe(
            destination: '/topic/chat/room/$chatSessionId',
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

          // ✅ 개인 채널 구독 (/user/{userId}/queue/events)
          _stompClient!.subscribe(
            destination: '/user/$userId/queue/events',
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
        },
        onStompError: (StompFrame frame) {
          print('❌ STOMP Error: ${frame.body}');
        },
        onWebSocketError: (dynamic error) {
          print('❌ WebSocket Error: $error');
        },
        onDisconnect: (_) {
          if (printDebugLog) print('🔌 STOMP 연결 종료됨');
        },
      ),
    );

    _stompClient!.activate();
  }

  /// ✅ 메시지 전송 (/app/chat/message)
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

    _send('/app/chat/message', body);
  }

  /// ✅ 초대 전송 (/app/chat/invite)
  @override
  void sendInvite({
    required String chatSessionId,
    required String inviteeId,
  }) {
    final body = jsonEncode({
      "chatSessionId": chatSessionId,
      "inviteeId": inviteeId,
    });

    _send('/app/chat/invite', body);
  }

  /// ✅ 참여 전송 (/app/chat/join)
  @override
  void sendJoin({
    required String chatSessionId,
  }) {
    final body = jsonEncode({
      "chatSessionId": chatSessionId,
    });

    _send('/app/chat/join', body);
  }

  /// ✅ 주제 선택 (/app/chat/category-select)
  @override
  void sendCategorySelect({
    required String chatSessionId,
    required int categoryId,
  }) {
    final body = jsonEncode({
      "chatSessionId": chatSessionId,
      "categoryId": categoryId,
    });

    _send('/app/chat/category-select', body);
  }

  /// 내부 전송 헬퍼
  void _send(String destination, String body) {
    if (_stompClient == null || !_stompClient!.connected) {
      print("⚠️ WebSocket not connected. send() skipped.");
      return;
    }

    _stompClient!.send(destination: destination, body: body);

    if (printDebugLog) print("📤 Sent ($destination): $body");
  }

  /// ✅ 연결 해제
  @override
  void disconnect() {
    _stompClient?.deactivate();
    if (printDebugLog) print("🔌 WebSocket Disconnected");
  }
}
