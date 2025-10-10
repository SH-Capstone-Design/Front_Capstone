// lib/providers/chat_room_controller.dart
// 채팅방 생성/세션 상태 및 이벤트를 관리하는 Riverpod Notifier

import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';

/// ✅ 채팅방 상태
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

/// ✅ 채팅방 컨트롤러 (상태 + 이벤트 관리)
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
  Future<void> startSession({required String userId}) async {
    state = state.copyWith(creating: true, error: null);

    try {
      // 1️⃣ 세션 생성
      final room = await _repo.startSession();
      state = state.copyWith(creating: false, room: room);

      // 2️⃣ WebSocket 연결 (STOMP)
      if (_repo is ChatRepositoryImpl) {
        final chatRepo = _repo as ChatRepositoryImpl;
        await chatRepo.connectSocket(
          chatSessionId: room.chatSessionId,
          userId: userId,
        );

        // 3️⃣ 이벤트 구독 시작 (파라미터 없음)
        _eventSub?.cancel();
        _eventSub = chatRepo.subscribeEvents().listen((event) {
          state = state.copyWith(events: [...state.events, event]);
        });
      }
    } catch (e) {
      state = state.copyWith(creating: false, error: e.toString());
    }
  }

  /// ✅ 세션 종료 (REST + 소켓 종료)
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

  /// ✅ 상태 초기화
  void clear() {
    _eventSub?.cancel();
    state = const ChatRoomState();
  }
}

/// ✅ Provider 등록
final chatRoomControllerProvider =
NotifierProvider<ChatRoomController, ChatRoomState>(
  ChatRoomController.new,
);
