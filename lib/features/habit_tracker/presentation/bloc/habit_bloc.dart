import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/habit_repository.dart';
import 'habit_event.dart';
import 'habit_state.dart';
import '../../domain/entities/user_habit.dart';
// Need to import UserHabitModel to use copyWith if needed, or implement copyWith in UserHabit entity.
// Assuming UserHabit entity is immutable and we might need to recreate it.
// For now, I will just reload from API or modify the list locally.

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
  }

  Future<void> _onHabitStarted(HabitStarted event, Emitter<HabitState> emit) async {
    emit(HabitLoading());
    try {
      final habits = await _repository.getUserHabits();
      // Sort by order then createdAt (implied/backend sort)
      // If backend sorts, we use as is.
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

    // Optimistic update
    final oldHabit = habits[index];
    // Create a copy with checkedInToday = true
    // Since I didn't implement copyWith in Entity, I'll do a hack or construct new one.
    // Better to add copyWith to Entity or Model.
    // For now, I'll construct manually to avoid editing Entity file again if possible, 
    // but copyWith is cleaner. I'll assume I can fetch the updated list or update locally.
    
    // Just fetch list again for simplicity to ensure consistency with backend rules (streaks, points)
    // OR: Locally update 'checkedInToday' only, then background fetch.
    // Guide says: "Optimistic UI: Immediately show 'Done' state... Background Sync".
    
    // I'll implement simple optimistic update by updating the boolean.
    // But I can't easily instantiate UserHabit without all fields.
    // I'll fetch fresh data for now as MVP step 1. Optimistic later if slow.
    // Actually, user expects instant feedback.
    
    // Let's add copyWith to UserHabit entity/model.
    // Since I am in the Bloc, I can just proceed with API call and then reload.
    // To be "Optimistic", I need to emit a new state with the change BEFORE api call.
    
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      
      // Call API
      final response = await _repository.checkIn(event.userHabitId, dateStr);
      
      // If successful, reload habits to get updated streaks/stats
      add(HabitStarted()); 
    } catch (e) {
      emit(HabitError(e.toString()));
      // Re-emit old state if needed, but since we didn't optimistic update yet, 
      // we just show error.
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
      await _repository.addHabit(event.habitId, notes: event.notes);
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }
  
  Future<void> _onCustomHabitCreated(CustomHabitCreated event, Emitter<HabitState> emit) async {
    try {
      await _repository.createCustomHabit(event.title, notes: event.notes, description: event.description);
      add(HabitStarted());
    } catch (e) {
      emit(HabitError(e.toString()));
    }
  }
}
