import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/attendance_service.dart';
import 'coin_provider.dart';

/// AttendanceService 주입
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final baseUrl = dotenv.env['BASE_URL'] ?? '';
  return AttendanceService(baseUrl: baseUrl);
});

/// 버튼 클릭 시만 호출 가능한 함수 Provider
final attendanceCheckProvider = Provider<AttendanceCheck>((ref) {
  final service = ref.read(attendanceServiceProvider);
  final coinNotifier = ref.read(coinProvider.notifier);

  return AttendanceCheck(service: service, coinNotifier: coinNotifier);
});

class AttendanceCheck {
  final AttendanceService service;
  final CoinNotifier coinNotifier;

  AttendanceCheck({required this.service, required this.coinNotifier});

  Future<Map<String, dynamic>> checkIn() async {
    try {
      final result = await service.checkIn();

      final coinGained =
          int.tryParse(result['coinGained']?.toString() ?? '0') ?? 0;
      final consecutiveDays =
          int.tryParse(result['consecutiveDays']?.toString() ?? '0') ?? 0;
      final newTotalCoinBalance = int.tryParse(
          result['newTotalCoinBalance']?.toString() ?? '0') ??
          coinNotifier.state;

      if (coinGained > 0) coinNotifier.updateCoin(newTotalCoinBalance);

      return {
        'success': true,
        'coinGained': coinGained,
        'consecutiveDays': consecutiveDays,
        'newTotalCoinBalance': newTotalCoinBalance,
      };
    } catch (e) {
      return {
        'success': false,
        'coinGained': 0,
        'consecutiveDays': 0,
        'newTotalCoinBalance': coinNotifier.state,
      };
    }
  }
}
