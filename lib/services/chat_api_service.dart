// REST 전용 호출방(방 생성 / 종료 / 히스토리).
// 기존 api_service.dart 래핑/확장

// lib/services/chat_api_service.dart
// REST 전용 호출 래퍼. 백엔드 규격이 확정되면 엔드포인트만 맞추면 됩니다.
// - 의존: ApiService (공통 인증/BASE_URL 적용)
// - 모델: ChatRoom/ChatMessage (services/chat_repository.dart 임시 모델 사용)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectbeat/services/api_service.dart';
import 'package:connectbeat/services/chat_repository.dart';

class ChatApiService {
  const ChatApiService();

  // TODO(backend): 백엔드 팀 규격에 맞춰 경로/쿼리 키를 조정하세요.
  static const String _roomsPath = '/chat/rooms';

  /// 방 생성 (세션)
  /// POST /chat/rooms { topicId, topicName? }
  Future<ChatRoom> createRoom({
    required String topicId,
    String? topicName,
  }) async {
    final http.Response res = await ApiService.postWithAuth(
      _roomsPath,
      body: <String, dynamic>{
        'topicId': topicId,
        if (topicName != null) 'topicName': topicName,
      },
    );
    final Map<String, dynamic> data = _decodeJson(res);
    return ChatRoom.fromJson(data);
  }

  /// 세션 종료 → 분석 파이프라인 트리거
  /// POST /chat/rooms/{roomId}/close
  Future<void> closeRoom(String roomId) async {
    final http.Response res = await ApiService.postWithAuth(
      '$_roomsPath/$roomId/close',
    );
    _ensure2xx(res);
  }

  /// 메시지 히스토리 조회 (옵션)
  /// GET /chat/rooms/{roomId}/messages?cursor=...&size=50
  Future<List<ChatMessage>> fetchHistory(
      String roomId, {
        String? cursor,
        int size = 50,
      }) async {
    final query = <String, String>{
      'size': size.toString(),
      if (cursor != null) 'cursor': cursor,
    };
    final path = _buildPathWithQuery('$_roomsPath/$roomId/messages', query);
    final http.Response res = await ApiService.getWithAuth(path);
    final dynamic jsonBody = _decodeJsonDynamic(res);

    if (jsonBody is List) {
      return jsonBody
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(growable: false);
    }
    if (jsonBody is Map && jsonBody['items'] is List) {
      // { items: [...], nextCursor: '...' } 형태도 지원
      final items = (jsonBody['items'] as List).cast<Map<String, dynamic>>();
      return items.map(ChatMessage.fromJson).toList(growable: false);
    }
    throw FormatException('Unexpected history response format');
  }

  /// (대안) REST로 메시지 전송
  /// POST /chat/rooms/{roomId}/messages { text, type? }
  Future<void> sendMessageRest({
    required String roomId,
    required String text,
    String type = 'text',
  }) async {
    final http.Response res = await ApiService.postWithAuth(
      '$_roomsPath/$roomId/messages',
      body: <String, dynamic>{
        'text': text,
        'type': type,
      },
    );
    _ensure2xx(res);
  }

  // --- helpers ---

  Map<String, dynamic> _decodeJson(http.Response res) {
    _ensure2xx(res);
    final dynamic body = json.decode(res.body);
    if (body is Map<String, dynamic>) return body;
    throw const FormatException('Expected JSON object');
  }

  dynamic _decodeJsonDynamic(http.Response res) {
    _ensure2xx(res);
    return json.decode(res.body);
  }

  void _ensure2xx(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('[${res.statusCode}] ${res.body}');
    }
  }

  String _buildPathWithQuery(String base, Map<String, String> query) {
    if (query.isEmpty) return base;
    final encoded = query.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$base?$encoded';
  }
}

class HttpException implements Exception {
  final String message;
  const HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
