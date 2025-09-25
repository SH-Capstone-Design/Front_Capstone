// lib/providers/chat_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';
import 'package:connectbeat/services/chat_api_service.dart';
import 'package:connectbeat/services/chat_socket_service.dart';
import 'package:connectbeat/services/auth_service.dart';

/// .env의 BASE_URL을 WebSocket용 URL로 변환
/// 예: http://13.125.197.173:8080/api → ws://13.125.197.173:8080/ws/chat
String _buildWsUrlFromBase() {
  final base = dotenv.env['BASE_URL'] ?? '';
  if (base.isEmpty) {
    throw Exception("❌ BASE_URL이 .env에 정의되지 않았습니다.");
  }
  var wsUrl = base.replaceFirst(RegExp(r'^http'), 'ws');
  wsUrl = wsUrl.replaceFirst(RegExp(r'/api/?$'), '/ws/chat');
  return wsUrl;
}

/// ChatRepository Provider (Riverpod)
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final api = ChatApiService();

  final socket = StompSocketService(
    url: _buildWsUrlFromBase(),
    headersBuilder: () async {
      // 매 재연결마다 토큰 새로 갱신
      final headers = await AuthService.buildAuthHeader();
      return {
        if (headers.containsKey('Authorization'))
          'Authorization': headers['Authorization']!,
      };
    },
    topicBuilder: (id) => '/topic/chat/room/$id', // ✅ 서버 명세와 일치
    sendDestinationBuilder: (_) => '/app/chat/message', // ✅ 서버 명세와 일치
    printDebugLog: true,
  );

  return ChatRepositoryImpl(api: api, socket: socket);
});
