import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/coin_service.dart';

/// CoinService 주입
final coinServiceProvider = Provider<CoinService>((ref) {
  final baseUrl = dotenv.env['BASE_URL']!;
  return CoinService(baseUrl: baseUrl);
});

/// 코인 상태 관리 Provider
final coinProvider = StateNotifierProvider<CoinNotifier, int>((ref) {
  final service = ref.watch(coinServiceProvider);
  return CoinNotifier(service);
});

class CoinNotifier extends StateNotifier<int> {
  final CoinService service;

  CoinNotifier(this.service) : super(0);

  /// 🔹 코인 조회
  Future<void> loadCoin() async {
    try {
      final coin = await service.fetchCoinBalance();
      state = coin;
      print('✅ 코인 조회 성공: $state');
    } catch (e) {
      print('❌ 코인 조회 실패: $e');
    }
  }

  /// 🔹 코인 사용 (아이템 구매)
  Future<bool> spendCoin(int price) async {
    if (state < price) return false;
    final newCoin = state - price;
    try {
      final success = await service.updateCoin(newCoin);
      if (success) state = newCoin;
      return success;
    } catch (e) {
      print('❌ 코인 차감 실패: $e');
      return false;
    }
  }

  /// 🔹 코인 추가 (출석 등)
  Future<bool> addCoin(int amount) async {
    try {
      state += amount; // 코인 상태 업데이트
      return true;
    } catch (e) {
      print('코인 추가 실패: $e');
      return false;
    }
  }

  /// 🔹 서버 응답 기반으로 즉시 갱신
  void updateCoin(int newCoin) {
    state = newCoin;
    print('🔄 코인 상태 갱신: $state');
  }
}
