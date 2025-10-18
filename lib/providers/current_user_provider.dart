import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/services/api_service.dart';

/// 👤 서버에서 최신 사용자 정보를 가져오는 Provider
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userInfo = await ApiService.fetchUserInfo();
  return userInfo;
});
