import 'package:flutter/material.dart';
import 'package:liveit_new/features/home/presentation/models/home_ui_state.dart';

class HabitEmptyStateCard extends StatelessWidget {
  final List<HabitRecommendation> recommendations;
  final VoidCallback? onAddHabit;

  const HabitEmptyStateCard({
    super.key,
    required this.recommendations,
    this.onAddHabit,
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
            Row(
              children: [
                Icon(
                  Icons.spa_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Mulai Kebiasaan',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada habit aktif. Pilih salah satu inspirasi ini untuk mulai bergerak hari ini.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...recommendations.map(
              (HabitRecommendation recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      recommendation.name,
                      style: textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      recommendation.description,
                      style: textTheme.bodyMedium,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onAddHabit,
                child: const Text('Buka Katalog Habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
