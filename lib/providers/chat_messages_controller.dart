// 메시지 구독·누적 AutoDisposeNotifier

// lib/providers/chat_messages_controller.dart
// 특정 roomId의 실시간 메시지를 구독/누적하는 AutoDisposeNotifier

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';

class ChatMessagesNotifier extends AutoDisposeNotifier<List<ChatMessage>> {
  StreamSubscription<ChatMessage>? _sub;

  @override
  List<ChatMessage> build() => <ChatMessage>[];

  /// roomId에 대한 실시간 구독 시작
  void start(String roomId) {
    final repo = ref.read(chatRepositoryProvider);
    _sub?.cancel();
    _sub = repo.subscribeMessages(roomId).listen((msg) {
      state = <ChatMessage>[...state, msg];
    });

    ref.onDispose(() {
      _sub?.cancel();
    });
  }

  /// 수동 해제(옵션)
  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  /// 누적 메시지 초기화
  void clear() => state = <ChatMessage>[];
}

final chatMessagesProvider = AutoDisposeNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
  ChatMessagesNotifier.new,
);