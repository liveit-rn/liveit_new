import 'dart:math';
import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liveit_new/core/router/app_router.dart';
import 'package:liveit_new/features/habit_tracker/domain/entities/user_habit.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_bloc.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_event.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_state.dart';
import '../widgets/habit_card.dart';
import '../widgets/celebrations.dart';

/// HabitTrackerPage - The main habits screen with iOS 2026 glass-morphism design.
/// WHY: Creates a calming, encouraging environment for daily habit tracking
/// with modern frosted glass aesthetic matching ProfilePage and HomePage.
@RoutePage()
class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _isReordering = false;
  bool _showConfetti = false;

  /// Track if we're currently showing a celebration to prevent duplicates
  bool _isShowingCelebration = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    context.read<HabitBloc>().add(HabitStarted());
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    if (hour < 20) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getMotivationalMessage(int completed, int total) {
    if (total == 0) return 'Mulai hari ini dengan kebiasaan baru!';
    if (completed == 0) return 'Ayo mulai dengan langkah pertama!';
    if (completed == total) return 'Luar biasa! Semua selesai hari ini! 🎉';
    if (completed / total >= 0.7) return 'Hampir selesai, terus semangat!';
    if (completed / total >= 0.5) return 'Setengah jalan, kamu bisa!';
    return 'Langkah kecil, dampak besar!';
  }

  /// Handle celebration data from state
  void _handleCelebration(CelebrationData celebration) {
    if (_isShowingCelebration || !celebration.hasCelebration) return;
    _isShowingCelebration = true;

    // Trigger confetti for any celebration
    setState(() => _showConfetti = true);

    // Show Zoe Points popup first
    if (celebration.pointsEarned > 0) {
      _showZoePointsPopup(celebration.pointsEarned, celebration.pointsReason);
    }

    // Show streak milestone celebration (with delay if points popup shown)
    if (celebration.streakMilestone != null) {
      Future.delayed(
        Duration(milliseconds: celebration.pointsEarned > 0 ? 1500 : 0),
        () {
          if (!mounted) return;
          _showStreakCelebration(
            celebration.streakMilestone!,
            celebration.habitName ?? 'Habit',
          );
        },
      );
    }
    // Show all-done celebration
    else if (celebration.allDone) {
      Future.delayed(
        Duration(milliseconds: celebration.pointsEarned > 0 ? 1500 : 0),
        () {
          if (!mounted) return;
          final state = context.read<HabitBloc>().state;
          if (state is HabitLoaded) {
            _showAllDoneCelebration(state.totalHabits);
          }
        },
      );
    }

    // Clear celebration after showing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<HabitBloc>().add(HabitCelebrationCleared());
      _isShowingCelebration = false;
    });
  }

  void _showZoePointsPopup(int points, String? reason) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 100,
        left: 0,
        right: 0,
        child: Center(
          child: ZoePointsPopup(
            points: points,
            reason: reason ?? 'Check-in',
            onComplete: () => entry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }

  void _showStreakCelebration(int streak, String habitName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakCelebration(
        streak: streak,
        habitName: habitName,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showAllDoneCelebration(int totalHabits) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AllDoneCelebration(
        totalHabits: totalHabits,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showHabitOptions(UserHabit habit) {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.92),
                    colorScheme.surface.withValues(alpha: 0.98),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glass handle indicator
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.3),
                              colorScheme.tertiary.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Habit info header with glass card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _parseColor(habit.color)
                                    .withValues(alpha: 0.12),
                                _parseColor(habit.color)
                                    .withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _parseColor(habit.color)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _parseColor(habit.color)
                                          .withValues(alpha: 0.25),
                                      _parseColor(habit.color)
                                          .withValues(alpha: 0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _parseColor(habit.color)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    habit.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habit.title ??
                                          habit.habit?.name ??
                                          'Habit',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department_rounded,
                                          size: 16,
                                          color: colorScheme.tertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${habit.currentStreak} hari streak',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Divider(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        height: 1,
                      ),

                      // Glass option tiles
                      _buildGlassOptionTile(
                        icon: Icons.bar_chart_rounded,
                        label: 'Lihat Statistik',
                        color: colorScheme.primary,
                        onTap: () {
                          context.router.maybePop();
                          context.router
                              .push(HabitStatsRoute(userHabit: habit));
                        },
                      ),
                      _buildGlassOptionTile(
                        icon: Icons.edit_outlined,
                        label: 'Edit Habit',
                        color: colorScheme.secondary,
                        onTap: () {
                          context.router.maybePop();
                          context.router.push(EditHabitRoute(userHabit: habit));
                        },
                      ),
                      _buildGlassOptionTile(
                        icon: Icons.archive_outlined,
                        label: 'Arsipkan',
                        color: colorScheme.error,
                        onTap: () {
                          context.router.maybePop();
                          _confirmArchive(habit);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6366F1);
    }
  }

  void _confirmArchive(UserHabit habit) {
    final habitBloc = context.read<HabitBloc>();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.error.withValues(alpha: 0.15),
                        colorScheme.error.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.archive_rounded,
                    color: colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Arsipkan Habit?'),
              ],
            ),
            content: Text(
              'Habit "${habit.title ?? habit.habit?.name}" akan diarsipkan. '
              'Kamu bisa mengembalikannya nanti dari pengaturan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Batal',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.error,
                      colorScheme.error.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.error.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      habitBloc.add(HabitArchived(userHabitId: habit.id));
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(
                        'Arsipkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConfettiOverlay(
      showConfetti: _showConfetti,
      onComplete: () => setState(() => _showConfetti = false),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withValues(alpha: 0.06),
                colorScheme.surface,
                colorScheme.tertiary.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: BlocConsumer<HabitBloc, HabitState>(
            listener: (context, state) {
              if (state is HabitLoaded) {
                _progressController.forward(from: 0);

                if (state.celebration != null &&
                    state.celebration!.hasCelebration) {
                  _handleCelebration(state.celebration!);
                }
              }
            },
            builder: (context, state) {
              if (state is HabitLoading) {
                return _buildLoadingState(theme, colorScheme);
              }

              if (state is HabitError) {
                return _buildErrorState(theme, colorScheme, state.message);
              }

              if (state is HabitLoaded) {
                return _buildLoadedState(theme, colorScheme, state.habits);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddHabit() async {
    HapticFeedback.lightImpact();
    final result = await context.router.push(const AddHabitRoute());
    if (result == true && mounted) {
      context.read<HabitBloc>().add(HabitStarted());
    }
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPrimary
              ? [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85)
                ]
              : [
                  colorScheme.surface.withValues(alpha: 0.7),
                  colorScheme.surface.withValues(alpha: 0.5)
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: isPrimary ? Colors.white.withValues(alpha: 0.2) : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: isPrimary
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddHabitCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.primary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: _navigateToAddHabit,
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Tambah Kebiasaan Baru',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.08, end: 0);
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        _buildHeader(theme, colorScheme, 0, 0),
        SliverFillRemaining(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surface.withValues(alpha: 0.8),
                        colorScheme.surface.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat kebiasaan...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    ColorScheme colorScheme,
    String message,
  ) {
    return CustomScrollView(
      slivers: [
        _buildHeader(theme, colorScheme, 0, 0),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.85),
                          colorScheme.surface.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.error.withValues(alpha: 0.15),
                                colorScheme.error.withValues(alpha: 0.08),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Oops! Terjadi kesalahan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                context.read<HabitBloc>().add(HabitStarted());
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      color: colorScheme.onPrimary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Coba Lagi',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        ),
      ],
    );
  }

  Widget _buildLoadedState(
    ThemeData theme,
    ColorScheme colorScheme,
    List<UserHabit> habits,
  ) {
    final completed = habits.where((h) => h.checkedInToday).length;
    final total = habits.length;

    // Sort: pending first, then completed
    final sortedHabits = List<UserHabit>.from(habits)
      ..sort((a, b) {
        if (a.checkedInToday == b.checkedInToday) {
          return a.order.compareTo(b.order);
        }
        return a.checkedInToday ? 1 : -1;
      });

    if (habits.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HabitBloc>().add(HabitStarted());
      },
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(theme, colorScheme, completed, total),

          // Section header with glass styling
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.8),
                          colorScheme.surface.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isReordering
                              ? Icons.swap_vert_rounded
                              : Icons.checklist_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isReordering
                              ? 'Geser untuk atur urutan'
                              : 'Habits Hari Ini',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isReordering
                            ? [
                                colorScheme.primary.withValues(alpha: 0.15),
                                colorScheme.primary.withValues(alpha: 0.08),
                              ]
                            : [
                                colorScheme.surface.withValues(alpha: 0.8),
                                colorScheme.surface.withValues(alpha: 0.5),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isReordering
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : colorScheme.outline.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isReordering = !_isReordering;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isReordering
                                    ? Icons.check_rounded
                                    : Icons.swap_vert_rounded,
                                size: 16,
                                color: _isReordering
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isReordering ? 'Selesai' : 'Urutkan',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: _isReordering
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideX(begin: -0.05, end: 0, duration: 600.ms),
          ),

          // Habits list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: _isReordering
                ? _buildReorderableList(sortedHabits)
                : _buildHabitsList(sortedHabits),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList(List<UserHabit> habits) {
    return SliverReorderableList(
      itemCount: habits.length,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        final reordered = List<UserHabit>.from(habits);
        final item = reordered.removeAt(oldIndex);
        if (newIndex > oldIndex) newIndex--;
        reordered.insert(newIndex, item);

        final updates = <Map<String, dynamic>>[];
        for (var i = 0; i < reordered.length; i++) {
          updates.add({
            'userHabitId': reordered[i].id,
            'order': i,
          });
        }

        context.read<HabitBloc>().add(HabitReordered(updates: updates));
      },
      itemBuilder: (context, index) {
        final habit = habits[index];
        return ReorderableDragStartListener(
          key: ValueKey(habit.id),
          index: index,
          child: HabitCard(
            userHabit: habit,
            onToggle: () => _handleToggle(habit),
            onEdit: () => _showHabitOptions(habit),
            isReordering: true,
          ),
        );
      },
    );
  }

  Widget _buildHabitsList(List<UserHabit> habits) {
    return SliverList.builder(
      itemCount: habits.length + 1,
      itemBuilder: (context, index) {
        if (index == habits.length) {
          return _buildAddHabitCard();
        }
        final habit = habits[index];
        return HabitCard(
          key: ValueKey(habit.id),
          userHabit: habit,
          onToggle: () => _handleToggle(habit),
          onEdit: () => _showHabitOptions(habit),
        )
            .animate()
            .fadeIn(
              duration: 500.ms,
              delay: Duration(milliseconds: 100 + (index * 80)),
            )
            .slideY(
              begin: 0.08,
              end: 0,
              duration: 500.ms,
              delay: Duration(milliseconds: 100 + (index * 80)),
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  void _handleToggle(UserHabit habit) {
    HapticFeedback.lightImpact();
    if (habit.checkedInToday) {
      context.read<HabitBloc>().add(
            HabitUndoCheckInRequested(
              userHabitId: habit.id,
              date: DateTime.now(),
            ),
          );
    } else {
      context.read<HabitBloc>().add(
            HabitCheckInRequested(
              userHabitId: habit.id,
              date: DateTime.now(),
            ),
          );
    }
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        _buildHeader(theme, colorScheme, 0, 0),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.85),
                          colorScheme.surface.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Illustrated empty state with glow
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.2),
                                colorScheme.tertiary.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '🌱',
                              style: TextStyle(
                                fontSize: 56,
                                shadows: [
                                  Shadow(
                                    color: colorScheme.shadow
                                        .withValues(alpha: 0.2),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Mulai Perjalananmu',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Setiap kebiasaan baik dimulai dari langkah pertama.\n'
                          'Tambahkan habit untuk memulai.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
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
                                    colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.router.push(const AddHabitRoute());
                              },
                              borderRadius: BorderRadius.circular(16),
                              splashColor: Colors.white.withValues(alpha: 0.2),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: colorScheme.onPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tambah Habit Pertama',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.9, 0.9), duration: 800.ms),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    int completed,
    int total,
  ) {
    final now = DateTime.now();
    final dayNames = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final dateString =
        '${dayNames[now.weekday % 7]}, ${now.day} ${monthNames[now.month - 1]}';

    return SliverToBoxAdapter(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              28,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.12),
                  colorScheme.primaryContainer.withValues(alpha: 0.2),
                  colorScheme.surface.withValues(alpha: 0.8),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Date badge & Settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.surface.withValues(alpha: 0.85),
                            colorScheme.surface.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.15),
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
                            dateString,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildGlassIconButton(
                          icon: Icons.settings_outlined,
                          onTap: () {
                            // TODO: Settings or profile
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildGlassIconButton(
                          icon: Icons.add_rounded,
                          onTap: _navigateToAddHabit,
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main content row
                Row(
                  children: [
                    // Greeting & Message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              letterSpacing: -0.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getMotivationalMessage(completed, total),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Progress ring with glass effect
                    if (total > 0)
                      _buildGlassProgressRing(colorScheme, completed, total),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 800.ms).slideY(
          begin: -0.05, end: 0, duration: 800.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildGlassProgressRing(
      ColorScheme colorScheme, int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;
    final allDone = completed == total && total > 0;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.2),
                colorScheme.tertiary.withValues(alpha: 0.1),
              ],
            ),
            boxShadow: allDone
                ? [
                    BoxShadow(
                      color: colorScheme.tertiary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 32,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.9),
                      colorScheme.surface.withValues(alpha: 0.7),
                    ],
                  ),
                  border: Border.all(
                    color: allDone
                        ? colorScheme.tertiary.withValues(alpha: 0.4)
                        : colorScheme.outline.withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: progress * _progressAnimation.value,
                    backgroundColor:
                        colorScheme.outline.withValues(alpha: 0.15),
                    progressColor:
                        allDone ? colorScheme.tertiary : colorScheme.primary,
                    strokeWidth: 5,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$completed',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: allDone
                                ? colorScheme.tertiary
                                : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'of $total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
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
      },
    );
  }
}

/// Custom painter for the circular progress indicator
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -pi / 2; // Start from top
      final sweepAngle = 2 * pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      progressColor != oldDelegate.progressColor;
}
