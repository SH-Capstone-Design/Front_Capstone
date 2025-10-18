// lib/services/chat_api_service.dart
import 'dart:convert';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectbeat/services/auth_service.dart';

/// =======================
/// 💬 채팅 REST API 호출 서비스
/// =======================
class ChatApiService {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// ✅ 외부에서 접근 가능한 baseUrl getter
  String get baseUrl => _baseUrl;

  /// ✅ 외부에서 직접 토큰을 가져올 수 있도록 노출
  Future<String?> getToken() async {
    return await AuthService.getToken();
  }

  /// 공통 헤더 (JWT 포함)
  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// =======================
  /// ✅ 채팅방 생성 (POST /api/chat/rooms)
  /// =======================
  Future<ChatRoom> startSession() async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/chat/rooms");

    final res = await http.post(url, headers: headers);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint("🔥 startSession raw response: $body");
      return ChatRoom.fromJson(body);
    } else {
      throw Exception("세션 시작 실패: [${res.statusCode}] ${res.body}");
    }
  }

  /// =======================
  /// ✅ 채팅방 종료 (POST /api/chat/rooms/end)
  /// =======================
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

  /// =======================
  /// ✅ 채팅방 과거 메시지 조회 (GET /api/chat/rooms/{chatSessionId}/messages)
  /// =======================
  Future<List<ChatMessage>> getMessages(String chatSessionId) async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/chat/rooms/$chatSessionId/messages");

    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as List<dynamic>;
      return body
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("메시지 조회 실패: [${res.statusCode}] ${res.body}");
    }
  }

  /// =======================
  /// ✅ 채팅방 참여 REST 요청 (POST /api/chat/join)
  /// =======================
  Future<void> joinRoom(String chatSessionId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception("토큰이 없습니다. 로그인 필요.");

      final url = Uri.parse("$_baseUrl/chat/join");
      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };
      final body = jsonEncode({'chatSessionId': chatSessionId});

      debugPrint("📡 [JOIN 요청] → $url");
      debugPrint("📡 [JOIN body] → $body");

      final res = await http.post(url, headers: headers, body: body);

      debugPrint("📡 [JOIN status] → ${res.statusCode}");
      debugPrint("📡 [JOIN response] → ${res.body}");

      if (res.statusCode != 200) {
        throw Exception("세션 참여 실패 (${res.statusCode}): ${res.body}");
      }
    } catch (e) {
      debugPrint("❌ joinRoom 실패: $e");
      rethrow;
    }
  }
}
