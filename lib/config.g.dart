// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
  address: json['address'] as String? ?? 'http://127.0.0.1:8188',
  duration: (json['duration'] as num?)?.toInt() ?? 5,
  model: json['model'] as String?,
  tagModel: json['tag_model'] as String? ?? "dart-v2-sft",
  rating: json['rating'] as String? ?? 'general',
  blockTags:
      (json['block_tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const ['nsfw'],
  target: json['target'] == null
      ? null
      : Target.fromJson(json['target'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
  'address': instance.address,
  'duration': instance.duration,
  'model': instance.model,
  'tag_model': instance.tagModel,
  'rating': instance.rating,
  'block_tags': instance.blockTags,
  'target': instance.target,
};
