class UserProjectsTables {
  static const userProjects = '''
    CREATE TABLE user_projects_table (
      project_id TEXT PRIMARY KEY,
      project_name TEXT,
      project_status TEXT,
      project_description TEXT,
      project_type TEXT,
      project_color TEXT,
      project_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      project_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''';
}
