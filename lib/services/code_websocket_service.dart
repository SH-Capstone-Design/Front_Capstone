import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/main.dart'; // 글로벌 navigatorKey, messengerKey

class CodeWebsocketService {
  static StompClient? _stompClient;
  static Timer? _heartbeatLogger;

  // 🔹 COUPLE_CONNECTED 이벤트 콜백
  static void Function(Map<String, dynamic> event)? _onCoupleConnected;

  /// 콜백 등록
  static void setOnCoupleConnected(void Function(Map<String, dynamic>) callback) {
    _onCoupleConnected = callback;
  }

  static Future<void> connect(
      String userId,
      String token, {
        required VoidCallback onSubscribed,
      }) async {
    final wsUrl = dotenv.env['BASE_WS_URL'];
    if (wsUrl == null || wsUrl.isEmpty) {
      print("❌ BASE_WS_URL이 .env에 설정되지 않았습니다.");
      return;
    }

    if (_stompClient?.isActive == true) {
      print("ℹ️ WebSocket is already active.");
      onSubscribed();
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) {
          print("✅ STOMP Connected");

          _heartbeatLogger = Timer.periodic(const Duration(seconds: 10), (_) {
            print("💓 Heartbeat outgoing sent at ${DateTime.now()}");
          });

          _stompClient?.subscribe(
            destination: "/user/queue/events",
            callback: (frame) {
              if (frame.body == null) return;
              final event = jsonDecode(frame.body!);
              print("📩 Received event: $event");

              if (event['eventType'] == 'COUPLE_CONNECTED') {
                // 🔹 등록된 콜백 호출
                _onCoupleConnected?.call(event);

                // 기존 글로벌 키 사용 예시
                if (navigatorKey.currentState != null) {
                  navigatorKey.currentState!.pushReplacementNamed('/home');
                }
                if (messengerKey.currentState != null) {
                  messengerKey.currentState!.showSnackBar(
                    SnackBar(content: Text(event['payload']?['message'] ?? '커플 연결 성공!')),
                  );
                }
              }
            },
          );

          onSubscribed();
        },
        onWebSocketError: (error) => disconnect(),
        onDisconnect: (frame) => _heartbeatLogger?.cancel(),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        heartbeatIncoming: const Duration(seconds: 20),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    _stompClient?.activate();
  }

  static void disconnect() {
    if (_stompClient?.connected == true) _stompClient?.deactivate();
    _heartbeatLogger?.cancel();
    _stompClient = null;
    _onCoupleConnected = null;
  }
}
