import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:mymanager/theme/app_theme.dart';

class TaskSummary extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;
  final VoidCallback? onTotalTap;
  final VoidCallback? onCompletedTap;
  final VoidCallback? onPendingTap;

  const TaskSummary({
    super.key,
    required this.total,
    required this.completed,
    required this.pending,
    this.onTotalTap,
    this.onCompletedTap,
    this.onPendingTap,
  });

  Widget _buildBox({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: Container(
            margin: EdgeInsets.all(2),
            child:
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 5, bottom: 5),
                      child: Text(
                        label,
                        style: AppTheme.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(value, style: AppTheme.headlineSmall),
                    ),
                  ],
                ).asGlass(
                  tintColor: Colors.white,
                  clipBorderRadius: BorderRadius.circular(14),
                  blurX: 12,
                  blurY: 12,
                ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBox(
              context: context,
              label: 'Total Tasks',
              value: total.toString(),
              onTap: onTotalTap,
            ),
            _buildBox(
              context: context,
              label: 'Completed',
              value: completed.toString(),
              onTap: onCompletedTap,
            ),
            _buildBox(
              context: context,
              label: 'Pending',
              value: pending.toString(),
              onTap: onPendingTap,
            ),
          ],
        );
      },
    );
  }
}
