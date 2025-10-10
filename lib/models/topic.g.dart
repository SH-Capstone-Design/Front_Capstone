// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TopicCategoryImpl _$$TopicCategoryImplFromJson(Map<String, dynamic> json) =>
    _$TopicCategoryImpl(
      categoryId: (json['categoryId'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$$TopicCategoryImplToJson(_$TopicCategoryImpl instance) =>
    <String, dynamic>{'categoryId': instance.categoryId, 'name': instance.name};

_$TopicImpl _$$TopicImplFromJson(Map<String, dynamic> json) => _$TopicImpl(
  topicId: (json['topicId'] as num).toInt(),
  topicCategory: TopicCategory.fromJson(
    json['topicCategory'] as Map<String, dynamic>,
  ),
  content: json['content'] as String,
);

Map<String, dynamic> _$$TopicImplToJson(_$TopicImpl instance) =>
    <String, dynamic>{
      'topicId': instance.topicId,
      'topicCategory': instance.topicCategory,
      'content': instance.content,
    };
