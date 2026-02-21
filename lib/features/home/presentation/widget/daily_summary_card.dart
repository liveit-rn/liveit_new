import 'package:flutter/material.dart';

class DailySummaryCard extends StatelessWidget {
  final String greeting;
  final int completedCount;
  final int totalCount;
  final double completionRate;
  final bool allDone;
  final VoidCallback? onAddHabit;

  const DailySummaryCard({
    super.key,
    required this.greeting,
    required this.completedCount,
    required this.totalCount,
    required this.completionRate,
    required this.allDone,
    this.onAddHabit,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final bool hasHabits = totalCount > 0;
    final String progressText = hasHabits
        ? '$completedCount dari $totalCount habit selesai'
        : 'Belum ada habit aktif hari ini';

    return Card(
      elevation: 0,
      color: scheme.primaryContainer.withOpacity(0.22),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: textTheme.headlineSmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              progressText,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 12),
            if (hasHabits)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: completionRate.clamp(0, 1),
                  backgroundColor: scheme.primary.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            if (!hasHabits) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.library_add_check_outlined),
                onPressed: onAddHabit,
                label: const Text('Tambah Habit'),
              ),
            ],
            if (allDone) ...[
              const SizedBox(height: 16),
              _BonusHighlight(scheme: scheme, textTheme: textTheme),
            ],
          ],
        ),
      ),
    );
  }
}

class _BonusHighlight extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _BonusHighlight({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: scheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All done! Bonus +20 Zoe Points',
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tetap jaga ritme ini, Pip bangga sama kamu!',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
