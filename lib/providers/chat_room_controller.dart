// lib/providers/chat_room_controller.dart
// 채팅방 생성/세션 상태를 관리하는 Riverpod Notifier

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';

class ChatRoomState {
  final bool creating;
  final ChatRoom? room;
  final String? error;

  const ChatRoomState({
    this.creating = false,
    this.room,
    this.error,
  });

  ChatRoomState copyWith({
    bool? creating,
    ChatRoom? room,
    String? error,
  }) {
    return ChatRoomState(
      creating: creating ?? this.creating,
      room: room ?? this.room,
      error: error,
    );
  }
}

class ChatRoomController extends Notifier<ChatRoomState> {
  late final ChatRepository _repo;

  @override
  ChatRoomState build() {
    _repo = ref.read(chatRepositoryProvider);
    return const ChatRoomState();
  }

  /// 10분 세션형 채팅방 생성 (Swagger: POST /api/chat/session/start)
  Future<void> startSession() async {
    state = state.copyWith(creating: true, error: null);
    try {
      final room = await _repo.startSession();
      state = state.copyWith(creating: false, room: room);
    } catch (e) {
      state = state.copyWith(creating: false, error: e.toString());
    }
  }

  /// 상태 초기화 (필요 시 사용)
  void clear() => state = const ChatRoomState();
}

final chatRoomControllerProvider =
NotifierProvider<ChatRoomController, ChatRoomState>(
  ChatRoomController.new,
);
