import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'target.dart';

part 'config.g.dart';

@JsonSerializable()
class Config {
  String address;
  String authorization;
  int duration;
  String? model;
  @JsonKey(name: 'tag_model')
  String tagModel;
  String upscaleModel;
  String rating;
  @JsonKey(name: 'block_tags')
  List<String>? blockTags;
  Target? target;
  int width;
  int height;
  bool releaseMemory;

  Config({
    this.address = 'http://127.0.0.1:8188',
    this.authorization = '',
    this.duration = 5,
    required this.model,
    this.tagModel = "dart-v2-moe-sft",
    this.upscaleModel = '4x-AnimeSharp.pth',
    this.rating = 'general',
    this.blockTags = const ['nsfw'],
    this.target,
    this.width = 1366,
    this.height = 768,
    this.releaseMemory = false,
  });

  @override
  String toString() {
    return 'Config(address: $address, authorization: $authorization, duration: $duration, model: $model, tagModel: $tagModel, upscaleModel: $upscaleModel, rating: $rating, blockTags: $blockTags, target: $target, width: $width, height: $height)';
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    return _$ConfigFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ConfigToJson(this);

  Config copyWith({
    String? address,
    String? authorization,
    int? duration,
    String? model,
    String? tagModel,
    String? upscaleModel,
    String? rating,
    List<String>? blockTags,
    Target? target,
    int? width,
    int? height,
    bool? releaseMemory,
  }) {
    return Config(
      address: address ?? this.address,
      authorization: authorization ?? this.authorization,
      duration: duration ?? this.duration,
      model: model ?? this.model,
      tagModel: tagModel ?? this.tagModel,
      upscaleModel: upscaleModel ?? this.upscaleModel,
      rating: rating ?? this.rating,
      blockTags: blockTags ?? this.blockTags,
      target: target ?? this.target,
      width: width ?? this.width,
      height: height ?? this.height,
      releaseMemory: releaseMemory ?? this.releaseMemory,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! Config) return false;
    final mapEquals = const DeepCollectionEquality().equals;
    return mapEquals(other.toJson(), toJson());
  }

  @override
  int get hashCode =>
      address.hashCode ^
      authorization.hashCode ^
      duration.hashCode ^
      model.hashCode ^
      tagModel.hashCode ^
      upscaleModel.hashCode ^
      rating.hashCode ^
      blockTags.hashCode ^
      target.hashCode ^
      width.hashCode ^
      height.hashCode;
}
