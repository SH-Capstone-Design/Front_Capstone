// lib/services/chat_repository.dart
// 채팅 도메인 인터페이스 정의
// 실제 구현체는 chat_repository_impl.dart 에서 작성됨.

import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';
import 'package:connectbeat/models/chat_room_event.dart';

/// 💬 ChatRepository
/// UI나 Provider가 의존하는 추상 레이어.
/// 실제 구현은 [ChatRepositoryImpl]에서 담당한다.
abstract class ChatRepository {
  /// ✅ 채팅 세션 생성 (10분 대화방 시작)
  /// - backend: POST /api/chat/rooms
  Future<ChatRoom> startSession();

  /// ✅ 실시간 메시지 구독
  /// - backend: STOMP subscribe → /topic/chat/room/{chatSessionId}
  Stream<ChatMessage> subscribeMessages(String chatSessionId);

  /// ✅ 실시간 이벤트 구독
  /// - backend: STOMP subscribe → /topic/chat/events/{chatSessionId}
  ///   예: CONVERSATION_STARTED, CONVERSATION_ENDED 등
  Stream<ChatRoomEvent> subscribeEvents(String chatSessionId);

  /// ✅ 메시지 전송
  /// - backend: STOMP publish → /app/chat/message
  ///   payload 예: { chatSessionId, senderId, content }
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  });

  /// ✅ 세션 종료 (분석 단계로 진입)
  /// - backend: POST /api/chat/rooms/{chatSessionId}/end
  Future<void> closeSession(String chatSessionId);
}
