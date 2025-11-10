import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';

/// 💬 ChatRepository
/// UI나 Provider가 의존하는 추상 레이어.
/// 실제 구현은 [ChatRepositoryImpl]에서 담당한다.
abstract class ChatRepository {
  /// ✅ 채팅 세션 생성 (10분 대화방 시작)
  Future<ChatRoom> startSession();

  /// ✅ 실시간 메시지 구독
  Stream<ChatMessage> subscribeMessages(String chatSessionId);

  /// ✅ 실시간 이벤트 구독
  Stream<ChatRoomEvent> subscribeEvents(String chatSessionId);

  /// ✅ 메시지 전송
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  });

  /// ✅ 세션 종료 (분석 단계로 진입)
  Future<void> closeSession(String chatSessionId);

  /// ✅ GPT 리포트 재시도 조회
  Future<Map<String, dynamic>?> generateReportWithRetry({
    required String chatSessionId,
    Duration interval,
    Duration timeout,
  });

  /// ✅ 대기 중 초대 확인
  /// - 반환: { chatSessionId, inviterId } 또는 null
  Future<Map<String, dynamic>?> checkPendingInvitation();
}
