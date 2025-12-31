class NotificationTables {
  static const notifications = '''
    CREATE TABLE notifications (
      notificationId TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      type TEXT NOT NULL,
      relatedId TEXT,
      isRead INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''';
}
