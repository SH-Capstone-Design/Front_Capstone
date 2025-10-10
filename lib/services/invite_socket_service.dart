import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

/// 초대 전용 WebSocket 통신 서비스
class InviteSocketService {
  static StompClient? _client;
  static bool _isConnected = false;

  /// ✅ WebSocket 연결 (없을 경우 자동 생성)
  static Future<void> _ensureConnected(String token) async {
    if (_isConnected && _client != null) return;

    final wsUrl = dotenv.env['BASE_WS_URL']!;
    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) {
          debugPrint("✅ Invite STOMP 연결 성공");
          _isConnected = true;
        },
        onStompError: (frame) => debugPrint("❌ STOMP Error: ${frame.body}"),
        onWebSocketError: (error) => debugPrint("❌ WebSocket Error: $error"),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );

    _client?.activate();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// ✅ 초대 메시지 전송
  static Future<void> sendInvite({
    required String inviterId,
    required String inviteeId,
    required String chatSessionId,
    required String token,
  }) async {
    await _ensureConnected(token);

    final payload = jsonEncode({
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'chatSessionId': chatSessionId,
    });

    _client?.send(
      destination: '/app/invite/send',
      body: payload,
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint("📨 초대 전송 완료 → inviteeId: $inviteeId");
  }

  /// ✅ 상대방이 초대를 수락했을 때 이벤트 수신
  static void listenForInviteResponse({
    required String chatSessionId,
    required VoidCallback onUserJoined,
  }) {
    _client?.subscribe(
      destination: '/topic/chat/session/$chatSessionId',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          final eventType = data['eventType'];
          if (eventType == 'USER_JOINED') {
            debugPrint("👫 상대방이 초대를 수락했습니다!");
            onUserJoined();
          }
        }
      },
    );
  }

  /// ✅ 연결 종료
  static void disconnect() {
    _client?.deactivate();
    _isConnected = false;
  }
}
