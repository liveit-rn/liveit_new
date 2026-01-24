import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../data/models/habit_checkin_response_model.dart';
import 'habit_event.dart';
import 'habit_state.dart';
import '../../domain/entities/user_habit.dart';

/// Streak milestones that trigger celebrations
const _streakMilestones = [7, 30, 100, 365];

/// Points awarded for different actions (matches backend)
const _pointsPerCheckin = 10;
const _pointsStreak7 = 50;
const _pointsStreak30 = 100;
const _pointsAllDone = 20;

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final HabitRepository _repository;

  /// Pending celebration to show after next refresh
  CelebrationData? _pendingCelebration;

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
    on<HabitCelebrationCleared>(_onCelebrationCleared);
  }

  Future<void> _onHabitStarted(
    HabitStarted event,
    Emitter<HabitState> emit,
  ) async {
    emit(HabitLoading());
    try {
      final habits = await _repository.getUserHabits();

      // Include any pending celebration from recent check-in
      final celebration = _pendingCelebration;
      _pendingCelebration = null;

      emit(HabitLoaded(
        habits: habits,
        lastUpdated: DateTime.now(),
        celebration: celebration,
      ));
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

    final habit = habits[index];
    final habitName = habit.title ?? habit.habit?.name ?? 'Habit';

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      final response = await _repository.checkIn(event.userHabitId, dateStr);

      // Calculate celebration data from response
      _pendingCelebration = _calculateCelebration(
        response,
        habitName,
        habits,
        event.userHabitId,
      );

      // Refresh to get updated state
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }

  /// Calculate celebration data based on check-in response
  CelebrationData _calculateCelebration(
    HabitCheckinResponseModel response,
    String habitName,
    List<UserHabit> currentHabits,
    String checkedHabitId,
  ) {
    int? streakMilestone;
    int pointsEarned = _pointsPerCheckin;
    String pointsReason = 'Check-in';

    // Check if we hit a streak milestone
    final streak = response.currentStreak;
    if (_streakMilestones.contains(streak)) {
      streakMilestone = streak;

      // Add bonus points for streak milestones
      if (streak >= 30) {
        pointsEarned += _pointsStreak30;
        pointsReason = 'Streak $streak hari!';
      } else if (streak >= 7) {
        pointsEarned += _pointsStreak7;
        pointsReason = 'Streak $streak hari!';
      }
    }

    // Check if all habits are now completed for today
    // (Count habits that were already checked + this one)
    final completedBefore = currentHabits.where((h) => h.checkedInToday).length;
    final totalHabits = currentHabits.length;
    final willBeCompleted = completedBefore + 1;

    final allDone = willBeCompleted >= totalHabits && totalHabits > 0;
    if (allDone) {
      pointsEarned += _pointsAllDone;
      pointsReason = 'Semua selesai!';
    }

    return CelebrationData(
      streakMilestone: streakMilestone,
      habitName: habitName,
      allDone: allDone,
      pointsEarned: pointsEarned,
      pointsReason: pointsReason,
    );
  }

  void _onCelebrationCleared(
    HabitCelebrationCleared event,
    Emitter<HabitState> emit,
  ) {
    if (state is HabitLoaded) {
      emit((state as HabitLoaded).clearCelebration());
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
