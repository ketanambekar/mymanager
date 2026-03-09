import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/theme/app_colors.dart';
import 'package:mymanager/screen/calander/calender_controller.dart';
import 'package:mymanager/widgets/app_side_menu.dart';

class CalenderView extends StatelessWidget {
  const CalenderView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CalenderController());
    final isDesktop = MediaQuery.sizeOf(context).width >= 980;

    final calendarContent = SingleChildScrollView(
      child: Column(
        children: [
          if (!isDesktop)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _MonthlyCalendar(controller: controller),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() {
              final tasks = controller.tasksForSelectedDay;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tasks for Selected Day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No tasks for this day',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                      ),
                    )
                  else
                    ...tasks.map((task) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowDark,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.taskTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (task.taskDescription != null && task.taskDescription!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              task.taskDescription!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    )),
                ],
              );
            }),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.cardDark,
              elevation: 0,
              title: const Text(
                'Calendar',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      drawer: isDesktop ? null : const Drawer(child: AppSideMenu(activeRoute: AppRoutes.calender)),
      body: isDesktop
          ? Row(
              children: [
                const AppSideMenu(activeRoute: AppRoutes.calender),
                Expanded(child: calendarContent),
              ],
            )
          : calendarContent,
    );
  }
}

class _MonthlyCalendar extends StatelessWidget {
  final CalenderController controller;
  
  const _MonthlyCalendar({required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final focusedDay = controller.focusedDay.value;
      final selectedDay = controller.selectedDay.value;
      final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
      final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
      final daysInMonth = lastDayOfMonth.day;
      final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
      
      return Column(
        children: [
          // Month/Year header with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                onPressed: () {
                  final newDate = DateTime(focusedDay.year, focusedDay.month - 1, 1);
                  controller.focusedDay.value = newDate;
                  // Keep selected day in view or reset to first day if not in new month
                  if (controller.selectedDay.value.month != newDate.month) {
                    controller.selectDay(newDate, newDate);
                  }
                },
              ),
              GestureDetector(
                onTap: () {
                  // Reset to today
                  final today = DateTime.now();
                  controller.focusedDay.value = DateTime(today.year, today.month, 1);
                  controller.selectDay(today, today);
                },
                child: Text(
                  '${_getMonthName(focusedDay.month)} ${focusedDay.year}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                onPressed: () {
                  final newDate = DateTime(focusedDay.year, focusedDay.month + 1, 1);
                  controller.focusedDay.value = newDate;
                  // Keep selected day in view or reset to first day if not in new month
                  if (controller.selectedDay.value.month != newDate.month) {
                    controller.selectDay(newDate, newDate);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          
          // Calendar grid
          ...List.generate((daysInMonth + startWeekday) ~/ 7 + 1, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - startWeekday + 1;
                  
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 40, height: 48);
                  }
                  
                  final date = DateTime(focusedDay.year, focusedDay.month, dayNumber);
                  final isSelected = date.day == selectedDay.day && 
                                     date.month == selectedDay.month && 
                                     date.year == selectedDay.year;
                  final isToday = date.day == DateTime.now().day && 
                                  date.month == DateTime.now().month && 
                                  date.year == DateTime.now().year;
                  final hasTasks = controller.hasTasksOnDate(date);
                  final hasHabits = controller.hasHabitCompletionOnDate(date);
                  
                  return GestureDetector(
                    onTap: () => controller.selectDay(date, date),
                    child: Container(
                      width: 40,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C4DFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected
                            ? Border.all(color: const Color(0xFF7C4DFF), width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: isSelected || isToday
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasTasks)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF5B8DEE),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasHabits)
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF4ECDC4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: const Color(0xFF5B8DEE), label: 'Tasks'),
              const SizedBox(width: 16),
              _LegendItem(color: const Color(0xFF4ECDC4), label: 'Habits'),
            ],
          ),
        ],
      );
    });
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  
  const _LegendItem({required this.color, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
