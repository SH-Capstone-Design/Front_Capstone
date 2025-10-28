// lib/services/date_websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/main.dart';

class DateWebsocketService {
  static StompClient? _stompClient;
  static Timer? _heartbeatLogger;

  // 🔹 이벤트 콜백 등록
  static void Function(Map<String, dynamic> event)? _onCoupleConnected;
  static void Function(Map<String, dynamic> event)? _onCoupleDDayUpdated;

  /// COUPLE_CONNECTED 콜백 등록
  static void setOnCoupleConnected(void Function(Map<String, dynamic>) callback) {
    _onCoupleConnected = callback;
    print("🟢 COUPLE_CONNECTED 콜백 등록됨");
  }

  /// COUPLE_DDAY_UPDATED 콜백 등록
  static void setOnCoupleDDayUpdated(void Function(Map<String, dynamic>) callback) {
    _onCoupleDDayUpdated = callback;
    print("🟢 COUPLE_DDAY_UPDATED 콜백 등록됨");
  }

  /// WebSocket 연결
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

    print("🔗 WebSocket 연결 시도: $wsUrl");

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) {
          print("✅ STOMP Connected");

          _heartbeatLogger = Timer.periodic(const Duration(seconds: 10), (_) {
            print("💓 Heartbeat outgoing sent at ${DateTime.now()}");
          });

          print("📥 /user/queue/events 구독 시작");
          _stompClient?.subscribe(
            destination: "/user/queue/events",
            callback: (frame) {
              if (frame.body == null) return;
              final event = jsonDecode(frame.body!);
              print("📩 Received event: $event");

              switch (event['eventType']) {
                case 'COUPLE_CONNECTED':
                  print("🔔 이벤트 COUPLE_CONNECTED 수신");
                  _onCoupleConnected?.call(event);
                  if (navigatorKey.currentState != null) {
                    navigatorKey.currentState!.pushReplacementNamed('/home');
                  }
                  if (messengerKey.currentState != null) {
                    messengerKey.currentState!.showSnackBar(
                      SnackBar(content: Text(event['payload']?['message'] ?? '커플 연결 성공!')),
                    );
                  }
                  break;

                case 'COUPLE_DDAY_UPDATED':
                  print("🔔 이벤트 COUPLE_DDAY_UPDATED 수신");
                  _onCoupleDDayUpdated?.call(event);
                  if (messengerKey.currentState != null) {
                    messengerKey.currentState!.showSnackBar(
                      const SnackBar(content: Text('💖 커플 디데이가 업데이트되었습니다!')),
                    );
                  }
                  break;

                default:
                  print("⚠️ 알 수 없는 이벤트 수신: ${event['eventType']}");
                  break;
              }
            },
          );

          print("🎉 구독 완료");
          onSubscribed();
        },
        onWebSocketError: (error) {
          print("❌ WebSocket Error: $error");
          disconnect();
        },
        onDisconnect: (frame) {
          print("ℹ️ WebSocket disconnected");
          _heartbeatLogger?.cancel();
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        heartbeatIncoming: const Duration(seconds: 20),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    _stompClient?.activate();
    print("🚀 WebSocket activate 호출됨");
  }

  /// 커플 디데이 업데이트 이벤트 전송 (문자열 YYYY-MM-DD 사용)
  static void sendCoupleDDayUpdated(String dateStr) {
    if (_stompClient?.connected != true) {
      print("⚠️ WebSocket이 연결되지 않아 이벤트를 보낼 수 없음");
      return;
    }

    final msg = jsonEncode({
      'eventType': 'COUPLE_DDAY_UPDATED',
      'payload': {
        'anniversaryDate': dateStr,
      },
    });

    _stompClient?.send(destination: "/app/couples/dday", body: msg);
    print("📤 Sent COUPLE_DDAY_UPDATED event: $msg");
  }

  /// 연결 종료
  static void disconnect() {
    if (_stompClient?.connected == true) {
      print("ℹ️ WebSocket disconnect 호출");
      _stompClient?.deactivate();
    }
    _heartbeatLogger?.cancel();
    _stompClient = null;
    _onCoupleConnected = null;
    _onCoupleDDayUpdated = null;
    print("🛑 WebSocket 완전 종료");
  }
}