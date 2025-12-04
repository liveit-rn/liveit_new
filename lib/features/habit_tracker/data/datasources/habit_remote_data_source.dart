import '../../../../core/network/dio_client.dart';
import '../models/habit_model.dart';
import '../models/user_habit_model.dart';
import '../models/habit_checkin_response_model.dart';

abstract class HabitRemoteDataSource {
  Future<List<UserHabitModel>> getUserHabits();
  Future<List<HabitModel>> getHabitCatalog();
  Future<HabitCheckinResponseModel> checkIn(String userHabitId, String date);
  Future<void> undoCheckIn(String userHabitId, String date);
  Future<UserHabitModel> addHabit(String habitId, {String? notes});
  Future<UserHabitModel> createCustomHabit(String title, {String? notes, String? description});
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
  Future<HabitCheckinResponseModel> checkIn(String userHabitId, String date) async {
    final response = await _client.post(
      '/habits/$userHabitId/checkin',
      data: {'date': date},
    );
    return HabitCheckinResponseModel.fromJson(response.data);
  }

  @override
  Future<void> undoCheckIn(String userHabitId, String date) async {
    await _client.delete(
      '/habits/$userHabitId/checkin',
      data: {'date': date},
    );
  }

  @override
  Future<UserHabitModel> addHabit(String habitId, {String? notes}) async {
    final response = await _client.post(
      '/habits',
      data: {
        'habitId': habitId,
        if (notes != null) 'notes': notes,
      },
    );
    return UserHabitModel.fromJson(response.data);
  }
  
  @override
  Future<UserHabitModel> createCustomHabit(String title, {String? notes, String? description}) async {
    final response = await _client.post(
      '/habits/custom',
      data: {
        'title': title,
        if (notes != null) 'notes': notes,
        if (description != null) 'description': description,
      },
    );
    return UserHabitModel.fromJson(response.data);
  }
}
