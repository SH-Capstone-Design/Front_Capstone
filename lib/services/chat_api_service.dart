// lib/services/chat_api_service.dart
import 'dart:convert';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectbeat/services/auth_service.dart';

/// 채팅 REST API 호출 서비스
class ChatApiService {
  /// .env에 정의된 BASE_URL 사용
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// 공통 헤더 (JWT 포함)
  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// ✅ 채팅방 생성 (POST /api/chat/rooms)
  Future<ChatRoom> startSession() async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/chat/rooms");
    print("📌 요청 헤더: $headers");
    final res = await http.post(url, headers: headers);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return ChatRoom.fromJson(body);
    } else {
      throw Exception("세션 시작 실패: [${res.statusCode}] ${res.body}");
    }
  }

  /// ✅ 채팅방 종료 (POST /api/chat/rooms/end)
  Future<void> closeSession(String chatSessionId) async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/chat/rooms/end");

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({"chatSessionId": chatSessionId}),
    );

    if (res.statusCode != 200) {
      throw Exception("세션 종료 실패: [${res.statusCode}] ${res.body}");
    }
  }

  /// ✅ 메시지 전송 (REST 대체용, 소켓 연결 안될 때만 사용)
  Future<ChatMessage> sendMessageRest({
    required String chatSessionId,
    required String senderId,
    required String content,
  }) async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/message");

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "chatSessionId": chatSessionId,
        "senderId": senderId,
        "content": content,
      }),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return ChatMessage.fromJson(body);
    } else {
      throw Exception("메시지 전송 실패: [${res.statusCode}] ${res.body}");
    }
  }
}
