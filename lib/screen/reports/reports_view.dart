import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/reports/reports_controller.dart';
import 'package:intl/intl.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportsController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadReportData,
              color: const Color(0xFF7C4DFF),
              backgroundColor: const Color(0xFF1A1A2E),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reports & Analytics',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Overall Statistics Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C4DFF).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Overall Progress',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${controller.completionRate.value.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Total Tasks',
                                  controller.totalTasks.value.toString(),
                                  Icons.task_outlined,
                                  Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatItem(
                                  'Projects',
                                  controller.allProjects.length.toString(),
                                  Icons.folder_outlined,
                                  Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Task Status Section
                    const Text(
                      'Task Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusCard(
                            'Completed',
                            controller.completedTasks.value,
                            Icons.check_circle_outline,
                            const Color(0xFF4ECDC4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatusCard(
                            'In Progress',
                            controller.inProgressTasks.value,
                            Icons.pending_outlined,
                            const Color(0xFFFFBE0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusCard(
                            'To Do',
                            controller.todoTasks.value,
                            Icons.radio_button_unchecked,
                            const Color(0xFF7C4DFF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatusCard(
                            'Overdue',
                            controller.overdueTasks.value,
                            Icons.warning_outlined,
                            const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Priority Distribution Section
                    const Text(
                      'Priority Distribution',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPriorityCard(
                      'Urgent and Important',
                      controller.urgentImportant.value,
                      Icons.flag,
                      const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(height: 8),
                    _buildPriorityCard(
                      'Urgent but Not Important',
                      controller.urgentNotImportant.value,
                      Icons.flag_outlined,
                      const Color(0xFFFFBE0B),
                    ),
                    const SizedBox(height: 8),
                    _buildPriorityCard(
                      'Not Urgent but Important',
                      controller.notUrgentImportant.value,
                      Icons.flag_outlined,
                      const Color(0xFF5B8DEE),
                    ),
                    const SizedBox(height: 8),
                    _buildPriorityCard(
                      'Not Urgent Not Important',
                      controller.notUrgentNotImportant.value,
                      Icons.outlined_flag,
                      const Color(0xFF4ECDC4),
                    ),

                    const SizedBox(height: 24),

                    // Task Frequency Section
                    const Text(
                      'Task Frequency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFrequencyCard(
                            'Once',
                            controller.onceTasks.value,
                            Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFrequencyCard(
                            'Daily',
                            controller.dailyTasks.value,
                            Icons.today,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFrequencyCard(
                            'Weekly',
                            controller.weeklyTasks.value,
                            Icons.date_range,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFrequencyCard(
                            'Monthly',
                            controller.monthlyTasks.value,
                            Icons.calendar_month,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Time-based Statistics Section
                    const Text(
                      'Time Statistics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeStatCard(
                      'Tasks Due Today',
                      controller.todayTasks.value,
                      Icons.today_outlined,
                      const Color(0xFF7C4DFF),
                    ),
                    const SizedBox(height: 8),
                    _buildTimeStatCard(
                      'Tasks This Week',
                      controller.thisWeekTasks.value,
                      Icons.date_range_outlined,
                      const Color(0xFF5B8DEE),
                    ),
                    const SizedBox(height: 8),
                    _buildTimeStatCard(
                      'Tasks This Month',
                      controller.thisMonthTasks.value,
                      Icons.calendar_month_outlined,
                      const Color(0xFF4ECDC4),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityCard(String label, int count, IconData icon, Color color) {
    final total = Get.find<ReportsController>().totalTasks.value;
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count task${count != 1 ? 's' : ''} ($percentage%)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyCard(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7C4DFF), size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
