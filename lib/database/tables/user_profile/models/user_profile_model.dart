class UserProfile {
  final String profileId;
  final String? name;
  final String? appVersion;
  final int xpPoints;
  final int level;
  final String? createdAt;
  final String? updatedAt;

  UserProfile({
    required this.profileId,
    this.name,
    this.appVersion,
    this.xpPoints = 0,
    this.level = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    profileId: m['profileId'] as String,
    name: m['name'] as String?,
    appVersion: m['appVersion'] as String?,
    xpPoints: m['xp_points'] as int? ?? 0,
    level: m['level'] as int? ?? 1,
    createdAt: m['created_at'] as String?,
    updatedAt: m['updated_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'profileId': profileId,
    'name': name,
    'appVersion': appVersion,
    'xp_points': xpPoints,
    'level': level,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  UserProfile copyWith({
    String? name, 
    String? appVersion, 
    int? xpPoints, 
    int? level, 
    String? updatedAt
  }) {
    return UserProfile(
      profileId: profileId,
      name: name ?? this.name,
      appVersion: appVersion ?? this.appVersion,
      xpPoints: xpPoints ?? this.xpPoints,
      level: level ?? this.level,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
