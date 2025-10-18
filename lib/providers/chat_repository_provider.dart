import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';
import 'package:connectbeat/services/chat_api_service.dart';
import 'package:connectbeat/services/chat_socket_service.dart';
import 'package:connectbeat/services/auth_service.dart';

/// ✅ .env의 BASE_URL을 WebSocket용 URL로 변환
/// 예: http://13.125.197.173:8080/api → ws://13.125.197.173:8080/ws/chat
String _buildWsUrlFromBase() {
  final base = dotenv.env['BASE_URL'] ?? '';
  if (base.isEmpty) {
    throw Exception("❌ BASE_URL이 .env에 정의되지 않았습니다.");
  }

  // http → ws / https → wss
  var wsUrl = base.replaceFirst(RegExp(r'^http'), 'ws');
  wsUrl = wsUrl.replaceFirst(RegExp(r'/api/?$'), '/ws/chat');
  return wsUrl;
}

/// ✅ ChatRepository Provider (Riverpod)
final chatRepositoryProvider = Provider<ChatRepositoryImpl>((ref) {
  final api = ChatApiService();

  final socket = StompSocketService(
    url: _buildWsUrlFromBase(),
    headersBuilder: () async {
      // 매 재연결마다 JWT 갱신
      final headers = await AuthService.buildAuthHeader();
      return {
        if (headers.containsKey('Authorization'))
          'Authorization': headers['Authorization']!,
      };
    },
    printDebugLog: true,
  );

  return ChatRepositoryImpl(api: api, socket: socket, ref: ref);
});

/// ✅ 소켓 연결 관리 Provider
/// UI에서 `ref.read(chatSocketControllerProvider).connect()` 식으로 호출
final chatSocketControllerProvider =
StateNotifierProvider<ChatSocketController, bool>((ref) {
  final repo = ref.read(chatRepositoryProvider);
  return ChatSocketController(repo);
});

/// ✅ 소켓 연결 상태 관리 및 트리거
class ChatSocketController extends StateNotifier<bool> {
  final ChatRepositoryImpl _repo;

  ChatSocketController(this._repo) : super(false);

  /// 소켓 기본 연결 (개인 큐 구독)
  Future<void> connect() async {
    try {
      await _repo.connectBase(); // ✅ 새 구조에 맞게 변경됨
      state = true;
      print('🔗 WebSocket 기본 연결 완료 (개인 큐 구독)');
    } catch (e) {
      print('❌ WebSocket 연결 실패: $e');
    }
  }

  /// 연결 해제 (채팅 종료 시)
  Future<void> disconnect(String chatSessionId) async {
    try {
      await _repo.closeSession(chatSessionId);
      state = false;
      print('🔌 WebSocket 연결 종료');
    } catch (e) {
      print('⚠️ 연결 종료 중 오류: $e');
    }
  }
}
