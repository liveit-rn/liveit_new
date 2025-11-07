import 'package:json_annotation/json_annotation.dart';

part 'username_check_model.g.dart';

@JsonSerializable()
class UsernameCheckModel {
  final bool available;

  const UsernameCheckModel({required this.available});

  factory UsernameCheckModel.fromJson(Map<String, dynamic> json) =>
      _$UsernameCheckModelFromJson(json);

  Map<String, dynamic> toJson() => _$UsernameCheckModelToJson(this);
}
