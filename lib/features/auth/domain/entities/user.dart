import 'package:equatable/equatable.dart';

/// User entity representing authenticated user data
class User extends Equatable {
  final String id;
  final String email;
  final String? username;
  final String? name;
  final bool needsUsername;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.name,
    required this.needsUsername,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this User with given fields replaced with new values
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? name,
    bool? needsUsername,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      needsUsername: needsUsername ?? this.needsUsername,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    name,
    needsUsername,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, name: $name, needsUsername: $needsUsername, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
