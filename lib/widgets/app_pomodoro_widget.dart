import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:mymanager/services/pomodoro_controller.dart';
import 'package:mymanager/theme/app_text_styles.dart';

class PomodoroWidget extends StatelessWidget {
  final String? taskId;
  
  const PomodoroWidget({super.key, this.taskId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PomodoroController());
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Text(
                controller.isWorkSession.value ? 'Focus Time' : 'Break Time',
                style: AppTheme.headline.copyWith(fontSize: 24),
              )),
          const SizedBox(height: 20),
          
          // Timer display
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.timeString,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.1),
                  )),
          
          const SizedBox(height: 20),
          
          // Session counter
          Obx(() => Text(
                'Sessions: ${controller.sessionsCompleted.value}',
                style: AppTextStyles.bodyLarge.copyWith(fontSize: 16),
              )),
          
          const SizedBox(height: 30),
          
          // Control buttons
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!controller.isRunning.value) ...[
                    _buildControlButton(
                      icon: Icons.play_arrow,
                      label: 'Start',
                      color: Colors.green,
                      onTap: () => controller.startTimer(taskId: taskId),
                    ),
                  ] else ...[
                    _buildControlButton(
                      icon: Icons.pause,
                      label: 'Pause',
                      color: Colors.orange,
                      onTap: controller.pauseTimer,
                    ),
                  ],
                  const SizedBox(width: 16),
                  _buildControlButton(
                    icon: Icons.refresh,
                    label: 'Reset',
                    color: Colors.red,
                    onTap: controller.resetTimer,
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOut);
  }
}
