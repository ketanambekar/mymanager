import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/database/apis/user_profile_api.dart';
import 'package:mymanager/database/apis/habit_api.dart';
import 'package:mymanager/database/tables/tasks/models/habit_model.dart';
import 'package:mymanager/services/xp_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/routes/app_routes.dart';

class DashboardXpWidget extends StatefulWidget {
  const DashboardXpWidget({super.key});

  @override
  State<DashboardXpWidget> createState() => _DashboardXpWidgetState();
}

class _DashboardXpWidgetState extends State<DashboardXpWidget> {
  int xpPoints = 0;
  int level = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadXpData();
  }

  Future<void> _loadXpData() async {
    try {
      final profileId = GetStorage().read(AppConstants.profileId);
      if (profileId != null) {
        final profile = await UserProfileApi.getProfile(profileId);
        if (profile != null && mounted) {
          setState(() {
            xpPoints = profile.xpPoints;
            level = profile.level;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox.shrink();
    }

    final progress = XpService.getProgressToNextLevel(xpPoints);
    final xpToNext = XpService.getXpToNextLevel(xpPoints);

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.habitList),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$xpToNext XP to next level',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$xpPoints XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHabitsWidget extends StatefulWidget {
  const DashboardHabitsWidget({super.key});

  @override
  State<DashboardHabitsWidget> createState() => _DashboardHabitsWidgetState();
}

class _DashboardHabitsWidgetState extends State<DashboardHabitsWidget> {
  List<Habit> todayHabits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await HabitApi.getHabits();
      if (mounted) {
        setState(() {
          // Show only habits that are due today
          todayHabits = habits.where((h) => h.isDueToday).take(3).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _toggleHabit(Habit habit) async {
    try {
      await HabitApi.completeHabit(habit.habitId);
      await XpService.awardXp(XpService.xpHabitComplete, reason: 'Habit completed');
      _loadHabits();
      
      // Show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${habit.habitName} completed! +${XpService.xpHabitComplete} XP'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF4ECDC4),
          ),
        );
      }
    } catch (e) {
      // Error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || todayHabits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s Habits',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.habitList),
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF7C4DFF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...todayHabits.map((habit) {
          Color habitColor = const Color(0xFF7C4DFF);
          if (habit.habitColor != null) {
            try {
              habitColor = Color(int.parse(habit.habitColor!.replaceFirst('#', '0xFF')));
            } catch (e) {
              // Use default
            }
          }

          final isCompleted = !habit.isDueToday;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: habitColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: isCompleted ? null : () => _toggleHabit(habit),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? habitColor : Colors.transparent,
                      border: Border.all(color: habitColor, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit.habitName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (habit.currentStreak > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: habitColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.currentStreak}',
                        style: TextStyle(
                          color: habitColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }
}
