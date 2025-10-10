// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TopicCategory _$TopicCategoryFromJson(Map<String, dynamic> json) {
  return _TopicCategory.fromJson(json);
}

/// @nodoc
mixin _$TopicCategory {
  int get categoryId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this TopicCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TopicCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopicCategoryCopyWith<TopicCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopicCategoryCopyWith<$Res> {
  factory $TopicCategoryCopyWith(
    TopicCategory value,
    $Res Function(TopicCategory) then,
  ) = _$TopicCategoryCopyWithImpl<$Res, TopicCategory>;
  @useResult
  $Res call({int categoryId, String name});
}

/// @nodoc
class _$TopicCategoryCopyWithImpl<$Res, $Val extends TopicCategory>
    implements $TopicCategoryCopyWith<$Res> {
  _$TopicCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TopicCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? categoryId = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            categoryId:
                null == categoryId
                    ? _value.categoryId
                    : categoryId // ignore: cast_nullable_to_non_nullable
                        as int,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TopicCategoryImplCopyWith<$Res>
    implements $TopicCategoryCopyWith<$Res> {
  factory _$$TopicCategoryImplCopyWith(
    _$TopicCategoryImpl value,
    $Res Function(_$TopicCategoryImpl) then,
  ) = __$$TopicCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int categoryId, String name});
}

/// @nodoc
class __$$TopicCategoryImplCopyWithImpl<$Res>
    extends _$TopicCategoryCopyWithImpl<$Res, _$TopicCategoryImpl>
    implements _$$TopicCategoryImplCopyWith<$Res> {
  __$$TopicCategoryImplCopyWithImpl(
    _$TopicCategoryImpl _value,
    $Res Function(_$TopicCategoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TopicCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? categoryId = null, Object? name = null}) {
    return _then(
      _$TopicCategoryImpl(
        categoryId:
            null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                    as int,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TopicCategoryImpl implements _TopicCategory {
  const _$TopicCategoryImpl({required this.categoryId, required this.name});

  factory _$TopicCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopicCategoryImplFromJson(json);

  @override
  final int categoryId;
  @override
  final String name;

  @override
  String toString() {
    return 'TopicCategory(categoryId: $categoryId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopicCategoryImpl &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, categoryId, name);

  /// Create a copy of TopicCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopicCategoryImplCopyWith<_$TopicCategoryImpl> get copyWith =>
      __$$TopicCategoryImplCopyWithImpl<_$TopicCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopicCategoryImplToJson(this);
  }
}

abstract class _TopicCategory implements TopicCategory {
  const factory _TopicCategory({
    required final int categoryId,
    required final String name,
  }) = _$TopicCategoryImpl;

  factory _TopicCategory.fromJson(Map<String, dynamic> json) =
      _$TopicCategoryImpl.fromJson;

  @override
  int get categoryId;
  @override
  String get name;

  /// Create a copy of TopicCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopicCategoryImplCopyWith<_$TopicCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Topic _$TopicFromJson(Map<String, dynamic> json) {
  return _Topic.fromJson(json);
}

/// @nodoc
mixin _$Topic {
  int get topicId => throw _privateConstructorUsedError;
  TopicCategory get topicCategory => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;

  /// Serializes this Topic to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopicCopyWith<Topic> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopicCopyWith<$Res> {
  factory $TopicCopyWith(Topic value, $Res Function(Topic) then) =
      _$TopicCopyWithImpl<$Res, Topic>;
  @useResult
  $Res call({int topicId, TopicCategory topicCategory, String content});

  $TopicCategoryCopyWith<$Res> get topicCategory;
}

/// @nodoc
class _$TopicCopyWithImpl<$Res, $Val extends Topic>
    implements $TopicCopyWith<$Res> {
  _$TopicCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? topicId = null,
    Object? topicCategory = null,
    Object? content = null,
  }) {
    return _then(
      _value.copyWith(
            topicId:
                null == topicId
                    ? _value.topicId
                    : topicId // ignore: cast_nullable_to_non_nullable
                        as int,
            topicCategory:
                null == topicCategory
                    ? _value.topicCategory
                    : topicCategory // ignore: cast_nullable_to_non_nullable
                        as TopicCategory,
            content:
                null == content
                    ? _value.content
                    : content // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TopicCategoryCopyWith<$Res> get topicCategory {
    return $TopicCategoryCopyWith<$Res>(_value.topicCategory, (value) {
      return _then(_value.copyWith(topicCategory: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TopicImplCopyWith<$Res> implements $TopicCopyWith<$Res> {
  factory _$$TopicImplCopyWith(
    _$TopicImpl value,
    $Res Function(_$TopicImpl) then,
  ) = __$$TopicImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int topicId, TopicCategory topicCategory, String content});

  @override
  $TopicCategoryCopyWith<$Res> get topicCategory;
}

/// @nodoc
class __$$TopicImplCopyWithImpl<$Res>
    extends _$TopicCopyWithImpl<$Res, _$TopicImpl>
    implements _$$TopicImplCopyWith<$Res> {
  __$$TopicImplCopyWithImpl(
    _$TopicImpl _value,
    $Res Function(_$TopicImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? topicId = null,
    Object? topicCategory = null,
    Object? content = null,
  }) {
    return _then(
      _$TopicImpl(
        topicId:
            null == topicId
                ? _value.topicId
                : topicId // ignore: cast_nullable_to_non_nullable
                    as int,
        topicCategory:
            null == topicCategory
                ? _value.topicCategory
                : topicCategory // ignore: cast_nullable_to_non_nullable
                    as TopicCategory,
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TopicImpl implements _Topic {
  const _$TopicImpl({
    required this.topicId,
    required this.topicCategory,
    required this.content,
  });

  factory _$TopicImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopicImplFromJson(json);

  @override
  final int topicId;
  @override
  final TopicCategory topicCategory;
  @override
  final String content;

  @override
  String toString() {
    return 'Topic(topicId: $topicId, topicCategory: $topicCategory, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopicImpl &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            (identical(other.topicCategory, topicCategory) ||
                other.topicCategory == topicCategory) &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, topicId, topicCategory, content);

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopicImplCopyWith<_$TopicImpl> get copyWith =>
      __$$TopicImplCopyWithImpl<_$TopicImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopicImplToJson(this);
  }
}

abstract class _Topic implements Topic {
  const factory _Topic({
    required final int topicId,
    required final TopicCategory topicCategory,
    required final String content,
  }) = _$TopicImpl;

  factory _Topic.fromJson(Map<String, dynamic> json) = _$TopicImpl.fromJson;

  @override
  int get topicId;
  @override
  TopicCategory get topicCategory;
  @override
  String get content;

  /// Create a copy of Topic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopicImplCopyWith<_$TopicImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
