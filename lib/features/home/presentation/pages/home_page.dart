import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../habit_tracker/presentation/bloc/habit_bloc.dart';
import '../../../habit_tracker/presentation/bloc/habit_event.dart';
import '../../../habit_tracker/presentation/bloc/habit_state.dart';

/// HomePage - Landing page utama LiveIt dengan glassmorphism design.
/// Menampilkan fitur utama aplikasi dengan aesthetic iOS 2026 modern.
@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Load habit data
    context.read<HabitBloc>().add(HabitStarted());

    // Trigger animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    if (hour < 20) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String get _todayDate {
    return DateFormat('EEEE, d MMMM', 'id_ID').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = _extractUserName(authState);

        return BlocBuilder<HabitBloc, HabitState>(
          builder: (context, habitState) {
            final habitData = _extractHabitData(habitState);

            return _HomePageContent(
              greeting: _greeting,
              userName: userName,
              date: _todayDate,
              habitData: habitData,
              controller: _animationController,
            );
          },
        );
      },
    );
  }

  String _extractUserName(AuthState state) {
    if (state is AuthAuthenticated) {
      final user = state.user;
      final name = user.name ?? user.username ?? user.email.split('@').first;
      return name.split(' ').first;
    }
    return 'Sahabat';
  }

  ({int completed, int total, int progress, bool isLoading}) _extractHabitData(
    HabitState state,
  ) {
    if (state is HabitLoaded) {
      return (
        completed: state.completedToday,
        total: state.totalHabits,
        progress: state.progress,
        isLoading: false,
      );
    }
    return (
      completed: 0,
      total: 0,
      progress: 0,
      isLoading: state is HabitLoading
    );
  }
}

class _HomePageContent extends StatelessWidget {
  final String greeting;
  final String userName;
  final String date;
  final ({int completed, int total, int progress, bool isLoading}) habitData;
  final AnimationController controller;

