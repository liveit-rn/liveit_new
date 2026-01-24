import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/habit_repository.dart';
import 'habit_event.dart';
import 'habit_state.dart';
import '../../domain/entities/user_habit.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final HabitRepository _repository;

  HabitBloc({required HabitRepository repository})
    : _repository = repository,
      super(HabitInitial()) {
    on<HabitStarted>(_onHabitStarted);
    on<HabitCheckInRequested>(_onHabitCheckInRequested);
    on<HabitUndoCheckInRequested>(_onHabitUndoCheckInRequested);
    on<HabitAdded>(_onHabitAdded);
    on<CustomHabitCreated>(_onCustomHabitCreated);
    on<HabitUpdated>(_onHabitUpdated);
    on<HabitArchived>(_onHabitArchived);
    on<HabitReordered>(_onHabitReordered);
  }

  Future<void> _onHabitStarted(
    HabitStarted event,
    Emitter<HabitState> emit,
  ) async {
    emit(HabitLoading());
    try {
      final habits = await _repository.getUserHabits();
      emit(HabitLoaded(habits: habits, lastUpdated: DateTime.now()));
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  Future<void> _onHabitCheckInRequested(
    HabitCheckInRequested event,
    Emitter<HabitState> emit,
  ) async {
    if (state is! HabitLoaded) return;
    final currentState = state as HabitLoaded;
    final habits = List<UserHabit>.from(currentState.habits);
    final index = habits.indexWhere((h) => h.id == event.userHabitId);

    if (index == -1) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      final response = await _repository.checkIn(event.userHabitId, dateStr);
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  Future<void> _onHabitUndoCheckInRequested(
    HabitUndoCheckInRequested event,
    Emitter<HabitState> emit,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      await _repository.undoCheckIn(event.userHabitId, dateStr);
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  Future<void> _onHabitAdded(HabitAdded event, Emitter<HabitState> emit) async {
    try {
      await _repository.addHabit(
        habitId: event.habitId,
        notes: event.notes,
        repeatPeriod: event.repeatPeriod,
        frequency: event.frequency,
        frequencyDays: event.frequencyDays,
        color: event.color,
        icon: event.icon,
        order: event.order,
      );
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  Future<void> _onCustomHabitCreated(
    CustomHabitCreated event,
    Emitter<HabitState> emit,
  ) async {
    try {
      await _repository.createCustomHabit(
        title: event.title,
        description: event.description,
        notes: event.notes,
        repeatPeriod: event.repeatPeriod,
        frequency: event.frequency,
        frequencyDays: event.frequencyDays,
        color: event.color,
        icon: event.icon,
        order: event.order,
      );
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  Future<void> _onHabitUpdated(
    HabitUpdated event,
    Emitter<HabitState> emit,
  ) async {
    try {
      await _repository.updateHabit(
        event.userHabitId,
        notes: event.notes,
        repeatPeriod: event.repeatPeriod,
        frequency: event.frequency,
        frequencyDays: event.frequencyDays,
        color: event.color,
        icon: event.icon,
        order: event.order,
      );
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  Future<void> _onHabitArchived(
    HabitArchived event,
    Emitter<HabitState> emit,
  ) async {
    try {
      await _repository.archiveHabit(event.userHabitId);
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  Future<void> _onHabitReordered(
    HabitReordered event,
    Emitter<HabitState> emit,
  ) async {
    try {
      await _repository.reorderHabits(event.updates);
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }
}
