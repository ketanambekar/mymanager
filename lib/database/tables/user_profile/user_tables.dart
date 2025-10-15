class UserTables {
  static const userProfile = '''
    CREATE TABLE user_profile (
      profileId TEXT PRIMARY KEY,
      name TEXT,
      appVersion TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''';
}
