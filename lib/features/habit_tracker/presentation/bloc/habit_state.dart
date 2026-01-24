import 'package:equatable/equatable.dart';
import '../../domain/entities/user_habit.dart';

abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

class HabitInitial extends HabitState {}

class HabitLoading extends HabitState {}

class HabitLoaded extends HabitState {
  final List<UserHabit> habits;
  final DateTime lastUpdated;

  const HabitLoaded({required this.habits, required this.lastUpdated});

  @override
  List<Object?> get props => [habits, lastUpdated];

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
