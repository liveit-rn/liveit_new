import 'package:equatable/equatable.dart';

abstract class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object?> get props => [];
}

class HabitStarted extends HabitEvent {}

class HabitCheckInRequested extends HabitEvent {
  final String userHabitId;
  final DateTime date;

  const HabitCheckInRequested({required this.userHabitId, required this.date});

  @override
  List<Object?> get props => [userHabitId, date];
}

class HabitUndoCheckInRequested extends HabitEvent {
  final String userHabitId;
  final DateTime date;

  const HabitUndoCheckInRequested({required this.userHabitId, required this.date});

  @override
  List<Object?> get props => [userHabitId, date];
}

class HabitAdded extends HabitEvent {
  final String habitId;
  final String? notes;

  const HabitAdded({required this.habitId, this.notes});

  @override
  List<Object?> get props => [habitId, notes];
}

class CustomHabitCreated extends HabitEvent {
  final String title;
  final String? notes;
  final String? description;

  const CustomHabitCreated({required this.title, this.notes, this.description});

  @override
  List<Object?> get props => [title, notes, description];
}
