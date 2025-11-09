class ProfileModel {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final int totalZoePoints;
  final int currentLevel;
  final DateTime joinedAt;

  const ProfileModel({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.totalZoePoints,
    required this.currentLevel,
    required this.joinedAt,
  });

  ProfileModel copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    int? totalZoePoints,
    int? currentLevel,
    DateTime? joinedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalZoePoints: totalZoePoints ?? this.totalZoePoints,
      currentLevel: currentLevel ?? this.currentLevel,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      totalZoePoints: json['totalZoePoints'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'totalZoePoints': totalZoePoints,
      'currentLevel': currentLevel,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}
