import '../entities/user_habit.dart';
import '../entities/habit.dart';
import '../../data/models/habit_checkin_response_model.dart';

abstract class HabitRepository {
  Future<List<UserHabit>> getUserHabits();
  Future<List<Habit>> getHabitCatalog();
  Future<HabitCheckinResponseModel> checkIn(String userHabitId, String date);
  Future<void> undoCheckIn(String userHabitId, String date);
  Future<UserHabit> addHabit(String habitId, {String? notes});
  Future<UserHabit> createCustomHabit(String title, {String? notes, String? description});
}
