// lib/models/topic.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'topic.freezed.dart';
part 'topic.g.dart';

/// 🧠 카테고리 모델 (예: 연애, 가치관, 추억 등)
@freezed
class TopicCategory with _$TopicCategory {
  const factory TopicCategory({
    required int categoryId,
    required String name,
  }) = _TopicCategory;

  factory TopicCategory.fromJson(Map<String, dynamic> json) =>
      _$TopicCategoryFromJson(json);
}

/// 💬 대화 주제 모델 (랜덤으로 선택되는 실제 질문)
@freezed
class Topic with _$Topic {
  const factory Topic({
    required int topicId,
    required TopicCategory topicCategory,
    required String content,
  }) = _Topic;

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
}
