class Habit {
  final int? id;
  final String name;
  final String? description;
  final String colorHex;
  final String frequency;
  final String? reminderTime;
  final bool reminderEnabled;
  final bool isActive;
  final int currentStreak;
  final int bestStreak;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Habit({
    this.id,
    required this.name,
    this.description,
    required this.colorHex,
    required this.frequency,
    this.reminderTime,
    this.reminderEnabled = false,
    this.isActive = true,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorHex: map['color_hex'] as String,
      frequency: map['frequency'] as String,
      reminderTime: map['reminder_time'] as String?,
      reminderEnabled: (map['reminder_enabled'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      currentStreak: (map['current_streak'] as int?) ?? 0,
      bestStreak: (map['best_streak'] as int?) ?? 0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'color_hex': colorHex,
      'frequency': frequency,
      'reminder_time': reminderTime,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? colorHex,
    String? frequency,
    String? reminderTime,
    bool? reminderEnabled,
    bool? isActive,
    int? currentStreak,
    int? bestStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
