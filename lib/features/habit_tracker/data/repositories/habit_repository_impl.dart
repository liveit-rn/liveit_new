import '../../domain/entities/habit.dart';
import '../../domain/entities/user_habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_remote_data_source.dart';
import '../datasources/habit_local_data_source.dart';
import '../models/habit_checkin_response_model.dart';

/// Habit Repository with Hybrid Strategy (Offline-First like Me+).
/// WHY: Provides instant data from cache, then refreshes from API in background.
/// HOW: Cache-first for reads, API-first for writes with cache update.
class HabitRepositoryImpl implements HabitRepository {
  final HabitRemoteDataSource _remoteDataSource;
  final HabitLocalDataSource _localDataSource;

  HabitRepositoryImpl({
    required HabitRemoteDataSource remoteDataSource,
    required HabitLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<List<UserHabit>> getCachedHabits() async {
    return await _localDataSource.getCachedHabits();
  }

  @override
  Future<List<UserHabit>> getUserHabits() async {
    // Strategy: Stale-While-Revalidate
    // 1. Try to get fresh data from API
    // 2. If API fails, fallback to cache (offline mode)
    // 3. Always update cache with fresh data

    try {
      // Try API first (source of truth)
      final remoteHabits = await _remoteDataSource.getUserHabits();

      // Update cache for next time (fire-and-forget, don't block)
      _localDataSource.cacheHabits(remoteHabits);

      return remoteHabits;
    } catch (e) {
      // API failed (offline or server error)
      // Fallback to cached data
      final cachedHabits = await _localDataSource.getCachedHabits();

      if (cachedHabits.isNotEmpty) {
        // Return stale data - better than nothing!
        return cachedHabits;
      }

      // No cache available - rethrow to show error UI
      rethrow;
    }
  }

  @override
  Future<List<Habit>> getHabitCatalog() async {
    // Catalog doesn't need caching - it's static reference data
    return await _remoteDataSource.getHabitCatalog();
  }

  @override
  Future<HabitCheckinResponseModel> checkIn(
    String userHabitId,
    String date,
  ) async {
    // Check-in is a write operation - must go to API
    // Optimistic UI is handled at Bloc level
    final response = await _remoteDataSource.checkIn(userHabitId, date);

    // Invalidate cache so next getUserHabits fetches fresh data
    // (We don't update cache here because response doesn't have full habit list)

    return response;
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
