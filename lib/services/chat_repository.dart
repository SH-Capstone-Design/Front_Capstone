// lib/services/chat_repository.dart
// 채팅 도메인 인터페이스 정의
// 실제 구현체는 chat_repository_impl.dart 에서 작성.

import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_message.dart';

/// 채팅 데이터 접근 계약.
/// UI/Providers는 이 인터페이스에만 의존합니다.
/// (구현체는 chat_repository_impl.dart)
abstract class ChatRepository {
  /// ✅ 세션 생성 (10분 채팅방 시작).
  /// - backend: POST /api/chat/session/start
  Future<ChatRoom> startSession();

  /// ✅ 실시간 메시지 스트림 구독.
  /// - backend: STOMP subscribe /topic/chat/session/{chatSessionId}
  Stream<ChatMessage> subscribeMessages(String chatSessionId);

  /// ✅ 메시지 전송.
  /// - backend: STOMP publish /app/chat/message
  ///   (payload: { chatSessionId, senderId, content })
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  });

  /// ✅ 세션 종료 → 분석 파이프라인 트리거.
  /// - backend: POST /api/chat/session/{chatSessionId}/close
  Future<void> closeSession(String chatSessionId);
}
