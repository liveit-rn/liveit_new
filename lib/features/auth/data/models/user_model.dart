import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    super.name,
    required super.needsUsername,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle null needsUsername by providing a default value
    final safeJson = Map<String, dynamic>.from(json);

    // Debug logging
    print('🔍 UserModel.fromJson - Original JSON: $json');
    print(
      '🔍 UserModel.fromJson - needsUsername value: ${json['needsUsername']}',
    );
    print(
      '🔍 UserModel.fromJson - needsUsername type: ${json['needsUsername'].runtimeType}',
    );

    if (safeJson['needsUsername'] == null) {
      print('⚠️  UserModel.fromJson - needsUsername is null, setting to true');
      safeJson['needsUsername'] = true; // Default to true for new registrations
    }

    print('🔍 UserModel.fromJson - Safe JSON: $safeJson');

    return _$UserModelFromJson(safeJson);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      username: user.username,
      name: user.name,
      needsUsername: user.needsUsername,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      username: username,
      name: name,
      needsUsername: needsUsername,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
