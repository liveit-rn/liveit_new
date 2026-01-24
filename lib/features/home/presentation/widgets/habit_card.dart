import 'package:flutter/material.dart';
import 'package:liveit_new/features/habit_tracker/domain/entities/user_habit.dart';

class HabitCard extends StatelessWidget {
  final UserHabit userHabit;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  const HabitCard({
    super.key,
    required this.userHabit,
    required this.onToggle,
    this.onEdit,
    this.onArchive,
  });

  String get _title =>
      userHabit.title ?? userHabit.habit?.name ?? 'Unknown Habit';

  String get _description =>
      userHabit.notes ?? userHabit.habit?.description ?? '';

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _formatRepeatPeriod(String period) {
    switch (period) {
      case '1_day':
        return '1 Hari';
      case '1_week':
        return '1 Minggu';
      case '1_month':
        return '1 Bulan';
      case '1_year':
        return '1 Tahun';
      case 'forever':
      default:
        return 'Selamanya';
    }
  }

  String _formatFrequency(String frequency, List<int>? days) {
    switch (frequency) {
      case 'daily':
        return 'Harian';
      case 'weekly':
        return 'Mingguan';
      case 'custom':
        if (days == null || days.isEmpty) return 'Custom';
        const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
        return days.map((d) => dayNames[d]).join(', ');
      default:
        return frequency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final habitColor = _parseColor(userHabit.color);
    final completed = userHabit.checkedInToday;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: habitColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: habitColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      userHabit.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: completed
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (_description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? habitColor : Colors.transparent,
                    border: Border.all(
                      color: completed ? habitColor : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: completed
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBadge(
                  context,
                  _formatRepeatPeriod(userHabit.repeatPeriod),
                  habitColor,
                ),
                const SizedBox(width: 8),
                _buildBadge(
                  context,
                  _formatFrequency(
                    userHabit.frequency,
                    userHabit.frequencyDays,
                  ),
                  colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStreakBadge(
                  context,
                  '🔥',
                  userHabit.currentStreak,
                  'Streak',
                ),
                const SizedBox(width: 16),
                _buildStreakBadge(
                  context,
                  '🏆',
                  userHabit.longestStreak,
                  'Best',
                ),
                const SizedBox(width: 16),
                _buildStreakBadge(
                  context,
                  '✓',
                  userHabit.totalCompletions,
                  'Total',
                ),
              ],
            ),
            if (onEdit != null || onArchive != null) ...[
              const SizedBox(height: 12),
              Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  if (onArchive != null)
                    TextButton.icon(
                      onPressed: onArchive,
                      icon: const Icon(Icons.archive_outlined, size: 18),
                      label: const Text('Arsip'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStreakBadge(
    BuildContext context,
    String emoji,
    int value,
    String label,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
