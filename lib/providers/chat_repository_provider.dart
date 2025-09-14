// lib/providers/chat_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';
import 'package:connectbeat/services/chat_api_service.dart';
import 'package:connectbeat/services/chat_socket_service.dart';
import 'package:connectbeat/services/auth_service.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final api = ChatApiService();
  final socket = StompSocketService(
    url: 'ws://13.125.197.173:8080/ws/chat', // ✅ 서버 주소 반영
    headersBuilder: () async => await AuthService.buildAuthHeader(), // ✅ JWT 토큰 헤더 추가
    topicBuilder: (id) => '/topic/chat/session/$id', // ✅ 서버 명세: 구독
    sendDestinationBuilder: (_) => '/app/chat/message', // ✅ 서버 명세: 메시지 전송
    printDebugLog: true,
  );

  return ChatRepositoryImpl(api: api, socket: socket);
});
