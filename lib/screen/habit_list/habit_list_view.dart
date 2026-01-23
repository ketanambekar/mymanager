import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/habit_list/habit_list_controller.dart';
import 'package:mymanager/database/tables/tasks/models/habit_model.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/routes/app_routes.dart';

class HabitListView extends StatelessWidget {
  const HabitListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HabitListController());

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        title: const Text(
          'Habits',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            onPressed: () async {
              await Get.toNamed(AppRoutes.createHabit);
              controller.loadHabits();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
          );
        }

        if (controller.habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.track_changes,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No habits yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start building good habits today!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadHabits,
          color: const Color(0xFF7C4DFF),
          backgroundColor: AppColors.darkBackground,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.habits.length,
            itemBuilder: (context, index) {
              final habit = controller.habits[index];
              return _HabitCard(
                habit: habit,
                onToggle: () => controller.toggleHabitCompletion(habit),
                onTap: () async {
                  await Get.toNamed(
                    AppRoutes.habitDetail,
                    arguments: habit,
                  );
                  controller.loadHabits();
                },
                onDelete: () => controller.deleteHabit(habit.habitId),
              );
            },
          ),
        );
      }),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  Color get _habitColor {
    if (habit.habitColor != null) {
      return Color(int.parse(habit.habitColor!.replaceFirst('#', '0xFF')));
    }
    return const Color(0xFF7C4DFF);
  }

  @override
  Widget build(BuildContext context) {
    final isDue = habit.isDueToday;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _habitColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Completion checkbox
                GestureDetector(
                  onTap: isDue ? onToggle : null,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: !isDue ? _habitColor : Colors.transparent,
                      border: Border.all(
                        color: _habitColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: !isDue
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Habit info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.habitName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 14,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            habit.frequency,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: habit.currentStreak > 0 
                                ? const Color(0xFFFF6B6B) 
                                : Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak} day streak',
                            style: TextStyle(
                              color: habit.currentStreak > 0
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white.withOpacity(0.3),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Best streak badge
                if (habit.bestStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _habitColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 14,
                          color: _habitColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.bestStreak}',
                          style: TextStyle(
                            color: _habitColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Delete button
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        backgroundColor: AppColors.cardDark,
                        title: const Text(
                          'Delete Habit?',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        content: Text(
                          'This will permanently delete "${habit.habitName}"',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.back();
                              onDelete();
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
