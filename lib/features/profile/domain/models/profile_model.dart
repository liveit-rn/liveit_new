class ProfileModel {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? profileImageId;
  final String? avatarUrl;
  final String? timezone;
  final int totalZoePoints;
  final int currentLevel;
  final int? currentStreak;
  final DateTime joinedAt;

  const ProfileModel({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.profileImageId,
    this.avatarUrl,
    this.timezone,
    required this.totalZoePoints,
    required this.currentLevel,
    this.currentStreak,
    required this.joinedAt,
  });

  ProfileModel copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? profileImageId,
    String? avatarUrl,
    String? timezone,
    int? totalZoePoints,
    int? currentLevel,
    int? currentStreak,
    DateTime? joinedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageId: profileImageId ?? this.profileImageId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      timezone: timezone ?? this.timezone,
      totalZoePoints: totalZoePoints ?? this.totalZoePoints,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final totalZoePoints = json['totalZoePoints'] ?? json['totalZP'];
    final currentLevel = json['currentLevel'] ?? json['level'];
    final joinedAtRaw = json['joinedAt'] ?? json['createdAt'];

    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'user',
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? json['name'] as String?,
      profileImageId: json['profileImageId'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      timezone: json['timezone'] as String?,
      totalZoePoints: totalZoePoints is num ? totalZoePoints.toInt() : 0,
      currentLevel: currentLevel is num ? currentLevel.toInt() : 1,
      currentStreak: json['currentStreak'] is num
          ? (json['currentStreak'] as num).toInt()
          : null,
      joinedAt: joinedAtRaw is String
          ? DateTime.parse(joinedAtRaw)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'profileImageId': profileImageId,
      'avatarUrl': avatarUrl,
      'timezone': timezone,
      'totalZoePoints': totalZoePoints,
      'currentLevel': currentLevel,
      'currentStreak': currentStreak,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}
