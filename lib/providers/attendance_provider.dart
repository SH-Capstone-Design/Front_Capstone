import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/attendance_service.dart';
import 'coin_provider.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final baseUrl = dotenv.env['BASE_URL'] ?? '';
  return AttendanceService(baseUrl: baseUrl);
});

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
    final result = await service.checkIn();
    if (!result['success']) return {'success': false};

    final newTotal = result['newTotalCoinBalance'];
    coinNotifier.updateCoin(newTotal);

    return {
      'success': true,
      'coinGained': result['coinGained'],
      'consecutiveDays': result['consecutiveDays'],
      'newTotalCoinBalance': newTotal,
    };
  }

  /// 🔥 새로 추가: 현재 상태 조회
  Future<Map<String, dynamic>> getStatus() async {
    return await service.getStatus();
  }
}
