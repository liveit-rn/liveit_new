import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/progress_ring.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _habits = [
    {
      'id': 1,
      'title': 'Doa Pagi',
      'description': '5 menit bersama Tuhan',
      'completed': true,
      'streak': 7,
    },
    {
      'id': 2,
      'title': 'Baca Alkitab',
      'description': '1 pasal per hari',
      'completed': true,
      'streak': 12,
    },
    {
      'id': 3,
      'title': 'Meditasi Firman',
      'description': 'Refleksi & jurnal',
      'completed': false,
      'streak': 3,
    },
    {
      'id': 4,
      'title': 'Doa Malam',
      'description': 'Syukur atas hari ini',
      'completed': false,
      'streak': 5,
    },
  ];

  void _toggleHabit(int id) {
    setState(() {
      final index = _habits.indexWhere((h) => h['id'] == id);
      if (index != -1) {
        _habits[index]['completed'] = !_habits[index]['completed'];
      }
    });
  }

  int get completedToday => _habits.where((h) => h['completed'] == true).length;
  int get totalHabits => _habits.length;
  int get progress =>
      totalHabits == 0 ? 0 : ((completedToday / totalHabits) * 100).round();

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
    print('🔴🔴🔴 HOMEPAGE BARU DI-RENDER! 🔴🔴🔴');
    final String dateLabel = DateFormat(
      'EEEE, d MMM',
      'id_ID',
    ).format(DateTime.now());
    final String capitalisedGreeting =
        _greetingPeriod[0].toUpperCase() + _greetingPeriod.substring(1);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(
        83,
        79,
        79,
        1,
      ), // DEBUG: warna merah terang!
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          print('📱 HomePage: Current AuthState = ${authState.runtimeType}');

          // Get user's first name from auth state
          String userFirstName = 'User'; // default fallback

          if (authState is AuthAuthenticated) {
            final user = authState.user;
            print('👤 User ID: ${user.id}');
            print('📧 User Email: ${user.email}');
            print('🏷️ User Username: ${user.username}');
            print('📝 User Name: ${user.name}');

            // Priority: name -> username -> email (before @)
            final name =
                user.name ?? user.username ?? user.email.split('@').first;
            // Get first word as first name
            userFirstName = name.split(' ').first;

            print('✅ Displaying as: $userFirstName');
          } else {
            print(
              '⚠️ NOT AUTHENTICATED - Auth state: ${authState.runtimeType}',
            );
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
                      _HabitGroupCard(
                        habits: _habits,
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
        color: Colors.red, // DEBUG: MERAH TERANG!
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
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
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
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$completed dari $total habit selesai',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
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
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Progress',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
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
              color: Colors.white.withValues(alpha: 0.28),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
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
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
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
  final List<Map<String, dynamic>> habits;
  final ValueChanged<int> onToggle;
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: completedToday == totalHabits
                      ? colorScheme.tertiary.withValues(alpha: 0.15)
                      : colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '$completedToday/$totalHabits',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: completedToday == totalHabits
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
          ...List.generate(habits.length, (index) {
            final habit = habits[index];
            final bool completed = habit['completed'] == true;
            final String title = habit['title'] as String;
            final String description = habit['description'] as String;
            final int streak = habit['streak'] as int;

            return Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  splashColor: colorScheme.primary.withValues(alpha: 0.08),
                  highlightColor: colorScheme.primary.withValues(alpha: 0.04),
                  onTap: () => onToggle(habit['id'] as int),
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
          ? Icon(Icons.check_rounded, size: 20, color: Colors.white)
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
          const Text('🔥', style: TextStyle(fontSize: 14)),
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
              color: Colors.black.withValues(alpha: 0.05),
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
