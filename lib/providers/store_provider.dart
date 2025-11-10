import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/store_service.dart';
import '../models/store_models.dart';

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService(); // 내부에서 dotenv.env['BASE_URL'] 사용
});

final storeItemsProvider = FutureProvider<List<StoreItemDTO>>((ref) async {
  final service = ref.watch(storeServiceProvider);
  return service.fetchStoreItems();
});
