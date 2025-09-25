import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final coupleDateProvider = StateNotifierProvider<CoupleDateNotifier, DateTime?>(
      (ref) => CoupleDateNotifier(),
);

class CoupleDateNotifier extends StateNotifier<DateTime?> {
  CoupleDateNotifier() : super(null) {
    _load();
  }

  // 저장된 날짜 불러오기
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('coupleDate');
    if (dateStr != null) state = DateTime.tryParse(dateStr);
  }

  // 날짜 저장 및 상태 갱신
  Future<void> save(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coupleDate', date.toIso8601String());
    state = date; // 상태 갱신 → 홈 화면 자동 rebuild
  }

  // D-Day 텍스트 계산
  String getDDayText() {
    if (state == null) return '사귄 날짜를 설정해주세요';
    final now = DateTime.now();
    final diff = now.difference(state!).inDays + 1; // 오늘 포함 1일부터 시작
    return '우리가 만난지 $diff일 🩷';
  }
}
