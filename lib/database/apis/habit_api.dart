import 'package:get_storage/get_storage.dart';
import 'package:mymanager/database/tables/tasks/models/habit_model.dart';

class HabitApi {
  static final GetStorage _storage = GetStorage();
  static const _habitsKey = 'habits_list';
  static const _logsKey = 'habit_logs';

  static List<Map<String, dynamic>> _habitMaps() {
    final raw = _storage.read<List>(_habitsKey) ?? const [];
    return raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  static Future<void> _saveHabits(List<Map<String, dynamic>> habits) async {
    await _storage.write(_habitsKey, habits);
  }

  static Future<void> createHabit(Habit habit) async {
    final habits = _habitMaps();
    habits.add(habit.toMap());
    await _saveHabits(habits);
  }

  static Future<List<Habit>> getHabits() async {
    return _habitMaps().map(Habit.fromMap).toList();
  }

  static Future<Habit?> getHabitById(String habitId) async {
    final habits = await getHabits();
    final found = habits.where((h) => h.habitId == habitId);
    return found.isEmpty ? null : found.first;
  }

  static Future<int> updateHabit(String habitId, Habit updated) async {
    final habits = _habitMaps();
    final index = habits.indexWhere((h) => h['habit_id'] == habitId);
    if (index == -1) return 0;
    habits[index] = updated.toMap();
    await _saveHabits(habits);
    return 1;
  }

  static Future<void> completeHabit(String habitId, {String? notes}) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return;

    final streak = habit.currentStreak + 1;
    final best = streak > habit.bestStreak ? streak : habit.bestStreak;

    await updateHabit(
      habitId,
      habit.copyWith(
        currentStreak: streak,
        bestStreak: best,
        lastCompleted: DateTime.now().toIso8601String(),
        habitUpdatedAt: DateTime.now().toIso8601String(),
      ),
    );

    final logs = (_storage.read<List>(_logsKey) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    logs.add({
      'habit_id': habitId,
      'completed_date': DateTime.now().toIso8601String(),
      'notes': notes
    });
    await _storage.write(_logsKey, logs);
  }

  static Future<int> deleteHabit(String habitId) async {
    final habits = _habitMaps();
    habits.removeWhere((h) => h['habit_id'] == habitId);
    await _saveHabits(habits);
    return 1;
  }

  static Future<List<Map<String, dynamic>>> getHabitLogs(String habitId, {int days = 30}) async {
    final logs = (_storage.read<List>(_logsKey) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return logs.where((log) {
      final sameHabit = log['habit_id'] == habitId;
      final date = DateTime.tryParse(log['completed_date']?.toString() ?? '');
      return sameHabit && date != null && date.isAfter(cutoff);
    }).toList();
  }
}
