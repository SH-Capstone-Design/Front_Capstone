// lib/services/chat_socket_service.dart
import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'chat_repository_impl.dart';

/// STOMP(WebSocket) 기반 구현체
class StompSocketService implements ChatSocketPort {
  final String url;
  final Future<Map<String, String>> Function() headersBuilder;
  final String Function(String chatSessionId) topicBuilder;
  final String Function(String chatSessionId) sendDestinationBuilder;
  final bool printDebugLog;

  StompClient? _stompClient;

  StompSocketService({
    required this.url,
    required this.headersBuilder,
    required this.topicBuilder,
    required this.sendDestinationBuilder,
    this.printDebugLog = false,
  });

  /// ✅ 서버와 STOMP(WebSocket) 연결
  @override
  Future<void> connect({
    required void Function(Map<String, dynamic>) onMessage,
  }) async {
    final headers = await headersBuilder();

    _stompClient = StompClient(
      config: StompConfig(
        url: url,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: (StompFrame frame) {
          if (printDebugLog) {
            print('✅ WebSocket Connected: session=${frame.headers?["session"]}');
          }
        },
        onStompError: (frame) {
          print('❌ STOMP Error: ${frame.body}');
        },
        onWebSocketError: (dynamic error) {
          print('❌ WebSocket Error: $error');
        },
        onUnhandledMessage: (frame) {
          if (frame.body != null) {
            try {
              final data = jsonDecode(frame.body!);
              if (printDebugLog) print("📩 Unhandled: $data");
              onMessage(data);
            } catch (e) {
              print("⚠️ Failed to decode unhandled message: $e");
            }
          }
        },
      ),
    );

    _stompClient?.activate();
  }

  /// ✅ 특정 채팅방 구독
  @override
  void subscribeChatRoom(
      String chatSessionId,
      void Function(Map<String, dynamic>) onMessage,
      ) {
    _stompClient?.subscribe(
      destination: topicBuilder(chatSessionId),
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            if (printDebugLog) print("📩 Received: $data");
            onMessage(data);
          } catch (e) {
            print("⚠️ Failed to decode message: $e");
          }
        }
      },
    );
  }

  /// ✅ 메시지 전송
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

    _stompClient?.send(
      destination: sendDestinationBuilder(chatSessionId),
      body: body,
    );

    if (printDebugLog) print("📤 Sent: $body");
  }

  /// ✅ 연결 해제
  @override
  void disconnect() {
    _stompClient?.deactivate();
    if (printDebugLog) print("🔌 WebSocket Disconnected");
  }
}