  const _HomePageContent({
    required this.greeting,
    required this.userName,
    required this.date,
    required this.habitData,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.06),
              colorScheme.surface,
              colorScheme.tertiary.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            slivers: [
              // Hero Section dengan greeting
              _HeroSection(
                greeting: greeting,
                userName: userName,
                date: date,
                controller: controller,
              ),

              // Progress Overview Card
              _ProgressOverview(
                completed: habitData.completed,
                total: habitData.total,
                progress: habitData.progress,
                isLoading: habitData.isLoading,
                controller: controller,
              ),

              // Fitur Utama Section
              _MainFeaturesSection(controller: controller),

              // Quick Stats Grid
              _QuickStatsGrid(controller: controller),

              // Community Preview
              _CommunityPreview(controller: controller),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 124),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String greeting;
  final String userName;
  final String date;
  final AnimationController controller;

  const _HeroSection({
    required this.greeting,
    required this.userName,
    required this.date,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.12),
                      colorScheme.primary.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Greeting
              Text(
                '$greeting,',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              // Tagline
              Text(
                'Bangun kebiasaan rohani, hidupi iman setiap hari.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  final int completed;
  final int total;
  final int progress;
  final bool isLoading;
  final AnimationController controller;

  const _ProgressOverview({
    required this.completed,
    required this.total,
    required this.progress,
    required this.isLoading,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () => context.router.push(const HabitTrackerRoute()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.85),
                    colorScheme.primary.withValues(alpha: 0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress Hari Ini',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  colorScheme.onPrimary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isLoading)
                            Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colorScheme.onPrimary
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            )
                          else
                            Text(
                              '$completed dari $total habit selesai',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimary
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                        ],
                      ),

                      // Progress indicator
                      if (isLoading)
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary.withValues(alpha: 0.2),
                            border: Border.all(
                              color:
                                  colorScheme.onPrimary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$progress%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: isLoading ? 0 : progress / 100,
                      backgroundColor:
                          colorScheme.onPrimary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                      minHeight: 8,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CTA Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status text
                      Expanded(
                        child: Text(
                          total == 0
                              ? 'Belum ada habit'
                              : completed == total
                                  ? 'Semua selesai!'
                                  : '${total - completed} habit tersisa',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                colorScheme.onPrimary.withValues(alpha: 0.85),
                          ),
                        ),
                      ),

                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tambah Habit button
                          GestureDetector(
                            onTap: () async {
                              final result = await context.router
                                  .push(const AddHabitRoute());
                              if (result == true && context.mounted) {
                                context.read<HabitBloc>().add(HabitStarted());
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.onPrimary
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colorScheme.onPrimary
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tambah',
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Lihat Detail button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.onPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: colorScheme.onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainFeaturesSection extends StatelessWidget {
  final AnimationController controller;

  const _MainFeaturesSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final features = [
      _FeatureItem(
        icon: Icons.check_circle_outline_rounded,
        title: 'Habit Tracker',
        subtitle: 'Catat kebiasaan rohanimu',
        color: colorScheme.primary,
        route: const HabitTrackerRoute(),
      ),
      _FeatureItem(
        icon: Icons.emoji_events_outlined,
        title: 'Zoe Points',
        subtitle: 'Kumpulkan poin iman',
        color: colorScheme.tertiary,
        route: null, // Coming soon
      ),
      _FeatureItem(
        icon: Icons.people_outline_rounded,
        title: 'Komunitas',
        subtitle: 'Terhubung dengan sesama',
        color: const Color(0xFF8B5CF6),
        route: null, // Coming soon
      ),
      _FeatureItem(
        icon: Icons.person_outline_rounded,
        title: 'Profil',
        subtitle: 'Lihat perjalananmu',
        color: colorScheme.secondary,
        route: const ProfileRoute(),
      ),
    ];

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Fitur Utama',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Features grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  final spacing = 12.0;
                  final itemWidth = (constraints.maxWidth -
                          (spacing * (crossAxisCount - 1))) /
                      crossAxisCount;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: features.map((feature) {
                      return SizedBox(
                        width: itemWidth,
                        child: _FeatureCard(feature: feature),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final PageRouteInfo? route;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.route,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        if (feature.route != null) {
          context.router.push(feature.route!);
        } else {
          _showComingSoon(context, feature.title);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface.withValues(alpha: 0.85),
                  colorScheme.surface.withValues(alpha: 0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: feature.color.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: feature.color.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        feature.color.withValues(alpha: 0.2),
                        feature.color.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    feature.icon,
                    color: feature.color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  feature.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  feature.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text('$feature segera hadir!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  final AnimationController controller;

  const _QuickStatsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stats = [
      _QuickStat(
        icon: Icons.local_fire_department_rounded,
        label: 'Zoe Points',
        value: '480',
        subtitle: '+20 hari ini',
        color: colorScheme.tertiary,
      ),
      _QuickStat(
        icon: Icons.trending_up_rounded,
        label: 'Streak',
        value: '7',
        subtitle: 'hari berturut',
        color: const Color(0xFFFFB74D),
      ),
      _QuickStat(
        icon: Icons.military_tech_rounded,
        label: 'Level',
        value: '3',
        subtitle: '70 XP lagi',
        color: colorScheme.primary,
      ),
      _QuickStat(
        icon: Icons.workspace_premium_rounded,
        label: 'Badge',
        value: '5',
        subtitle: 'diperoleh',
        color: const Color(0xFFA78BFA),
      ),
    ];

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 60 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Statistik Cepat',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              // Stats grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: stats.map((stat) {
                      return SizedBox(
                        width: itemWidth,
                        child: _QuickStatCard(stat: stat),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStat {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });
}

class _QuickStatCard extends StatelessWidget {
  final _QuickStat stat;

  const _QuickStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface.withValues(alpha: 0.85),
                colorScheme.surface.withValues(alpha: 0.45),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: stat.color.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: stat.color.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          stat.color.withValues(alpha: 0.2),
                          stat.color.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(stat.icon, color: stat.color, size: 22),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                stat.value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: stat.color,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: stat.color.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityPreview extends StatelessWidget {
  final AnimationController controller;

  const _CommunityPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, 70 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.75),
                      colorScheme.surface.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with avatar stack
                    Row(
                      children: [
                        // Avatar stack
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: Stack(
                            children: [
                              _buildAvatar(colorScheme, 0, '😊'),
                              _buildAvatar(colorScheme, 28, '🙏'),
                              _buildAvatar(colorScheme, 56, '✨'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1.2k+ sahabat aktif',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'bergabung minggu ini',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Bergabung dengan Komunitas',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      'Terhubung dengan sesama sahabat untuk saling mendukung dan berbagi perjalanan iman.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CTA Button
                    GestureDetector(
                      onTap: () => _showComingSoon(context, 'Komunitas'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              color: colorScheme.onPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Jelajahi Komunitas',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, double left, String emoji) {
    return Positioned(
      left: left,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text('$feature segera hadir!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
      ),
    );
  }
}
