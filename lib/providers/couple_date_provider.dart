import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final coupleDDayProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final dateStr = prefs.getString('coupleDate');

  if (dateStr == null) {
    return '우리가 만난지'; // 기본값
  }

  final coupleDate = DateTime.parse(dateStr);
  final now = DateTime.now();

  final difference = now.difference(coupleDate).inDays + 1;
  return '우리가 만난지 $difference일 째💕';
});
