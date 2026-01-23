class UserTables {
  static const userProfile = '''
    CREATE TABLE user_profile (
      profileId TEXT PRIMARY KEY,
      name TEXT,
      appVersion TEXT,
      xp_points INTEGER DEFAULT 0,
      level INTEGER DEFAULT 1,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''';
}
