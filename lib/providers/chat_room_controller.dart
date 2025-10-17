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
  bool _isDisposed = false;

  @override
  ChatRoomState build() {
    _repo = ref.read(chatRepositoryProvider);

    ref.onDispose(() {
      _isDisposed = true;
      _eventSub?.cancel();
    });

    return const ChatRoomState();
  }

  /// ✅ 세션 생성 + 자동 초대
  Future<void> startSession({
    required String userId,
    required String partnerId, // 👈 초대할 상대방 ID 추가
  }) async {
    if (_isDisposed) return;

    state = state.copyWith(creating: true, error: null);
    try {
      // 1️⃣ 세션 생성 (REST)
      final room = await _repo.startSession();
      if (_isDisposed) return;
      state = state.copyWith(creating: false, room: room);

      // 2️⃣ WebSocket 연결
      if (_repo is ChatRepositoryImpl) {
        final chatRepo = _repo as ChatRepositoryImpl;
        await chatRepo.connectSocket(
          chatSessionId: room.chatSessionId,
          userId: userId,
        );

        // 3️⃣ 상대방에게 초대 전송
        await chatRepo.sendInvite(
          chatSessionId: room.chatSessionId,
          inviteeId: partnerId,
        );
        print("💌 초대 전송 완료 → 상대방: $partnerId");

        // 4️⃣ 이벤트 구독
        _eventSub?.cancel();
        _eventSub =
            chatRepo.subscribeEvents(room.chatSessionId).listen((event) {
              if (_isDisposed) return;
              state = state.copyWith(events: [...state.events, event]);
            });
      }
    } catch (e) {
      if (_isDisposed) return;
      print("❌ startSession 오류: $e");
      state = state.copyWith(creating: false, error: e.toString());
    }
  }

  /// ✅ 세션 종료
  Future<void> closeSession() async {
    if (_isDisposed) return;

    final room = state.room;
    if (room == null) return;

    try {
      await _repo.closeSession(room.chatSessionId);
      _eventSub?.cancel();
      state = const ChatRoomState();
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendCategorySelect({
    required String chatSessionId,
    required int categoryId,
  }) async {
    if (_isDisposed) return;
    await _repo.sendCategorySelect(
      chatSessionId: chatSessionId,
      categoryId: categoryId,
    );
  }


  /// ✅ 상태 초기화
  void clear() {
    if (_isDisposed) return;
    _eventSub?.cancel();
    state = const ChatRoomState();
  }
}

/// ✅ Provider 등록
final chatRoomControllerProvider =
NotifierProvider<ChatRoomController, ChatRoomState>(
  ChatRoomController.new,
);
