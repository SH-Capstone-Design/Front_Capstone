// lib/providers/chat_room_controller.dart
// 채팅방 생성/세션 상태 및 이벤트를 관리하는 Riverpod Notifier

import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';

/// 채팅방 상태
class ChatRoomState {
  final bool creating; // 세션 생성 중 여부
  final ChatRoom? room; // 생성된 채팅방 정보
  final String? error; // 오류 메시지
  final List<ChatRoomEvent> events; // 수신된 이벤트 리스트

  const ChatRoomState({
    this.creating = false,
    this.room,
    this.error,
    this.events = const [],
  });

  ChatRoomState copyWith({
    bool? creating,
    ChatRoom? room,
    String? error,
    List<ChatRoomEvent>? events,
  }) {
    return ChatRoomState(
      creating: creating ?? this.creating,
      room: room ?? this.room,
      error: error,
      events: events ?? this.events,
    );
  }
}

/// 채팅방 컨트롤러
class ChatRoomController extends Notifier<ChatRoomState> {
  late final ChatRepository _repo;
  StreamSubscription<ChatRoomEvent>? _eventSub;

  @override
  ChatRoomState build() {
    _repo = ref.read(chatRepositoryProvider);
    ref.onDispose(() {
      _eventSub?.cancel();
    });
    return const ChatRoomState();
  }

  /// ✅ 세션 생성 (REST: POST /api/chat/rooms)
  Future<void> startSession() async {
    state = state.copyWith(creating: true, error: null);
    try {
      final room = await _repo.startSession();
      state = state.copyWith(creating: false, room: room);

      // ✅ 이벤트 구독 시작
      _eventSub?.cancel();
      if (_repo is ChatRepositoryImpl) {
        _eventSub = (_repo as ChatRepositoryImpl)
            .subscribeEvents(room.chatSessionId)
            .listen((event) {
          state = state.copyWith(events: [...state.events, event]);
        });
      }
    } catch (e) {
      state = state.copyWith(creating: false, error: e.toString());
    }
  }

  /// ✅ 세션 종료 (REST: POST /api/chat/rooms/end)
  Future<void> closeSession() async {
    final room = state.room;
    if (room == null) return;

    try {
      await _repo.closeSession(room.chatSessionId);
      _eventSub?.cancel();
      state = const ChatRoomState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 상태 초기화
  void clear() {
    _eventSub?.cancel();
    state = const ChatRoomState();
  }
}

/// Provider
final chatRoomControllerProvider =
NotifierProvider<ChatRoomController, ChatRoomState>(
  ChatRoomController.new,
);
