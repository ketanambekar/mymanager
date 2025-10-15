class UserProfile {
  final String profileId;
  final String? name;
  final String? appVersion;
  final String? createdAt;
  final String? updatedAt;

  UserProfile({
    required this.profileId,
    this.name,
    this.appVersion,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    profileId: m['profileId'] as String,
    name: m['name'] as String?,
    appVersion: m['appVersion'] as String?,
    createdAt: m['created_at'] as String?,
    updatedAt: m['updated_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'profileId': profileId,
    'name': name,
    'appVersion': appVersion,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  UserProfile copyWith({String? name, String? appVersion, String? updatedAt}) {
    return UserProfile(
      profileId: profileId,
      name: name ?? this.name,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
