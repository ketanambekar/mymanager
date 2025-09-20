// lib/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:glass/glass.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A simple, reusable TaskCard with glass UI, slidable actions and an entry animation.
/// - Uses `glass` (asGlass) for the frosted glass background
/// - Uses `flutter_slidable` for swipe actions
/// - Uses `flutter_animate` for a short entrance animation
class TaskCard extends StatelessWidget {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime? time; // optional alert / due time to show
  final bool done;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleDone;

  const TaskCard({
    Key? key,
    required this.id,
    required this.title,
    this.subtitle,
    this.time,
    this.done = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleDone,
  }) : super(key: key);

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    // simple hh:mm AM/PM
    final hour = dt.hour == 0 || dt.hour == 12 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Slidable(
        key: ValueKey(id),
        // swipe left to reveal actions
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit?.call(),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => onDelete?.call(),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: _buildGlassCard(context).animate().fadeIn(duration: 250.ms).slideY(end: 0, begin: 0.02, duration: 300.ms),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700);
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70);
    final timeStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60, fontSize: 12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            // Outer container only provides size and shape; inner content is glassed
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Leading checkbox / status
                GestureDetector(
                  onTap: () => onToggleDone?.call(!done),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.2),
                      color: done ? Colors.greenAccent.withOpacity(0.18) : Colors.transparent,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: done
                            ? Icon(Icons.check, key: const ValueKey('done'), size: 20, color: Colors.greenAccent.shade400)
                            : Icon(Icons.circle_outlined, key: const ValueKey('undone'), size: 20, color: Colors.white70),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // The glass body: title / subtitle / time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AsGlass wraps the content to produce blur + tint.
                      // We wrap a sized container so blur has area to work with.
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(subtitle!, style: subtitleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        )
                      ),
                    ],
                  ),
                ),

                // time / menu area
                if (time != null) ...[
                  const SizedBox(width: 8),
                  Text(_formatTime(time), style: timeStyle),
                ],

                const SizedBox(width: 8),
                // small chevron to indicate more
                Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
            decoration: BoxDecoration(
              // a very subtle translucent base so the blur is visible
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 10, offset: const Offset(0, 6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
