import '../../../../core/network/dio_client.dart';
import '../models/habit_model.dart';
import '../models/user_habit_model.dart';
import '../models/habit_checkin_response_model.dart';

abstract class HabitRemoteDataSource {
  Future<List<UserHabitModel>> getUserHabits();
  Future<List<HabitModel>> getHabitCatalog();
  Future<HabitCheckinResponseModel> checkIn(String userHabitId, String date);
  Future<void> undoCheckIn(String userHabitId, String date);
  Future<UserHabitModel> addHabit({
    required String habitId,
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  });
  Future<UserHabitModel> createCustomHabit({
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
  Future<UserHabitModel> updateHabit(
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

class HabitRemoteDataSourceImpl implements HabitRemoteDataSource {
  final DioClient _client;

  HabitRemoteDataSourceImpl(this._client);

  @override
  Future<List<UserHabitModel>> getUserHabits() async {
    final response = await _client.get('/habits');
    final data = response.data as List;
    return data.map((e) => UserHabitModel.fromJson(e)).toList();
  }

  @override
  Future<List<HabitModel>> getHabitCatalog() async {
    final response = await _client.get('/habits/catalog');
    final data = response.data as List;
    return data.map((e) => HabitModel.fromJson(e)).toList();
  }

  @override
  Future<HabitCheckinResponseModel> checkIn(
    String userHabitId,
    String date,
  ) async {
    final response = await _client.post(
      '/habits/$userHabitId/checkin',
      data: {'date': date},
    );
    return HabitCheckinResponseModel.fromJson(response.data);
  }

  @override
  Future<void> undoCheckIn(String userHabitId, String date) async {
    await _client.delete('/habits/$userHabitId/checkin', data: {'date': date});
  }

  @override
  Future<UserHabitModel> addHabit({
    required String habitId,
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  }) async {
    final response = await _client.post(
      '/habits',
      data: {
        'habitId': habitId,
        if (notes != null) 'notes': notes,
        if (repeatPeriod != null) 'repeatPeriod': repeatPeriod,
        if (frequency != null) 'frequency': frequency,
        if (frequencyDays != null) 'frequencyDays': frequencyDays,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        if (order != null) 'order': order,
      },
    );
    return UserHabitModel.fromJson(response.data);
  }

  @override
  Future<UserHabitModel> createCustomHabit({
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
    final response = await _client.post(
      '/habits/custom',
      data: {
        'title': title,
        if (description != null) 'description': description,
        if (notes != null) 'notes': notes,
        if (repeatPeriod != null) 'repeatPeriod': repeatPeriod,
        if (frequency != null) 'frequency': frequency,
        if (frequencyDays != null) 'frequencyDays': frequencyDays,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        if (order != null) 'order': order,
      },
    );
    return UserHabitModel.fromJson(response.data);
  }

  @override
  Future<UserHabitModel> updateHabit(
    String userHabitId, {
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  }) async {
    final response = await _client.patch(
      '/habits/$userHabitId',
      data: {
        if (notes != null) 'notes': notes,
        if (repeatPeriod != null) 'repeatPeriod': repeatPeriod,
        if (frequency != null) 'frequency': frequency,
        if (frequencyDays != null) 'frequencyDays': frequencyDays,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        if (order != null) 'order': order,
      },
    );
    return UserHabitModel.fromJson(response.data);
  }

  @override
  Future<void> archiveHabit(String userHabitId) async {
    await _client.delete('/habits/$userHabitId');
  }

  @override
  Future<void> reorderHabits(List<Map<String, dynamic>> updates) async {
    await _client.patch('/habits/reorder', data: {'updates': updates});
  }
}
