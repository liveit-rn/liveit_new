import 'package:flutter/material.dart';
import 'package:liveit_new/features/home/presentation/models/home_ui_state.dart';

class HabitGroupsSection extends StatelessWidget {
  final List<HabitItem> pendingHabits;
  final List<HabitItem> completedHabits;
  final ValueChanged<HabitItem> onCheckIn;
  final ValueChanged<HabitItem> onUndo;

  const HabitGroupsSection({
    super.key,
    required this.pendingHabits,
    required this.completedHabits,
    required this.onCheckIn,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Harian',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (pendingHabits.isNotEmpty)
              _HabitList(
                title: 'Belum Selesai',
                habits: pendingHabits,
                accentColor: Theme.of(context).colorScheme.primary,
                onTap: onCheckIn,
                actionLabel: 'Selesai',
                checkboxActiveColor: Theme.of(context).colorScheme.primary,
              )
            else
              _EmptyGroup(
                title: 'Semua habit sudah di-check-in untuk hari ini.',
              ),
            if (completedHabits.isNotEmpty) ...[
              const SizedBox(height: 20),
              ExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                title: Text('Selesai Hari Ini', style: textTheme.titleMedium),
                childrenPadding: EdgeInsets.zero,
                children: [
                  _HabitList(
                    title: null,
                    habits: completedHabits,
                    accentColor: Theme.of(context).colorScheme.secondary,
                    onTap: onUndo,
                    actionLabel: 'Undo',
                    checkboxActiveColor: Theme.of(
                      context,
                    ).colorScheme.secondary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HabitList extends StatelessWidget {
  final String? title;
  final List<HabitItem> habits;
  final Color accentColor;
  final ValueChanged<HabitItem> onTap;
  final String actionLabel;
  final Color checkboxActiveColor;

  const _HabitList({
    this.title,
    required this.habits,
    required this.accentColor,
    required this.onTap,
    required this.actionLabel,
    required this.checkboxActiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: textTheme.titleMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final HabitItem habit = habits[index];
            final bool isCompleted = habit.checkedInToday;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Checkbox(
                  value: isCompleted,
                  onChanged: (_) => onTap(habit),
                  activeColor: checkboxActiveColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                title: Text(
                  habit.name,
                  style: textTheme.titleMedium?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: habit.note != null
                    ? Text(habit.note!, style: textTheme.bodyMedium)
                    : null,
                trailing: TextButton(
                  onPressed: () => onTap(habit),
                  child: Text(actionLabel),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: habits.length,
        ),
      ],
    );
  }
}

class _EmptyGroup extends StatelessWidget {
  final String title;

  const _EmptyGroup({required this.title});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
