// lib/providers/topic_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/models/topic.dart';
import 'package:connectbeat/services/topic_service.dart';
import 'package:connectbeat/services/auth_service.dart';

/// 🧩 TopicService 인스턴스 제공
final topicServiceProvider = Provider<TopicService>((ref) {
  return TopicService();
});

/// 🧠 전체 카테고리 목록 조회 Provider
final topicCategoriesProvider =
FutureProvider<List<TopicCategory>>((ref) async {
  final token = await AuthService.getToken();

  // ✅ null 안전 처리
  if (token == null || token.isEmpty) {
    throw Exception('토큰이 존재하지 않습니다. 다시 로그인해주세요.');
  }

  final topicService = ref.read(topicServiceProvider);
  return topicService.fetchCategories(token);
});

/// 🎯 선택된 카테고리 상태 관리 Provider
final selectedCategoryProvider = StateProvider<TopicCategory?>((ref) => null);

/// 💬 선택된 카테고리 기반 랜덤 주제 가져오기 Provider
final randomTopicProvider =
FutureProvider.family<Topic, int>((ref, categoryId) async {
  final token = await AuthService.getToken();

  // ✅ null 안전 처리
  if (token == null || token.isEmpty) {
    throw Exception('토큰이 존재하지 않습니다. 다시 로그인해주세요.');
  }

  final topicService = ref.read(topicServiceProvider);
  return topicService.fetchRandomTopic(token: token, categoryId: categoryId);
});
