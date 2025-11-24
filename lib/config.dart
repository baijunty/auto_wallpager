import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'target.dart';

part 'config.g.dart';

@JsonSerializable()
class Config {
  String address;
  int duration;
  String? model;
  @JsonKey(name: 'tag_model')
  String tagModel;
  String rating;
  @JsonKey(name: 'block_tags')
  List<String>? blockTags;
  Target? target;

  Config({
    this.address = 'http://127.0.0.1:8188',
    this.duration = 5,
    this.model,
    this.tagModel = "dart-v2-sft",
    this.rating = 'general',
    this.blockTags = const ['nsfw'],
    this.target,
  });

  @override
  String toString() {
    return 'Config(address: $address, duration: $duration, model: $model, tagModel: $tagModel, rating: $rating, blockTags: $blockTags, target: $target)';
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    return _$ConfigFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ConfigToJson(this);

  Config copyWith({
    String? address,
    int? duration,
    String? model,
    String? tagModel,
    String? rating,
    List<String>? blockTags,
    Target? target,
  }) {
    return Config(
      address: address ?? this.address,
      duration: duration ?? this.duration,
      model: model ?? this.model,
      tagModel: tagModel ?? this.tagModel,
      rating: rating ?? this.rating,
      blockTags: blockTags ?? this.blockTags,
      target: target ?? this.target,
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
      duration.hashCode ^
      model.hashCode ^
      tagModel.hashCode ^
      rating.hashCode ^
      blockTags.hashCode ^
      target.hashCode;
}
