import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'target.g.dart';

@JsonSerializable()
class Target {
  String? name;
  String? product;

  Target({this.name, this.product});

  @override
  String toString() => 'Target(name: $name, product: $product)';

  factory Target.fromJson(Map<String, dynamic> json) {
    return _$TargetFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TargetToJson(this);

  Target copyWith({String? name, String? product}) {
    return Target(name: name ?? this.name, product: product ?? this.product);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! Target) return false;
    final mapEquals = const DeepCollectionEquality().equals;
    return mapEquals(other.toJson(), toJson());
  }

  @override
  int get hashCode => name.hashCode ^ product.hashCode;
}
