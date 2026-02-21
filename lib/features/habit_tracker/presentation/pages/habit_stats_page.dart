import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/user_habit.dart';

@RoutePage()
class HabitStatsPage extends StatelessWidget {
  final UserHabit userHabit;

  const HabitStatsPage({super.key, required this.userHabit});

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final habitColor = _parseColor(userHabit.color);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(userHabit.title ?? 'Statistik'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    habitColor.withOpacity(0.8),
                    habitColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: habitColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        userHabit.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userHabit.title ?? 'Habit',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatFrequency(userHabit),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Streak Saat Ini',
                    '${userHabit.currentStreak}',
                    '🔥',
                    const Color(0xFFFF7B54), // Coral
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Rekor Terbaik',
                    '${userHabit.longestStreak}',
                    '👑',
                    const Color(0xFFFFD700), // Gold
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              'Total Penyelesaian',
              '${userHabit.totalCompletions} Kali',
              '✅',
              const Color(0xFF4CAF50), // Green
              isFullWidth: true,
            ),
            const SizedBox(height: 32),

            // 3. Calendar Heatmap (Mock Data for now)
            Text(
              'Riwayat Check-in',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCalendar(context, habitColor),

            const SizedBox(height: 32),

            // 4. Next Milestone
            Text(
              'Milestone Berikutnya',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNextMilestone(context, userHabit.currentStreak),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String emoji,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: isFullWidth
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
            ],
          ),
          if (isFullWidth)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            )
          else ...[
            const Spacer(),
            Text(emoji, style: const TextStyle(fontSize: 24)),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, Color habitColor) {
    // NOTE: This uses dummy data for visualization because
    // the UserHabit model doesn't store full history yet.
    // In real implementation, we'd fetch check-in history from API.

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOffset = DateTime(now.year, now.month, 1).weekday - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Month Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: () {}, // Disabled for future
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Days Header (S S R K J S M)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg']
                .map((day) => SizedBox(
                      width: 32,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) return const SizedBox();

              final day = index - firstDayOffset + 1;

              // MOCK LOGIC: Check-in on even days + today
              final isToday = day == now.day;
              final isChecked = (day % 2 == 0 && day < now.day) ||
                  (isToday && userHabit.checkedInToday);

              return Container(
                decoration: BoxDecoration(
                  color: isChecked ? habitColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !isChecked
                      ? Border.all(color: habitColor, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isChecked
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isChecked || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNextMilestone(BuildContext context, int currentStreak) {
    int nextTarget = 7;
    if (currentStreak >= 7) nextTarget = 30;
    if (currentStreak >= 30) nextTarget = 100;
    if (currentStreak >= 100) nextTarget = 365;

    final progress = currentStreak / nextTarget;
    final remaining = nextTarget - currentStreak;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2F5D62).withOpacity(0.1),
            const Color(0xFF2F5D62).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menuju $nextTarget Hari',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F5D62),
                    ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F5D62),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white,
            color: const Color(0xFF2F5D62), // Deep Teal
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          Text(
            remaining > 0
                ? '$remaining hari lagi untuk mencapai milestone!'
                : 'Milestone tercapai! Lanjutkan ke target berikutnya.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF2F5D62).withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }

  String _formatFrequency(UserHabit habit) {
    if (habit.frequency == 'daily') return 'Setiap Hari';
    if (habit.frequency == 'weekly') return 'Mingguan';
    return 'Custom';
  }
}
