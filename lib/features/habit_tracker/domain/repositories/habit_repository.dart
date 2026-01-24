import '../entities/user_habit.dart';
import '../entities/habit.dart';
import '../../data/models/habit_checkin_response_model.dart';

abstract class HabitRepository {
  Future<List<UserHabit>> getUserHabits();
  Future<List<UserHabit>> getCachedHabits(); // Explicit cache access
  Future<List<Habit>> getHabitCatalog();
  Future<HabitCheckinResponseModel> checkIn(String userHabitId, String date);
  Future<void> undoCheckIn(String userHabitId, String date);
  Future<UserHabit> addHabit({
    required String habitId,
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  });
  Future<UserHabit> createCustomHabit({
    required String title,
    String? description,
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  });
  Future<UserHabit> updateHabit(
    String userHabitId, {
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  });
  Future<void> archiveHabit(String userHabitId);
  Future<void> reorderHabits(List<Map<String, dynamic>> updates);
}
