import 'package:flutter/material.dart';
import 'package:liveit_new/features/home/presentation/models/home_ui_state.dart';

class DevotionalCard extends StatelessWidget {
  final DevotionalHighlight? devotional;
  final VoidCallback? onRead;
  final VoidCallback? onCreateHabit;

  const DevotionalCard({
    super.key,
    required this.devotional,
    this.onRead,
    this.onCreateHabit,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DevotionalHighlight? data = devotional;

    if (data == null) {
      return const SizedBox.shrink();
    }

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
                  Icons.menu_book_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Text(
                  data.isForToday ? 'Renungan Hari Ini' : 'Renungan terbaru',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (data.readingDuration != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    label: Text(data.readingDuration!),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data.title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(data.snippet, style: textTheme.bodyMedium),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onRead,
                  child: const Text('Baca Renungan'),
                ),
                OutlinedButton.icon(
                  onPressed: onCreateHabit,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Buat Habit dari Renungan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
