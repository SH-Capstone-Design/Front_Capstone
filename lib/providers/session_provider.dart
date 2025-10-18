// lib/providers/session_provider.dart
//
// ✅ 커플 간 채팅 세션 및 상대방 정보를 전역 상태로 관리하는 Provider.
// - A가 세션 생성 시 chatSessionId를 저장.
// - B는 초대 수신 시 sessionId를 자동 업데이트하고 join().
// - 커플 연결 시 partnerId를 서버에서 받아 저장.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ✅ 세션 상태 데이터 모델
class SessionState {
  final String? chatSessionId; // 현재 진행 중인 채팅방 ID
  final String? partnerId; // 상대방 유저 ID

  const SessionState({
    this.chatSessionId,
    this.partnerId,
  });

  SessionState copyWith({
    String? chatSessionId,
    String? partnerId,
  }) {
    return SessionState(
      chatSessionId: chatSessionId ?? this.chatSessionId,
      partnerId: partnerId ?? this.partnerId,
    );
  }

  bool get hasActiveSession =>
      chatSessionId != null && chatSessionId!.isNotEmpty;
}

/// ✅ 세션 상태를 관리하는 Notifier
class SessionController extends StateNotifier<SessionState> {
  SessionController() : super(const SessionState());

  /// 🔹 세션 시작 시 chatSessionId 저장
  void setSession(String chatSessionId) {
    state = state.copyWith(chatSessionId: chatSessionId);
  }

  /// 🔹 상대방 ID 저장
  void setPartner(String partnerId) {
    state = state.copyWith(partnerId: partnerId);
  }

  /// 🔹 상대방 ID 조회
  String? get partnerId => state.partnerId;

  /// 🔹 세션 ID 조회
  String? get chatSessionId => state.chatSessionId;

  /// 🔹 세션 종료 시 ID 및 상대 정보 제거
  void clearSession() {
    state = const SessionState();
  }

  /// 🔹 현재 세션이 존재하는지 여부
  bool get hasActiveSession => state.hasActiveSession;
}

/// ✅ SessionController Provider
final sessionControllerProvider =
StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController();
});
