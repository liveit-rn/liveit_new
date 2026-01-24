import 'package:equatable/equatable.dart';
import '../../domain/entities/user_habit.dart';

abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

class HabitInitial extends HabitState {}

class HabitLoading extends HabitState {}

/// Celebration data after check-in events.
/// WHY: Tracks milestone achievements for visual feedback.
class CelebrationData extends Equatable {
  /// Streak milestone hit (7, 30, 100, 365) - null if no milestone
  final int? streakMilestone;

  /// Habit name for streak celebration
  final String? habitName;

  /// True when all habits completed for the day
  final bool allDone;

  /// Zoe Points earned (10 per check-in, bonus for streaks)
  final int pointsEarned;

  /// Reason for points (e.g., "Check-in", "Streak 7 hari")
  final String? pointsReason;

  const CelebrationData({
    this.streakMilestone,
    this.habitName,
    this.allDone = false,
    this.pointsEarned = 0,
    this.pointsReason,
  });

  /// No celebration needed
  static const none = CelebrationData();

  bool get hasCelebration =>
      streakMilestone != null || allDone || pointsEarned > 0;

  @override
  List<Object?> get props => [
        streakMilestone,
        habitName,
        allDone,
        pointsEarned,
        pointsReason,
      ];
}

class HabitLoaded extends HabitState {
  final List<UserHabit> habits;
  final DateTime lastUpdated;

  /// Celebration data from recent check-in (null if just loading)
  final CelebrationData? celebration;

  const HabitLoaded({
    required this.habits,
    required this.lastUpdated,
    this.celebration,
  });

  @override
  List<Object?> get props => [habits, lastUpdated, celebration];

  /// Create a copy with cleared celebration (after it's shown)
  HabitLoaded clearCelebration() => HabitLoaded(
        habits: habits,
        lastUpdated: lastUpdated,
        celebration: null,
      );

  // Helpers for stats
  int get completedToday => habits.where((h) => h.checkedInToday).length;
  int get totalHabits => habits.length;
  int get progress =>
      totalHabits == 0 ? 0 : ((completedToday / totalHabits) * 100).round();
}

class HabitError extends HabitState {
  final String message;

  const HabitError(this.message);

  @override
  List<Object?> get props => [message];
}
