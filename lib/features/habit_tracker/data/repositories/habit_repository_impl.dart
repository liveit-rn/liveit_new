import '../../domain/entities/habit.dart';
import '../../domain/entities/user_habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_remote_data_source.dart';
import '../models/habit_checkin_response_model.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitRemoteDataSource _remoteDataSource;

  HabitRepositoryImpl({required HabitRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<UserHabit>> getUserHabits() async {
    return await _remoteDataSource.getUserHabits();
  }

  @override
  Future<List<Habit>> getHabitCatalog() async {
    return await _remoteDataSource.getHabitCatalog();
  }

  @override
  Future<HabitCheckinResponseModel> checkIn(String userHabitId, String date) async {
    return await _remoteDataSource.checkIn(userHabitId, date);
  }

  @override
  Future<void> undoCheckIn(String userHabitId, String date) async {
    await _remoteDataSource.undoCheckIn(userHabitId, date);
  }

  @override
  Future<UserHabit> addHabit(String habitId, {String? notes}) async {
    return await _remoteDataSource.addHabit(habitId, notes: notes);
  }
  
  @override
  Future<UserHabit> createCustomHabit(String title, {String? notes, String? description}) async {
    return await _remoteDataSource.createCustomHabit(title, notes: notes, description: description);
  }
}
