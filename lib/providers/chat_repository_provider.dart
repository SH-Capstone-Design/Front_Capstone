// DI 지점(현재 Mock 주입, 나중에 Impl로 교체)

// lib/providers/chat_repository_provider.dart
// 리포지토리 DI 지점. 현재는 Mock을 주입하고,
// 나중에 실제 구현(REST + WebSocket/STOMP)으로 교체만 하면 됩니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';
import 'package:connectbeat/services/chat_api_service.dart';
import 'package:connectbeat/services/chat_socket_service.dart';
import 'package:connectbeat/services/api_service.dart';

// TODO(backend): ChatRepositoryImpl(api, socket, auth) 로 교체
final chatRepositoryProvider = Provider<ChatRepository>((ref) {

  final api = ChatApiService();
  final socket = StompSocketService(
    url: 'wss://<HOST>/ws',                 // TODO: 백엔드 엔드포인트
    headersBuilder: () async => {
      // 'Authorization': 'Bearer ' + (await ApiService.getAuthToken()), // 예시
    },
    topicBuilder: (id) => '/topic/rooms/$id',
    sendDestinationBuilder: (id) => '/app/rooms/$id',
    printDebugLog: true,
  );
  return ChatRepositoryImpl(api: api, socket: socket);

  // return ChatRepositoryMock();
});