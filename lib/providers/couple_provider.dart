// lib/providers/couple_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/couple_service.dart';

/// 🔹 커플 상태 (파트너 정보 포함) Provider
final coupleStatusProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await CoupleService.fetchCoupleStatus();
});
