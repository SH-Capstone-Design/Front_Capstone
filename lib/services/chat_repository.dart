// 추상화 인터페이스
// createRoom / subscribeMessages / sendMessage / closeRoom 정의.

// lib/services/chat_repository.dart
// Riverpod 기반 아키텍처에서 UI/Provider가 의존하는 채팅 도메인 계약(인터페이스)과
// 임시로 사용할 최소 도메인 모델을 함께 정의했습니다.
// TODO(app): 나중에 models/로 분리하면 import 경로만 바꾸고 그대로 사용 가능합니다.

import 'dart:async';
import 'package:flutter/foundation.dart';

/// 메시지 도메인 모델 (임시: 이후 lib/models/chat_message.dart 로 이동 권장)
@immutable
class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final String type; // 'text', 'image' 등 확장 가능

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = 'text',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: (json['type'] as String?) ?? 'text',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'roomId': roomId,
    'senderId': senderId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'type': type,
  };
}

/// 채팅방 도메인 모델 (임시: 이후 lib/models/chat_room.dart 로 이동 권장)
@immutable
class ChatRoom {
  final String id;
  final String topicId; // 10분 세션마다 필수
  final String? topicName;
  final DateTime createdAt;

  const ChatRoom({
    required this.id,
    required this.topicId,
    this.topicName,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'topicId': topicId,
    'topicName': topicName,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// 채팅 데이터 접근 계약. UI/Providers는 이 인터페이스에만 의존합니다.
abstract class ChatRepository {
  /// 방 생성 (10분 세션마다 새 방).
  /// - backend: POST /chat/rooms {topicId}
  Future<ChatRoom> createRoom({
    required String topicId,
    String? topicName,
  });

  /// 실시간 메시지 스트림 구독.
  /// - backend: STOMP subscribe /topic/rooms/{roomId}
  Stream<ChatMessage> subscribeMessages(String roomId);

  /// 메시지 전송.
  /// - backend: STOMP publish /app/rooms/{roomId} (또는 REST POST)
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  });

  /// 세션(방) 종료 → 분석 파이프라인 트리거.
  /// - backend: POST /chat/rooms/{roomId}/close
  Future<void> closeRoom(String roomId);
}