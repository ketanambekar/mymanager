class TasksTables {
  static const tasks = '''
    CREATE TABLE tasks (
      task_id TEXT PRIMARY KEY,
      project_id TEXT,
      task_title TEXT NOT NULL,
      task_description TEXT,
      task_priority TEXT,
      task_urgency TEXT,
      task_importance TEXT,
      task_status TEXT DEFAULT 'Todo',
      task_frequency TEXT,
      task_frequency_value INTEGER,
      enable_alerts INTEGER DEFAULT 0,
      alert_time TEXT,
      task_start_date TEXT,
      task_due_date TEXT,
      task_completed_date TEXT,
      time_estimate INTEGER,
      time_spent INTEGER DEFAULT 0,
      task_color TEXT,
      task_order INTEGER DEFAULT 0,
      is_recurring INTEGER DEFAULT 0,
      parent_task_id TEXT,
      energy_level TEXT,
      focus_required INTEGER DEFAULT 0,
      task_created_at TEXT,
      task_updated_at TEXT,
      FOREIGN KEY (project_id) REFERENCES user_projects_table(project_id) ON DELETE CASCADE
    )
  ''';

  static const taskHistory = '''
    CREATE TABLE task_history (
      history_id TEXT PRIMARY KEY,
      task_id TEXT NOT NULL,
      action_type TEXT NOT NULL,
      action_date TEXT NOT NULL,
      time_spent INTEGER,
      notes TEXT,
      FOREIGN KEY (task_id) REFERENCES tasks(task_id) ON DELETE CASCADE
    )
  ''';

  static const habits = '''
    CREATE TABLE habits (
      habit_id TEXT PRIMARY KEY,
      habit_name TEXT NOT NULL,
      habit_description TEXT,
      frequency TEXT NOT NULL,
      target_count INTEGER DEFAULT 1,
      current_streak INTEGER DEFAULT 0,
      best_streak INTEGER DEFAULT 0,
      last_completed TEXT,
      habit_color TEXT,
      enable_alerts INTEGER DEFAULT 0,
      alert_time TEXT,
      habit_created_at TEXT,
      habit_updated_at TEXT
    )
  ''';

  static const habitLogs = '''
    CREATE TABLE habit_logs (
      log_id TEXT PRIMARY KEY,
      habit_id TEXT NOT NULL,
      completed_date TEXT NOT NULL,
      notes TEXT,
      FOREIGN KEY (habit_id) REFERENCES habits(habit_id) ON DELETE CASCADE
    )
  ''';
}
