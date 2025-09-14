import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectbeat/services/auth_service.dart';
import 'package:connectbeat/services/chat_repository.dart';

class ChatApiService {
  static const String _baseUrl = "http://13.125.197.173:8080/api/chat";

  /// 공통 헤더
  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 세션 시작: POST /api/chat/session/start
  Future<ChatRoom> startSession() async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/session/start");

    final res = await http.post(url, headers: headers);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return ChatRoom.fromJson(body);
    } else {
      throw Exception("세션 시작 실패: [${res.statusCode}] ${res.body}");
    }
  }

  /// 세션 종료: POST /api/chat/session/end
  Future<void> closeSession(String chatSessionId) async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/session/end");

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({"chatSessionId": chatSessionId}),
    );

    if (res.statusCode != 200) {
      throw Exception("세션 종료 실패: [${res.statusCode}] ${res.body}");
    }
  }

  /// 메시지 전송 (소켓 없는 경우 대체용)
  Future<void> sendMessageRest({
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

    if (res.statusCode != 200) {
      throw Exception("메시지 전송 실패: [${res.statusCode}] ${res.body}");
    }
  }
}
