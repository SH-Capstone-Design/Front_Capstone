// lib/providers/session_provider.dart
//
// 두 명의 커플이 공유할 채팅 세션 ID와 상대방 ID를 전역으로 관리하는 Provider.
// A가 세션을 생성하면 chatSessionId를 저장하고,
// B는 해당 값의 변화를 감지해 자동으로 채팅방에 입장한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ✅ 현재 커플이 참여 중인 채팅 세션 ID (없으면 null)
final sessionIdProvider = StateProvider<String?>((ref) => null);

/// ✅ 세션 상태를 관리하는 헬퍼 Notifier
/// - 세션 생성, 종료, 초기화 로직을 중앙에서 제어
/// - partnerId를 함께 저장해 커플 상대 식별 가능
class SessionController extends StateNotifier<String?> {
  SessionController() : super(null);

  String? _partnerId;

  /// 세션 시작 시 ID 저장
  void setSession(String sessionId) {
    state = sessionId;
  }

  /// 상대방 ID 저장
  void setPartner(String partnerId) {
    _partnerId = partnerId;
  }

  /// 상대방 ID 조회
  String? get partnerId => _partnerId;

  /// 세션 종료 시 ID 및 상대 정보 제거
  void clearSession() {
    state = null;
    _partnerId = null;
  }

  /// 현재 세션이 존재하는지 여부
  bool get hasActiveSession => state != null && state!.isNotEmpty;
}

/// ✅ SessionController Provider
final sessionControllerProvider =
StateNotifierProvider<SessionController, String?>((ref) {
  return SessionController();
});
