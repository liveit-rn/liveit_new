import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../habit_tracker/domain/entities/user_habit.dart';
import '../../../habit_tracker/presentation/bloc/habit_bloc.dart';
import '../../../habit_tracker/presentation/bloc/habit_event.dart';
import '../../../habit_tracker/presentation/bloc/habit_state.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/progress_ring.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _toggleHabit(String userHabitId, bool isCompleted) {
    final bloc = context.read<HabitBloc>();
    final now = DateTime.now();
    if (isCompleted) {
      bloc.add(HabitUndoCheckInRequested(userHabitId: userHabitId, date: now));
    } else {
      bloc.add(HabitCheckInRequested(userHabitId: userHabitId, date: now));
    }
  }

  String get _greetingPeriod {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'pagi';
    }
    if (hour < 17) {
      return 'siang';
    }
    return 'malam';
  }

  @override
  Widget build(BuildContext context) {
    final String dateLabel = DateFormat(
      'EEEE, d MMM',
      'id_ID',
    ).format(DateTime.now());
    final String capitalisedGreeting =
        _greetingPeriod[0].toUpperCase() + _greetingPeriod.substring(1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.router.push(const AddHabitRoute());
          if (result == true && context.mounted) {
            context.read<HabitBloc>().add(HabitStarted());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          // Get user's first name from auth state
          String userFirstName = 'User'; // default fallback

          if (authState is AuthAuthenticated) {
            final user = authState.user;
            // Priority: name -> username -> email (before @)
            final name =
                user.name ?? user.username ?? user.email.split('@').first;
            // Get first word as first name
            userFirstName = name.split(' ').first;
          }

          return BlocBuilder<HabitBloc, HabitState>(
            builder: (context, habitState) {
              int completedToday = 0;
              int totalHabits = 0;
              int progress = 0;
              List<UserHabit> habits = [];
              bool isLoading = habitState is HabitLoading;
              String? errorMessage;

              if (habitState is HabitLoaded) {
                habits = habitState.habits;
                completedToday = habitState.completedToday;
                totalHabits = habitState.totalHabits;
                progress = habitState.progress;
              } else if (habitState is HabitError) {
                errorMessage = habitState.message;
              }

              return SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _HeaderCard(
                            greeting: capitalisedGreeting,
                            name: userFirstName,
                            dateLabel: dateLabel,
                            completed: completedToday,
                            total: totalHabits,
                            progress: progress,
                          ),
                          const SizedBox(height: 24),
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                'Error: $errorMessage',
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                          if (isLoading && habits.isEmpty)
                            const Center(child: CircularProgressIndicator())
                          else
                            _HabitGroupCard(
                              habits: habits,
                              onToggle: _toggleHabit,
                              completedToday: completedToday,
                              totalHabits: totalHabits,
                            ),
                          const SizedBox(height: 24),
                          _CommunityCard(),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String greeting;
  final String name;
  final String dateLabel;
  final int completed;
  final int total;
  final int progress;

  const _HeaderCard({
    required this.greeting,
    required this.name,
    required this.dateLabel,
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat $greeting, $name',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$completed dari $total habit selesai',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                progress: progress.clamp(0, 100),
                size: 96,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$progress%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Progress',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: _HeaderStatChip(
                    icon: Icons.bolt,
                    label: 'Zoe Points',
                    value: '480',
                    subtitle: '+20 hari ini',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _HeaderStatChip(
                    icon: Icons.emoji_events,
                    label: 'Level',
                    value: '3',
                    subtitle: '70 XP lagi',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _HeaderStatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.onPrimary, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.88),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _HabitGroupCard extends StatelessWidget {
  final List<UserHabit> habits;
  final void Function(String, bool) onToggle;
  final int completedToday;
  final int totalHabits;

  const _HabitGroupCard({
    required this.habits,
    required this.onToggle,
    required this.completedToday,
    required this.totalHabits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Habit Harian',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bangun konsistensi imanmu hari ini.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: completedToday == totalHabits && totalHabits > 0
                      ? colorScheme.tertiary.withValues(alpha: 0.15)
                      : colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '$completedToday/$totalHabits',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: completedToday == totalHabits && totalHabits > 0
                        ? colorScheme.tertiary
                        : colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (habits.isEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 20),
               child: Center(
                 child: Text(
                   'Belum ada habit. Tambahkan sekarang!',
                   style: theme.textTheme.bodyMedium?.copyWith(
                     color: colorScheme.onSurfaceVariant,
                   ),
                 ),
               ),
             )
          else
          ...List.generate(habits.length, (index) {
            final habit = habits[index];
            final bool completed = habit.checkedInToday;
            final String title = habit.title ?? habit.habit?.name ?? 'Untitled';
            final String description = habit.notes ?? habit.habit?.description ?? '';
            final int streak = habit.currentStreak;

            return Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  splashColor: colorScheme.primary.withValues(alpha: 0.08),
                  highlightColor: colorScheme.primary.withValues(alpha: 0.04),
                  onTap: () => onToggle(habit.id, completed),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        _HabitCheckbox(completed: completed),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: completed
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    decoration: completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _HabitTrailingBadge(
                          completed: completed,
                          streak: streak,
                        ),
                      ],
                    ),
                  ),
                ),
                if (index != habits.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 60),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _HabitCheckbox extends StatelessWidget {
  final bool completed;

  const _HabitCheckbox({required this.completed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? colorScheme.tertiary : Colors.transparent,
        border: Border.all(
          color: completed
              ? colorScheme.tertiary
              : colorScheme.outline.withValues(alpha: 0.35),
          width: 2.5,
        ),
      ),
      child: completed
          ? Icon(Icons.check_rounded, size: 20, color: colorScheme.onTertiary)
          : null,
    );
  }
}

class _HabitTrailingBadge extends StatelessWidget {
  final bool completed;
  final int streak;

  const _HabitTrailingBadge({required this.completed, required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Selesai',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: theme.textTheme.labelMedium),
          const SizedBox(width: 4),
          Text(
            '$streak hari',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Komunitas segera tersedia.')),
          );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.people_alt_rounded,
                color: colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Komunitas',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Terhubung dengan sesama untuk saling mendukung perjalanan iman.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
