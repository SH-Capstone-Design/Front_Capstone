import 'dart:async';
import 'package:connectbeat/models/chat_room.dart';
import 'package:connectbeat/models/chat_room_event.dart';
import 'package:connectbeat/services/chat_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/chat_repository.dart';
import 'package:connectbeat/providers/chat_repository_provider.dart';

/// ✅ 채팅방 상태
class ChatRoomState {
  final bool creating;
  final ChatRoom? room;
  final String? error;
  final List<ChatRoomEvent> events;
  final bool partnerJoined;
  final bool chatEnded;

  const ChatRoomState({
    this.creating = false,
    this.room,
    this.error,
    this.events = const [],
    this.partnerJoined = false,
    this.chatEnded = false, // 기본값 false
  });

  ChatRoomState copyWith({
    bool? creating,
    ChatRoom? room,
    String? error,
    List<ChatRoomEvent>? events,
    bool? partnerJoined,
    bool? chatEnded,
  }) {
    return ChatRoomState(
      creating: creating ?? this.creating,
      room: room ?? this.room,
      error: error,
      events: events ?? this.events,
      partnerJoined: partnerJoined ?? this.partnerJoined,
    );
  }

  bool get canStartChat => room != null && partnerJoined;
}

/// ✅ 채팅방 컨트롤러
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

  // 개인 채널 연결 및 이벤트 수신
  Future<void> connectBase() async {
    if (_isDisposed) return;
    if (_repo is! ChatRepositoryImpl) return;

    final chatRepo = _repo as ChatRepositoryImpl;
    await chatRepo.connectBase();

    _eventSub?.cancel();
    _eventSub = chatRepo.eventStream.listen((event) async {
      if (_isDisposed) return;

      // ❌ INVITATION 이벤트는 UI에서 수락 후 join하도록 변경
      if (event.eventType == "INVITATION") {
        final chatSessionId = event.payload?['chatSessionId'] as String?;
        if (chatSessionId != null) {
          print("📨 초대 수신 → UI에서 수락 시 join 필요: $chatSessionId");
          state = state.copyWith(room: ChatRoom(chatSessionId: chatSessionId));
        }
      }

      // 상대방 입장 감지
      if (event.eventType == "USER_JOINED") {
        state = state.copyWith(partnerJoined: true);
      }

      // 종료 이벤트 감지 → 로컬 상태 초기화
      if (event.eventType == "CONVERSATION_ENDED") {
        _eventSub?.cancel();
        state = state.copyWith(
          room: null,
          partnerJoined: false,
          events: [...state.events, event],
          chatEnded: true, // 새 필드
        );
        return;
      }

      state = state.copyWith(events: [...state.events, event]);
    });
  }

  // 세션 생성 + 초대 전송 (A)
  Future<void> startSession({
    required String userId,
    required String partnerId,
  }) async {
    if (_isDisposed) return;

    state = state.copyWith(creating: true, error: null);
    try {
      final room = await _repo.startSession();
      state = state.copyWith(creating: false, room: room);

      await connectBase();

      if (_repo is ChatRepositoryImpl) {
        final chatRepo = _repo as ChatRepositoryImpl;
        await chatRepo.sendInvite(
          chatSessionId: room.chatSessionId,
          inviteeId: partnerId,
        );
        await chatRepo.subscribeRoom(chatSessionId: room.chatSessionId);
      }
    } catch (e) {
      state = state.copyWith(creating: false, error: e.toString());
    }
  }

  /// UI에서 초대 수락 시 호출
  Future<void> acceptInvitation() async {
    final room = state.room;
    if (_isDisposed || room == null || _repo is! ChatRepositoryImpl) return;

    final chatRepo = _repo as ChatRepositoryImpl;
    await chatRepo.sendJoin(chatSessionId: room.chatSessionId);
    state = state.copyWith(partnerJoined: true);
  }

  Future<void> closeSession() async {
    if (_isDisposed) return;
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

  void clear() {
    if (_isDisposed) return;
    _eventSub?.cancel();
    state = const ChatRoomState();
  }
}

final chatRoomControllerProvider =
NotifierProvider<ChatRoomController, ChatRoomState>(
  ChatRoomController.new,
);
