import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/user_habit.dart';

class HabitCard extends StatefulWidget {
  final UserHabit userHabit;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final bool isReordering;

  const HabitCard({
    super.key,
    required this.userHabit,
    required this.onToggle,
    this.onEdit,
    this.onArchive,
    this.isReordering = false,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isReordering) return;

    _checkController.forward().then((_) {
      _checkController.reverse();
    });
    widget.onToggle();
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final habit = widget.userHabit;
    final isDone = habit.checkedInToday;
    final habitColor = _parseColor(habit.color);

    return GestureDetector(
      onLongPress: widget.isReordering ? null : widget.onEdit,
      onTap: widget.isReordering ? null : () {},
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDone
                    ? habitColor.withOpacity(0.1)
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDone
                      ? habitColor.withOpacity(0.3)
                      : colorScheme.outline.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.isReordering ? null : () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Reorder Handle or Icon
                      if (widget.isReordering)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: habitColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              habit.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),

                      const SizedBox(width: 16),

                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title ?? habit.habit?.name ?? 'Habit',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration:
                                    isDone ? TextDecoration.lineThrough : null,
                                color: isDone
                                    ? colorScheme.onSurface.withOpacity(0.6)
                                    : colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (habit.currentStreak > 0) ...[
                                  _buildStreakBadge(
                                    habit.currentStreak,
                                    theme,
                                    colorScheme,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _formatFrequency(habit),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Checkbox Button
                      if (!widget.isReordering)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleTap,
                            borderRadius: BorderRadius.circular(24),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? habitColor
                                    : colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                                boxShadow: isDone
                                    ? [
                                        BoxShadow(
                                          color: habitColor.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: isDone
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakBadge(
    int streak,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    String emoji = '🔥';
    Color color = const Color(0xFFFF7B54); // Coral

    if (streak >= 100) {
      emoji = '👑';
      color = const Color(0xFFFFD700); // Gold
    } else if (streak >= 7) {
      emoji = '⚡';
      color = const Color(0xFF6366F1); // Indigo
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFrequency(UserHabit habit) {
    if (habit.frequency == 'daily') return 'Setiap Hari';
    if (habit.frequency == 'weekly') return 'Mingguan';
    if (habit.frequency == 'custom') {
      return '${habit.frequencyDays?.length ?? 0} hari/minggu';
    }
    return 'Harian';
  }
}
