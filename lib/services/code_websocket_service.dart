import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CodeWebsocketService {
  static StompClient? _stompClient;

  /// STOMP(WebSocket) 연결
  static Future<void> connect(String userId, String token, BuildContext context) async {
    final wsUrl = dotenv.env['BASE_WS_URL']!;
    print("🔗 Connecting to WebSocket: $wsUrl");

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (StompFrame frame) {
          print("✅ STOMP Connected");

          // 사용자별 이벤트 구독 (userId 포함)
          _stompClient?.subscribe(
            destination: "/user/$userId/queue/events",
            callback: (StompFrame frame) {
              print("📩 Received frame: ${frame.body}");
              if (frame.body != null) {
                final event = jsonDecode(frame.body!);
                if (event['eventType'] == 'COUPLE_CONNECTED') {
                  Navigator.pushReplacementNamed(context, '/home-screen');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(event['payload']?['message'] ?? '커플 연결 성공!')),
                  );
                }
              }
            },
          );

          print("📌 Subscribed to /user/$userId/queue/events");
        },
        onWebSocketError: (dynamic error) => print("❌ WebSocket error: $error"),
        onStompError: (StompFrame frame) => print("❌ STOMP error: ${frame.body}"),
        onDisconnect: (frame) => print("⚡ WebSocket disconnected"),
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        heartbeatIncoming: Duration(milliseconds: 0),
        heartbeatOutgoing: Duration(milliseconds: 20000),
      ),
    );

    _stompClient?.activate();
  }

  /// WebSocket 연결 해제
  static void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    print("⚡ WebSocket disconnected manually");
  }
}
