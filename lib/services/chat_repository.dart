// lib/services/chat_repository.dart
// 채팅 도메인 인터페이스 및 최소 모델 정의
// 실제 구현체는 chat_repository_impl.dart 에서 작성.

import 'dart:async';
import 'package:flutter/foundation.dart';

/// 메시지 도메인 모델
/// (임시: 이후 lib/models/chat_message.dart 로 이동 권장)
@immutable
class ChatMessage {
  final String chatSessionId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.chatSessionId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      chatSessionId: json['chatSessionId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chatSessionId': chatSessionId,
    'senderId': senderId,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// 채팅 세션 도메인 모델
/// (임시: 이후 lib/models/chat_room.dart 로 이동 권장)
@immutable
class ChatRoom {
  final String chatSessionId;

  const ChatRoom({required this.chatSessionId});

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      chatSessionId: json['chatSessionId'] as String,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chatSessionId': chatSessionId,
  };
}

/// 채팅 데이터 접근 계약.
/// UI/Providers는 이 인터페이스에만 의존합니다.
/// (구현체는 chat_repository_impl.dart)
abstract class ChatRepository {
  /// 세션 생성 (10분 채팅방 시작).
  /// - backend: POST /api/chat/session/start
  Future<ChatRoom> startSession();

  /// 실시간 메시지 스트림 구독.
  /// - backend: STOMP subscribe /topic/chat/session/{chatSessionId}
  Stream<ChatMessage> subscribeMessages(String chatSessionId);

  /// 메시지 전송.
  /// - backend: STOMP publish /app/chat/message
  ///   (payload: { chatSessionId, senderId, content })
  Future<void> sendMessage({
    required String chatSessionId,
    required String senderId,
    required String content,
  });

  /// 세션 종료 → 분석 파이프라인 트리거.
  /// - backend: POST /api/chat/session/{chatSessionId}/close
  Future<void> closeSession(String chatSessionId);
}
