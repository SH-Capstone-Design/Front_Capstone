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

  // ---------------------------------------------------------------------------
  // ✅ 1️⃣ 개인 채널(WebSocket 기본 연결)
  // ---------------------------------------------------------------------------
  Future<void> connectBase() async {
    if (_isDisposed) return;
    if (_repo is! ChatRepositoryImpl) return;

    final chatRepo = _repo as ChatRepositoryImpl;

    await chatRepo.connectBase();

    // ✅ 초대 수신 이벤트 처리
    _eventSub?.cancel();
    _eventSub = chatRepo.eventStream.listen((event) async {
      if (_isDisposed) return;

      // 초대 수신 시 자동 참여
      if (event.eventType == "INVITATION") {
        final chatSessionId = event.payload?['chatSessionId'] as String?;
        if (chatSessionId != null) {
          print("📨 초대 수신 → 자동 join 시도: $chatSessionId");
          await chatRepo.sendJoin(chatSessionId: chatSessionId);
          await chatRepo.subscribeRoom(chatSessionId: chatSessionId);

          // ✅ 상태 업데이트
          state = state.copyWith(room: ChatRoom(chatSessionId: chatSessionId));
        }
      }

      state = state.copyWith(events: [...state.events, event]);
    });
  }

  // ---------------------------------------------------------------------------
  // ✅ 2️⃣ 세션 생성 + 초대 전송 (A 사용자)
  // ---------------------------------------------------------------------------
  Future<void> startSession({
    required String userId,
    required String partnerId,
  }) async {
    if (_isDisposed) return;

    state = state.copyWith(creating: true, error: null);
    try {
      // 1️⃣ REST로 새 채팅방 생성
      final room = await _repo.startSession();
      state = state.copyWith(creating: false, room: room);

      // 2️⃣ 개인 채널 연결
      await connectBase();

      // 3️⃣ 상대방 초대 전송
      if (_repo is ChatRepositoryImpl) {
        final chatRepo = _repo as ChatRepositoryImpl;
        await chatRepo.sendInvite(
          chatSessionId: room.chatSessionId,
          inviteeId: partnerId,
        );
        print("💌 초대 전송 완료 → 상대방: $partnerId");

        // 4️⃣ 자기 자신 방 구독
        await chatRepo.subscribeRoom(chatSessionId: room.chatSessionId);
      }
    } catch (e) {
      print("❌ startSession 오류: $e");
      state = state.copyWith(creating: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 4️⃣ 세션 종료
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // ✅ 5️⃣ 상태 초기화
  // ---------------------------------------------------------------------------
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
