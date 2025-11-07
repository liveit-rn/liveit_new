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
    final safeJson = Map<String, dynamic>.from(json);

    // Normalisasi key yang tidak konsisten dari backend:
    // Username: 'username' | 'user_name' | 'userName'
    dynamic uname = safeJson['username'];
    if (uname == null) {
      if (safeJson.containsKey('user_name')) {
        uname = safeJson['user_name'];
      } else if (safeJson.containsKey('userName')) {
        uname = safeJson['userName'];
      }
    }
    if (uname != null) {
      safeJson['username'] = uname is String ? uname : uname.toString();
    }

    // needsUsername: 'needsUsername' | 'needs_username' | 'needsUserName'
    dynamic needsRaw = safeJson['needsUsername'];
    if (needsRaw == null) {
      if (safeJson.containsKey('needs_username')) {
        needsRaw = safeJson['needs_username'];
      } else if (safeJson.containsKey('needsUserName')) {
        needsRaw = safeJson['needsUserName'];
      }
    }

    // Tanggal: 'createdAt' | 'created_at', 'updatedAt' | 'updated_at'
    final createdRaw = safeJson['createdAt'] ?? safeJson['created_at'];
    if (createdRaw != null) {
      safeJson['createdAt'] =
          createdRaw is String ? createdRaw : createdRaw.toString();
    }
    final updatedRaw = safeJson['updatedAt'] ?? safeJson['updated_at'];
    if (updatedRaw != null) {
      safeJson['updatedAt'] =
          updatedRaw is String ? updatedRaw : updatedRaw.toString();
    }

    // Normalisasi needsUsername menjadi boolean yang konsisten.
    // Jika tidak diberikan atau tidak bisa diparse, turunkan dari keberadaan username:
    // - true jika username null/empty
    // - false jika username sudah ada
    bool computedNeedsUsername;
    if (needsRaw is bool) {
      computedNeedsUsername = needsRaw;
    } else if (needsRaw == null) {
      final u = safeJson['username'];
      computedNeedsUsername =
          u == null || (u is String && u.trim().isEmpty);
    } else if (needsRaw is String) {
      final lower = needsRaw.toLowerCase();
      if (lower == 'true' || lower == '1') {
        computedNeedsUsername = true;
      } else if (lower == 'false' || lower == '0') {
        computedNeedsUsername = false;
      } else {
        final u = safeJson['username'];
        computedNeedsUsername =
            u == null || (u is String && u.trim().isEmpty);
      }
    } else if (needsRaw is num) {
      computedNeedsUsername = needsRaw != 0;
    } else {
      final u = safeJson['username'];
      computedNeedsUsername =
          u == null || (u is String && u.trim().isEmpty);
    }

    safeJson['needsUsername'] = computedNeedsUsername;

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
