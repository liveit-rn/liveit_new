import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:liveit_new/features/home/domain/repositories/home_repository.dart';
import 'package:liveit_new/features/home/presentation/models/home_ui_state.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._repository) : super(HomeState.initial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshed>(_onRefreshed);
    on<HabitCheckInRequested>(_onHabitCheckInRequested);
    on<HabitUndoRequested>(_onHabitUndoRequested);
    on<DevotionalHabitCreateRequested>(_onDevotionalHabitCreateRequested);
    on<HomeRetryRequested>(_onRetryRequested);
    on<HomeMessageCleared>(_onMessageCleared);
    on<PlaceholderActionRequested>(_onPlaceholderActionRequested);
  }

  final HomeRepository _repository;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));
    await _fetchAndEmit(emit, () => _repository.fetchHome());
  }

  Future<void> _onRefreshed(
      HomeRefreshed event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));
    await _fetchAndEmit(emit, () => _repository.refresh());
  }

  Future<void> _onHabitCheckInRequested(
    HabitCheckInRequested event,
    Emitter<HomeState> emit,
  ) async {
    final String habitName = _resolveHabitName(event.habitId);
    await _mutateWithFeedback(
      emit,
      () => _repository.checkInHabit(event.habitId),
      successMessage: 'Mantap! $habitName selesai. +10 Zoe Points',
    );
  }

  Future<void> _onHabitUndoRequested(
    HabitUndoRequested event,
    Emitter<HomeState> emit,
  ) async {
    final String habitName = _resolveHabitName(event.habitId);
    await _mutateWithFeedback(
      emit,
      () => _repository.undoHabit(event.habitId),
      successMessage: 'Undo berhasil untuk $habitName. Yuk lanjut lagi!',
    );
  }

  Future<void> _onDevotionalHabitCreateRequested(
    DevotionalHabitCreateRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _mutateWithFeedback(
      emit,
      _repository.createHabitFromDevotional,
      successMessage: 'Habit baru dari renungan siap dikerjakan.',
    );
  }

  Future<void> _onRetryRequested(
    HomeRetryRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: HomeStatus.loading,
        errorMessage: null,
        uiState: state.uiState.copyWith(isOffline: false, hasError: false),
      ),
    );
    await _fetchAndEmit(emit, () => _repository.refresh());
  }

  void _onMessageCleared(HomeMessageCleared event, Emitter<HomeState> emit) {
    emit(state.copyWith(successMessage: null, errorMessage: null));
  }

  void _onPlaceholderActionRequested(
    PlaceholderActionRequested event,
    Emitter<HomeState> emit,
  ) {
    emit(
      state.copyWith(
        successMessage: event.message,
        errorMessage: null,
      ),
    );
  }

  Future<void> _fetchAndEmit(
    Emitter<HomeState> emit,
    Future<HomeUiState> Function() fetcher,
  ) async {
    try {
      final HomeUiState uiState = await fetcher();
      emit(
        state.copyWith(
          status: HomeStatus.success,
          uiState: uiState,
          errorMessage: null,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          uiState: state.uiState.copyWith(hasError: true),
          errorMessage: 'Gagal memuat data. Coba lagi ya.',
        ),
      );
    }
  }

  Future<void> _mutateWithFeedback(
    Emitter<HomeState> emit,
    Future<HomeUiState> Function() mutation, {
    required String successMessage,
  }) async {
    emit(state.copyWith(status: HomeStatus.mutating));
    try {
      final HomeUiState uiState = await mutation();
      emit(
        state.copyWith(
          status: HomeStatus.success,
          uiState: uiState,
          successMessage: successMessage,
          errorMessage: null,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Ada gangguan. Aksi tidak tersimpan.',
          successMessage: null,
        ),
      );
    }
  }

  String _resolveHabitName(String habitId) {
    for (final HabitItem habit in <HabitItem>[
      ...state.uiState.pendingHabits,
      ...state.uiState.completedHabits,
    ]) {
      if (habit.id == habitId) {
        return habit.name;
      }
    }
    return 'Habit';
  }
}
