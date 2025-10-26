import 'dart:convert';
import 'package:connectbeat/models/chat_room.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectbeat/services/auth_service.dart';

class ChatApiService {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 채팅방 생성
  Future<ChatRoom> startSession() async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/chat/rooms");

    final res = await http.post(url, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return ChatRoom.fromJson(body);
    } else {
      throw Exception("세션 시작 실패: ${res.statusCode}");
    }
  }

  /// 채팅방 종료
  Future<void> closeSession(String chatSessionId) async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/chat/rooms/end");

    final res = await http.post(url, headers: headers, body: jsonEncode({'chatSessionId': chatSessionId}));
    if (res.statusCode != 200) throw Exception("세션 종료 실패: ${res.statusCode}");
  }

  /// 채팅 참여
  Future<void> joinRoom(String chatSessionId) async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/chat/join");
    final body = jsonEncode({'chatSessionId': chatSessionId});

    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode != 200) throw Exception("세션 참여 실패: ${res.statusCode}");
  }

  /// ✅ 대기 중 초대 확인
  Future<Map<String, dynamic>?> checkPendingInvitation() async {
    final headers = await _headers();
    final url = Uri.parse("$_baseUrl/chat/rooms/pending");

    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final data = jsonDecode(res.body);
      return data is Map<String, dynamic> ? data : null;
    } else if (res.statusCode == 204) {
      return null; // 대기 중 없음
    } else {
      throw Exception("대기 초대 확인 실패: ${res.statusCode}");
    }
  }
}
