import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CodeWebsocketService {
  static StompClient? _stompClient;

  static void connect(String userId, String token, BuildContext context) {
    final wsUrl = dotenv.env['BASE_WS_URL']!; // ws:// 또는 wss://
    print("🔗 Connecting to WebSocket: $wsUrl");

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (StompFrame frame) {
          print("✅ STOMP Connected");

          _stompClient?.subscribe(
            destination: "/user/$userId/queue/events",
            callback: (frame) {
              if (frame.body != null) {
                final event = jsonDecode(frame.body!);
                print("📩 Event received: $event");

                if (event['eventType'] == 'COUPLE_CONNECTED') {
                  Navigator.pushReplacementNamed(context, '/home-screen');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        event['payload']?['message'] ??
                            '커플 연결이 성공적으로 완료되었습니다!',
                        style: const TextStyle(fontFamily: 'GowunBatang'),
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
        onWebSocketError: (error) => print("❌ WebSocket error: $error"),
        onStompError: (frame) => print("❌ STOMP error: ${frame.body}"),
        onDisconnect: (frame) => print("⚡ WebSocket disconnected"),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );

    _stompClient?.activate();
  }

  static void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    print("⚡ WebSocket disconnected manually");
  }
}
