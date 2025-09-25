// lib/providers/chat_messages_controller.dart
// 특정 roomId의 실시간 메시지를 구독/누적하는 AutoDisposeNotifier

import 'dart:async';
import 'package:connectbeat/models/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';

class ChatMessagesNotifier extends AutoDisposeNotifier<List<ChatMessage>> {
  StreamSubscription<ChatMessage>? _sub;

  @override
  List<ChatMessage> build() => <ChatMessage>[];

  /// 특정 채팅방(roomId)의 메시지 실시간 구독 시작
  void start(String roomId) {
    final repo = ref.read(chatRepositoryProvider);

    // 기존 구독 해제
    _sub?.cancel();

    // 새로운 구독 시작
    _sub = repo.subscribeMessages(roomId).listen((msg) {
      state = [...state, msg];
    });

    // AutoDispose 시 정리
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });
  }

  /// 수동 해제 (옵션)
  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  /// 메시지 초기화
  void clear() => state = <ChatMessage>[];
}

/// UI에서 사용할 Provider
final chatMessagesProvider =
AutoDisposeNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
  ChatMessagesNotifier.new,
);
