import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_habit_model.dart';

/// Local Data Source for Habit Tracker using Hive for caching.
/// WHY: Provides instant data access and offline capability (Me+ experience).
abstract class HabitLocalDataSource {
  /// Retrieves the list of habits from the local cache.
  Future<List<UserHabitModel>> getCachedHabits();

  /// Persists the given list of habits to the local cache.
  Future<void> cacheHabits(List<UserHabitModel> habits);
}

class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  static const String boxName = 'habits_cache';
  static const String _cacheKey = 'user_habits';
  final Box _box;

  HabitLocalDataSourceImpl(this._box);

  /// Opens the Hive box for habit caching.
  /// Called during dependency injection setup.
  static Future<Box> openBox() async {
    return await Hive.openBox(boxName);
  }

  @override
  Future<List<UserHabitModel>> getCachedHabits() async {
    final data = _box.get(_cacheKey);
    if (data != null && data is List) {
      return data
          .map((e) => UserHabitModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  @override
  Future<void> cacheHabits(List<UserHabitModel> habits) async {
    final jsonList = habits.map((e) => e.toJson()).toList();
    await _box.put(_cacheKey, jsonList);
  }
}
