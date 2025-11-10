import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_models.dart';
import '../services/inventory_service.dart';
import '../models/store_models.dart';

/// 🔹 인벤토리 상태 관리
final inventoryProvider =
StateNotifierProvider<InventoryNotifier, List<InventoryItemDTO>>(
      (ref) => InventoryNotifier(),
);

/// 🔹 현재 착용 데코 상태 관리
final currentDecorationProvider =
StateNotifierProvider<CurrentDecorationNotifier, CurrentDecorationDTO?>(
      (ref) => CurrentDecorationNotifier(),
);

/// 🔹 인벤토리 StateNotifier
class InventoryNotifier extends StateNotifier<List<InventoryItemDTO>> {
  final _service = InventoryService();

  InventoryNotifier() : super([]);

  /// 서버에서 인벤토리 불러오기
  Future<void> fetchInventory() async {
    try {
      final items = await _service.fetchInventory();
      state = items;
    } catch (e) {
      throw Exception('인벤토리 로딩 실패: $e');
    }
  }

  /// 구매 직후 인벤토리에 추가
  void addItemFromPurchase(InventoryItemDTO item) {
    // 기존 리스트를 복사해서 새 리스트로 상태 갱신 → UI 즉시 반영
    state = [...state, item];
  }

  /// 아이템 적용
  Future<void> applyItem(int itemId) async {
    try {
      await _service.applyDecoration(itemId);
    } catch (e) {
      throw Exception('아이템 적용 실패: $e');
    }
  }
}

/// 🔹 현재 착용 데코 StateNotifier
class CurrentDecorationNotifier extends StateNotifier<CurrentDecorationDTO?> {
  final _service = InventoryService();

  CurrentDecorationNotifier() : super(null);

  /// 서버에서 현재 착용 데코 조회
  Future<void> fetchCurrentDecoration() async {
    try {
      final deco = await _service.fetchCurrentDecoration();
      state = deco;
    } catch (e) {
      throw Exception('현재 데코 조회 실패: $e');
    }
  }

  /// 착용 아이템 업데이트 (옵션)
  void updateDecoration(CurrentDecorationDTO deco) {
    state = deco;
  }
}
