part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}

class HabitCheckInRequested extends HomeEvent {
  const HabitCheckInRequested(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => <Object?>[habitId];
}

class HabitUndoRequested extends HomeEvent {
  const HabitUndoRequested(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => <Object?>[habitId];
}

class DevotionalHabitCreateRequested extends HomeEvent {
  const DevotionalHabitCreateRequested();
}

class PlaceholderActionRequested extends HomeEvent {
  const PlaceholderActionRequested(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class HomeRetryRequested extends HomeEvent {
  const HomeRetryRequested();
}

class HomeMessageCleared extends HomeEvent {
  const HomeMessageCleared();
}
