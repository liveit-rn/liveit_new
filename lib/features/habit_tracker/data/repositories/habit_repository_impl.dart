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
  Future<HabitCheckinResponseModel> checkIn(
    String userHabitId,
    String date,
  ) async {
    return await _remoteDataSource.checkIn(userHabitId, date);
  }

  @override
  Future<void> undoCheckIn(String userHabitId, String date) async {
    await _remoteDataSource.undoCheckIn(userHabitId, date);
  }

  @override
  Future<UserHabit> addHabit({
    required String habitId,
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  }) async {
    return await _remoteDataSource.addHabit(
      habitId: habitId,
      notes: notes,
      repeatPeriod: repeatPeriod,
      frequency: frequency,
      frequencyDays: frequencyDays,
      color: color,
      icon: icon,
      order: order,
    );
  }

  @override
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
  }) async {
    return await _remoteDataSource.createCustomHabit(
      title: title,
      description: description,
      notes: notes,
      repeatPeriod: repeatPeriod,
      frequency: frequency,
      frequencyDays: frequencyDays,
      color: color,
      icon: icon,
      order: order,
    );
  }

  @override
  Future<UserHabit> updateHabit(
    String userHabitId, {
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  }) async {
    return await _remoteDataSource.updateHabit(
      userHabitId,
      notes: notes,
      repeatPeriod: repeatPeriod,
      frequency: frequency,
      frequencyDays: frequencyDays,
      color: color,
      icon: icon,
      order: order,
    );
  }

  @override
  Future<void> archiveHabit(String userHabitId) async {
    await _remoteDataSource.archiveHabit(userHabitId);
  }

  @override
  Future<void> reorderHabits(List<Map<String, dynamic>> updates) async {
    await _remoteDataSource.reorderHabits(updates);
  }
}
