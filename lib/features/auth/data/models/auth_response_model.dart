import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_response.dart';
import 'user_model.dart';

part 'auth_response_model.g.dart';

@JsonSerializable()
class AuthResponseModel {
  final UserModel user;

  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  const AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.expiresIn,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);

  AuthResponse toEntity() {
    return AuthResponse(
      user: user.toEntity(),
      accessToken: accessToken,
      expiresIn: expiresIn,
    );
  }
}
