// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
  address: json['address'] as String? ?? 'http://127.0.0.1:8188',
  authorization: json['authorization'] as String? ?? '',
  duration: (json['duration'] as num?)?.toInt() ?? 5,
  model: json['model'] as String?,
  tagModel: json['tag_model'] as String? ?? "dart-v2-moe-sft",
  upscaleModel: json['upscaleModel'] as String? ?? '4x-AnimeSharp.pth',
  rating: json['rating'] as String? ?? 'general',
  blockTags:
      (json['block_tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const ['nsfw'],
  target: json['target'] == null
      ? null
      : Target.fromJson(json['target'] as Map<String, dynamic>),
  width: (json['width'] as num?)?.toInt() ?? 1366,
  height: (json['height'] as num?)?.toInt() ?? 768,
);

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
  'address': instance.address,
  'authorization': instance.authorization,
  'duration': instance.duration,
  'model': instance.model,
  'tag_model': instance.tagModel,
  'upscaleModel': instance.upscaleModel,
  'rating': instance.rating,
  'block_tags': instance.blockTags,
  'target': instance.target,
  'width': instance.width,
  'height': instance.height,
};
