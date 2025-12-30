class Habit {
  final String habitId;
  final String habitName;
  final String? habitDescription;
  final String frequency;
  final int targetCount;
  final int currentStreak;
  final int bestStreak;
  final String? lastCompleted;
  final String? habitColor;
  final bool enableAlerts;
  final String? alertTime;
  final String? habitCreatedAt;
  final String? habitUpdatedAt;

  Habit({
    required this.habitId,
    required this.habitName,
    this.habitDescription,
    required this.frequency,
    this.targetCount = 1,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompleted,
    this.habitColor,
    this.enableAlerts = false,
    this.alertTime,
    this.habitCreatedAt,
    this.habitUpdatedAt,
  });

  factory Habit.fromMap(Map<String, dynamic> m) => Habit(
        habitId: m['habit_id'] as String,
        habitName: m['habit_name'] as String,
        habitDescription: m['habit_description'] as String?,
        frequency: m['frequency'] as String,
        targetCount: m['target_count'] as int? ?? 1,
        currentStreak: m['current_streak'] as int? ?? 0,
        bestStreak: m['best_streak'] as int? ?? 0,
        lastCompleted: m['last_completed'] as String?,
        habitColor: m['habit_color'] as String?,
        enableAlerts: (m['enable_alerts'] as int? ?? 0) == 1,
        alertTime: m['alert_time'] as String?,
        habitCreatedAt: m['habit_created_at'] as String?,
        habitUpdatedAt: m['habit_updated_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'habit_id': habitId,
        'habit_name': habitName,
        'habit_description': habitDescription,
        'frequency': frequency,
        'target_count': targetCount,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'last_completed': lastCompleted,
        'habit_color': habitColor,
        'enable_alerts': enableAlerts ? 1 : 0,
        'alert_time': alertTime,
        'habit_created_at': habitCreatedAt,
        'habit_updated_at': habitUpdatedAt,
      };

  Habit copyWith({
    String? habitName,
    String? habitDescription,
    String? frequency,
    int? targetCount,
    int? currentStreak,
    int? bestStreak,
    String? lastCompleted,
    String? habitColor,
    bool? enableAlerts,
    String? alertTime,
    String? habitUpdatedAt,
  }) {
    return Habit(
      habitId: habitId,
      habitName: habitName ?? this.habitName,
      habitDescription: habitDescription ?? this.habitDescription,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      habitColor: habitColor ?? this.habitColor,
      enableAlerts: enableAlerts ?? this.enableAlerts,
      alertTime: alertTime ?? this.alertTime,
      habitCreatedAt: habitCreatedAt,
      habitUpdatedAt: habitUpdatedAt ?? this.habitUpdatedAt,
    );
  }

  bool get isDueToday {
    if (lastCompleted == null) return true;
    try {
      final lastDate = DateTime.parse(lastCompleted!);
      final now = DateTime.now();
      final diff = now.difference(lastDate);

      switch (frequency) {
        case 'Daily':
          return diff.inDays >= 1;
        case 'Weekly':
          return diff.inDays >= 7;
        case 'Monthly':
          return diff.inDays >= 30;
        default:
          return false;
      }
    } catch (_) {
      return true;
    }
  }
}
