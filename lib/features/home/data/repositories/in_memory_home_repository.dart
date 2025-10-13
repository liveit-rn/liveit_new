import 'dart:async';

import 'package:liveit_new/features/home/domain/repositories/home_repository.dart';
import 'package:liveit_new/features/home/presentation/models/home_ui_state.dart';

/// Simple in-memory repository to support homepage prototyping before wiring
/// to real services. Provides optimistic updates with short artificial delay.
class InMemoryHomeRepository implements HomeRepository {
  InMemoryHomeRepository({HomeUiState? seed})
    : _state = seed ?? HomeUiState.sample();

  HomeUiState _state;

  Future<void> _simulateLatency() => Future<void>.delayed(
    const Duration(milliseconds: 220),
  );

  @override
  Future<HomeUiState> fetchHome() async {
    await _simulateLatency();
    return _state;
  }

  @override
  Future<HomeUiState> refresh() async {
    await _simulateLatency();
    _state = _state.copyWith(hasError: false, isOffline: false);
    return _state;
  }

  @override
  Future<HomeUiState> checkInHabit(String habitId) async {
    await _simulateLatency();

    final List<HabitItem> pending = List<HabitItem>.from(_state.pendingHabits);
    final int index = pending.indexWhere((HabitItem item) => item.id == habitId);
    if (index == -1) {
      return _state;
    }

    final HabitItem completedHabit = pending
        .removeAt(index)
        .copyWith(checkedInToday: true);

    final List<HabitItem> completed = <HabitItem>[completedHabit, ..._state.completedHabits];

    _state = _state.copyWith(
      pendingHabits: pending,
      completedHabits: completed,
    );

    return _state;
  }

  @override
  Future<HomeUiState> undoHabit(String habitId) async {
    await _simulateLatency();

    final List<HabitItem> completed = List<HabitItem>.from(
      _state.completedHabits,
    );
    final int index = completed.indexWhere((HabitItem item) => item.id == habitId);
    if (index == -1) {
      return _state;
    }

    final HabitItem revertedHabit = completed
        .removeAt(index)
        .copyWith(checkedInToday: false);

    final List<HabitItem> pending = <HabitItem>[revertedHabit, ..._state.pendingHabits];

    _state = _state.copyWith(
      pendingHabits: pending,
      completedHabits: completed,
    );

    return _state;
  }

  @override
  Future<HomeUiState> createHabitFromDevotional() async {
    await _simulateLatency();

    final HabitItem newHabit = HabitItem(
      id: 'habit-devotional-${DateTime.now().millisecondsSinceEpoch}',
      name: _state.devotional?.title ?? 'Habit Refleksi Renungan',
      note: 'Mulai praktikkan sorotan renungan hari ini.',
    );

    _state = _state.copyWith(
      pendingHabits: <HabitItem>[newHabit, ..._state.pendingHabits],
    );

    return _state;
  }
}
