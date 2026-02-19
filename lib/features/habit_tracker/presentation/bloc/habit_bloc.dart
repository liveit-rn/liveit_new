import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/services/habit_sync_service.dart';
import '../../data/services/sync_status.dart';
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
  final HabitSyncService _syncService;

  /// Pending celebration to show after next refresh
  CelebrationData? _pendingCelebration;
  StreamSubscription<SyncStatus>? _syncSubscription;
  int _latestPendingSyncCount = 0;

  HabitBloc({
    required HabitRepository repository,
    required HabitSyncService syncService,
  }) : _repository = repository,
       _syncService = syncService,
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
    on<HabitSyncRequested>(_onHabitSyncRequested);
    on<HabitSyncCompleted>(_onHabitSyncCompleted);
    on<HabitSyncStatusUpdated>(_onHabitSyncStatusUpdated);

    _syncSubscription = _syncService.status$.listen(_onSyncStatusChanged);
  }

  Future<void> _onHabitStarted(
    HabitStarted event,
    Emitter<HabitState> emit,
  ) async {
    emit(HabitLoading());

    // 1. Try to load from cache first (Instant UI)
    int pendingSyncCount = 0;
    try {
      pendingSyncCount = await _repository.pendingMutationsCount();
    } catch (_) {
      pendingSyncCount = 0;
    }
    _latestPendingSyncCount = pendingSyncCount;

    try {
      final cachedHabits = await _repository.getCachedHabits();
      if (cachedHabits.isNotEmpty) {
        emit(
          HabitLoaded(
            habits: cachedHabits,
            lastUpdated: DateTime.now(),
            pendingSyncCount: pendingSyncCount,
            syncFeedbackMessage: null,
          ),
        );
      }
    } catch (_) {
      // Ignore cache errors
    }

    // 2. Fetch fresh data from API (Source of Truth)
    try {
      final habits = await _repository.getUserHabits();

      // Include any pending celebration from recent check-in
      final celebration = _pendingCelebration;
      _pendingCelebration = null;

      emit(
        HabitLoaded(
          habits: habits,
          lastUpdated: DateTime.now(),
          celebration: celebration,
          pendingSyncCount: pendingSyncCount,
          syncFeedbackMessage: null,
        ),
      );
    } catch (e) {
      // If we already emitted cached data, don't show error screen,
      // just stay on cached data (maybe show snackbar later)
      if (state is! HabitLoaded) {
        emit(HabitError(e.toString()));
      }
    }
  }

  Future<void> _onHabitCheckInRequested(
    HabitCheckInRequested event,
    Emitter<HabitState> emit,
  ) async {
    if (state is! HabitLoaded) return;
    final currentState = state as HabitLoaded;
    final originalHabits = List<UserHabit>.from(currentState.habits);
    final index = originalHabits.indexWhere((h) => h.id == event.userHabitId);

    if (index == -1) return;

    final habit = originalHabits[index];
    final habitName = habit.title ?? habit.habit?.name ?? 'Habit';

    // ============================================
    // OPTIMISTIC UI: Update instantly (Me+ style)
    // ============================================
    // 1. Create optimistic version with checkedInToday = true
    final optimisticHabit = UserHabit(
      id: habit.id,
      userId: habit.userId,
      habitId: habit.habitId,
      notes: habit.notes,
      isCustom: habit.isCustom,
      title: habit.title,
      visibility: habit.visibility,
      reach: habit.reach,
      repeatPeriod: habit.repeatPeriod,
      repeatStartDate: habit.repeatStartDate,
      repeatEndDate: habit.repeatEndDate,
      frequency: habit.frequency,
      frequencyDays: habit.frequencyDays,
      currentStreak: habit.currentStreak + 1, // Optimistic streak increment
      longestStreak: habit.longestStreak,
      totalCompletions: habit.totalCompletions + 1,
      color: habit.color,
      icon: habit.icon,
      order: habit.order,
      checkedInToday: true, // The key change!
      lastCheckinAt: DateTime.now(),
      habit: habit.habit,
    );

    // 2. Replace in list and emit immediately (user sees instant check!)
    final optimisticHabits = List<UserHabit>.from(originalHabits);
    optimisticHabits[index] = optimisticHabit;

    emit(
      HabitLoaded(
        habits: optimisticHabits,
        lastUpdated: DateTime.now(),
        pendingSyncCount: currentState.pendingSyncCount,
        syncFeedbackMessage: null,
      ),
    );

    // ============================================
    // BACKGROUND: Send to server
    // ============================================
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      final response = await _repository.checkIn(event.userHabitId, dateStr);

      // Calculate celebration data from actual server response
      _pendingCelebration = _calculateCelebration(
        response,
        habitName,
        originalHabits, // Use original to calculate "all done" correctly
        event.userHabitId,
      );

      // Refresh to get accurate state from server + show celebration
      add(HabitStarted());
    } catch (e) {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      if (_isNetworkError(e)) {
        await _repository.queueCheckIn(event.userHabitId, dateStr);
        final pendingCount = await _repository.pendingMutationsCount();
        _latestPendingSyncCount = pendingCount;

        emit(
          HabitLoaded(
            habits: optimisticHabits,
            lastUpdated: DateTime.now(),
            pendingSyncCount: pendingCount,
            syncFeedbackMessage: null,
          ),
        );

        add(HabitSyncRequested());
        return;
      }

      // ============================================
      // ROLLBACK: Revert if server failed
      // ============================================
      emit(
        HabitLoaded(
          habits: originalHabits,
          lastUpdated: DateTime.now(),
          pendingSyncCount: currentState.pendingSyncCount,
          syncFeedbackMessage: null,
        ),
      );
      emit(HabitError('Gagal menyimpan check-in: ${e.toString()}'));
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
    if (state is! HabitLoaded) return;
    final currentState = state as HabitLoaded;
    final originalHabits = List<UserHabit>.from(currentState.habits);
    final index = originalHabits.indexWhere((h) => h.id == event.userHabitId);

    if (index == -1) return;

    final habit = originalHabits[index];

    // ============================================
    // OPTIMISTIC UI: Undo instantly
    // ============================================
    final optimisticHabit = UserHabit(
      id: habit.id,
      userId: habit.userId,
      habitId: habit.habitId,
      notes: habit.notes,
      isCustom: habit.isCustom,
      title: habit.title,
      visibility: habit.visibility,
      reach: habit.reach,
      repeatPeriod: habit.repeatPeriod,
      repeatStartDate: habit.repeatStartDate,
      repeatEndDate: habit.repeatEndDate,
      frequency: habit.frequency,
      frequencyDays: habit.frequencyDays,
      currentStreak: habit.currentStreak > 0 ? habit.currentStreak - 1 : 0,
      longestStreak: habit.longestStreak,
      totalCompletions: habit.totalCompletions > 0
          ? habit.totalCompletions - 1
          : 0,
      color: habit.color,
      icon: habit.icon,
      order: habit.order,
      checkedInToday: false, // Unchecked!
      lastCheckinAt: habit.lastCheckinAt,
      habit: habit.habit,
    );

    final optimisticHabits = List<UserHabit>.from(originalHabits);
    optimisticHabits[index] = optimisticHabit;

    emit(
      HabitLoaded(
        habits: optimisticHabits,
        lastUpdated: DateTime.now(),
        pendingSyncCount: currentState.pendingSyncCount,
        syncFeedbackMessage: null,
      ),
    );

    // ============================================
    // BACKGROUND: Send to server
    // ============================================
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      await _repository.undoCheckIn(event.userHabitId, dateStr);
      // Refresh to get accurate state
      add(HabitStarted());
    } catch (e) {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      if (_isNetworkError(e)) {
        await _repository.queueUndoCheckIn(event.userHabitId, dateStr);
        final pendingCount = await _repository.pendingMutationsCount();
        _latestPendingSyncCount = pendingCount;

        emit(
          HabitLoaded(
            habits: optimisticHabits,
            lastUpdated: DateTime.now(),
            pendingSyncCount: pendingCount,
            syncFeedbackMessage: null,
          ),
        );

        add(HabitSyncRequested());
        return;
      }

      // Rollback
      emit(
        HabitLoaded(
          habits: originalHabits,
          lastUpdated: DateTime.now(),
          pendingSyncCount: currentState.pendingSyncCount,
          syncFeedbackMessage: null,
        ),
      );
      emit(HabitError('Gagal membatalkan check-in: ${e.toString()}'));
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

  Future<void> _onHabitSyncRequested(
    HabitSyncRequested event,
    Emitter<HabitState> emit,
  ) async {
    await _syncService.sync();
  }

  void _onHabitSyncCompleted(
    HabitSyncCompleted event,
    Emitter<HabitState> emit,
  ) {
    add(HabitStarted());
  }

  void _onSyncStatusChanged(SyncStatus status) {
    if (isClosed) {
      return;
    }

    final previousPending = _latestPendingSyncCount;
    _latestPendingSyncCount = status.pendingCount;
    final syncCompleted =
        previousPending > 0 && status.pendingCount == 0 && status is SyncIdle;
    final syncFeedbackMessage = status is SyncError
        ? 'Sinkronisasi gagal: ${status.message}'
        : null;

    add(
      HabitSyncStatusUpdated(
        pendingSyncCount: status.pendingCount,
        syncCompleted: syncCompleted,
        syncFeedbackMessage: syncFeedbackMessage,
      ),
    );
  }

  void _onHabitSyncStatusUpdated(
    HabitSyncStatusUpdated event,
    Emitter<HabitState> emit,
  ) {
    final currentState = state;
    if (currentState is HabitLoaded &&
        (currentState.pendingSyncCount != event.pendingSyncCount ||
            event.syncFeedbackMessage != null)) {
      emit(
        currentState.copyWith(
          pendingSyncCount: event.pendingSyncCount,
          lastUpdated: DateTime.now(),
          syncFeedbackMessage: event.syncFeedbackMessage,
          clearSyncFeedbackMessage: event.syncFeedbackMessage == null,
        ),
      );
    }

    if (event.syncCompleted) {
      if (!isClosed) {
        add(HabitSyncCompleted());
      }
    }
  }

  bool _isNetworkError(Object error) {
    if (error is! ApiException) {
      return false;
    }

    return error.type == ApiExceptionType.noInternet ||
        error.type == ApiExceptionType.timeout;
  }

  @override
  Future<void> close() async {
    await _syncSubscription?.cancel();
    return super.close();
  }
}
