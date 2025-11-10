import 'store_models.dart';

class InventoryItemDTO {
  final int inventoryId;
  final StoreItemDTO item;
  final DateTime acquiredAt;

  InventoryItemDTO({
    required this.inventoryId,
    required this.item,
    required this.acquiredAt,
  });

  factory InventoryItemDTO.fromJson(Map<String, dynamic> json) {
    return InventoryItemDTO(
      inventoryId: json['inventoryId'] as int,
      item: StoreItemDTO.fromJson(json['item']),
      acquiredAt: DateTime.parse(json['acquiredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'item': item.toJson(),
      'acquiredAt': acquiredAt.toIso8601String(),
    };
  }
}
