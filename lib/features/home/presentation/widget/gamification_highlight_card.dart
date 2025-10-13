import 'package:flutter/material.dart';
import 'package:liveit_new/core/theme/app_theme.dart';
import 'package:liveit_new/features/home/presentation/models/home_ui_state.dart';

class GamificationHighlightCard extends StatelessWidget {
  final GamificationHighlight data;
  final VoidCallback? onViewProfile;

  const GamificationHighlightCard({
    super.key,
    required this.data,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppSemanticColors? semantic = Theme.of(
      context,
    ).extension<AppSemanticColors>();

    final double progress = data.pointsToNextLevel <= 0
        ? 1
        : data.totalZoePoints / (data.totalZoePoints + data.pointsToNextLevel);

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
                  Icons.local_fire_department_outlined,
                  color: scheme.tertiary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Zoe Points & Refleksi',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  data.totalZoePoints.toString(),
                  style: textTheme.displaySmall,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.currentJourneyLevel,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.pointsToNextLevel <= 0
                            ? 'Level berikutnya siap dibuka!'
                            : '${data.pointsToNextLevel} ZP lagi menuju langkah selanjutnya.',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 10,
                backgroundColor: scheme.tertiaryContainer.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.tertiary),
              ),
            ),
            if (data.latestBadge != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color:
                      semantic?.info.withOpacity(0.2) ??
                      scheme.secondaryContainer.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Badge terbaru: ${data.latestBadge!.name}',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.latestBadge!.reflection,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onViewProfile,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Lihat Profil Lengkap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
