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

  const HabitUndoCheckInRequested({
    required this.userHabitId,
    required this.date,
  });

  @override
  List<Object?> get props => [userHabitId, date];
}

class HabitAdded extends HabitEvent {
  final String habitId;
  final String? notes;
  final String? repeatPeriod;
  final String? frequency;
  final String? frequencyDays;
  final String? color;
  final String? icon;
  final int? order;

  const HabitAdded({
    required this.habitId,
    this.notes,
    this.repeatPeriod,
    this.frequency,
    this.frequencyDays,
    this.color,
    this.icon,
    this.order,
  });

  @override
  List<Object?> get props => [
    habitId,
    notes,
    repeatPeriod,
    frequency,
    frequencyDays,
    color,
    icon,
    order,
  ];
}

class CustomHabitCreated extends HabitEvent {
  final String title;
  final String? description;
  final String? notes;
  final String? repeatPeriod;
  final String? frequency;
  final String? frequencyDays;
  final String? color;
  final String? icon;
  final int? order;

  const CustomHabitCreated({
    required this.title,
    this.description,
    this.notes,
    this.repeatPeriod,
    this.frequency,
    this.frequencyDays,
    this.color,
    this.icon,
    this.order,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    notes,
    repeatPeriod,
    frequency,
    frequencyDays,
    color,
    icon,
    order,
  ];
}

class HabitUpdated extends HabitEvent {
  final String userHabitId;
  final String? notes;
  final String? repeatPeriod;
  final String? frequency;
  final String? frequencyDays;
  final String? color;
  final String? icon;
  final int? order;

  const HabitUpdated({
    required this.userHabitId,
    this.notes,
    this.repeatPeriod,
    this.frequency,
    this.frequencyDays,
    this.color,
    this.icon,
    this.order,
  });

  @override
  List<Object?> get props => [
    userHabitId,
    notes,
    repeatPeriod,
    frequency,
    frequencyDays,
    color,
    icon,
    order,
  ];
}

class HabitArchived extends HabitEvent {
  final String userHabitId;

  const HabitArchived({required this.userHabitId});

  @override
  List<Object?> get props => [userHabitId];
}

class HabitReordered extends HabitEvent {
  final List<Map<String, dynamic>> updates;

  const HabitReordered({required this.updates});

  @override
  List<Object?> get props => [updates];
}
