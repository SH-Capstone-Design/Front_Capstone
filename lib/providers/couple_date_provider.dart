import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final coupleDDayProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final dateStr = prefs.getString('coupleDate');

  if (dateStr == null) {
    return '사귄 날짜를 설정해주세요 💕';
  }

  try {
    final coupleDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(coupleDate).inDays + 1;

    return '우리가 만난 지 $difference일 째 💕';
  } catch (e) {
    return '날짜를 불러올 수 없습니다';
  }
});
