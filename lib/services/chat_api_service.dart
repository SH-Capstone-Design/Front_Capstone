// lib/services/chat_api_service.dart
import 'dart:convert';
import 'package:connectbeat/models/chat_room.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectbeat/services/auth_service.dart';

/// 채팅 REST API 호출 서비스
class ChatApiService {
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

    final res = await http.post(url, headers: headers);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint("🔥 startSession raw response: $body");   // 추가
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
}
