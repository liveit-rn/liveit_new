import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveit_new/core/network/api_exception.dart';
import 'package:liveit_new/features/habit_tracker/data/models/habit_checkin_response_model.dart';
import 'package:liveit_new/features/habit_tracker/data/services/habit_sync_service.dart';
import 'package:liveit_new/features/habit_tracker/data/services/sync_status.dart';
import 'package:liveit_new/features/habit_tracker/domain/entities/habit.dart';
import 'package:liveit_new/features/habit_tracker/domain/entities/user_habit.dart';
import 'package:liveit_new/features/habit_tracker/domain/repositories/habit_repository.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_bloc.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_event.dart';
import 'package:liveit_new/features/habit_tracker/presentation/bloc/habit_state.dart';

void main() {
  late _FakeHabitRepository repository;
  late _FakeHabitSyncService syncService;
  late UserHabit sampleHabit;

  setUp(() {
    repository = _FakeHabitRepository();
    syncService = _FakeHabitSyncService();

    sampleHabit = UserHabit(
      id: 'habit-1',
      title: 'Doa Pagi',
      repeatStartDate: DateTime(2026, 2, 16),
      checkedInToday: false,
      currentStreak: 2,
      totalCompletions: 5,
    );
  });

  tearDown(() async {
    await syncService.dispose();
  });

  blocTest<HabitBloc, HabitState>(
    'check-in offline queues mutation and keeps optimistic state',
    build: () {
      repository.checkInException = ApiException.noInternet(message: 'Offline');
      repository.pendingCount = 1;

      return HabitBloc(repository: repository, syncService: syncService);
    },
    seed: () => HabitLoaded(
      habits: [sampleHabit],
      lastUpdated: DateTime(2026, 2, 16, 9),
    ),
    act: (bloc) => bloc.add(
      HabitCheckInRequested(
        userHabitId: 'habit-1',
        date: DateTime(2026, 2, 16),
      ),
    ),
    expect: () => [
      isA<HabitLoaded>()
          .having((s) => s.habits.first.checkedInToday, 'checkedInToday', true)
          .having((s) => s.pendingSyncCount, 'pendingSyncCount', 0),
      isA<HabitLoaded>()
          .having((s) => s.habits.first.checkedInToday, 'checkedInToday', true)
          .having((s) => s.pendingSyncCount, 'pendingSyncCount', 1),
    ],
    verify: (_) {
      expect(repository.queueCheckInCalls, 1);
      expect(syncService.syncCalls, 1);
    },
  );

  blocTest<HabitBloc, HabitState>(
    'sync completed refreshes habit list from repository',
    build: () {
      repository.pendingCount = 0;
      repository.cachedHabits = [];
      repository.userHabits = [sampleHabit.copyWith(checkedInToday: true)];

      return HabitBloc(repository: repository, syncService: syncService);
    },
    act: (bloc) => bloc.add(HabitSyncCompleted()),
    expect: () => [
      isA<HabitLoading>(),
      isA<HabitLoaded>().having(
        (s) => s.habits.first.checkedInToday,
        'checkedInToday',
        true,
      ),
    ],
  );
}

class _FakeHabitSyncService implements HabitSyncService {
  final StreamController<SyncStatus> _controller =
      StreamController<SyncStatus>.broadcast();

  int syncCalls = 0;

  @override
  Stream<SyncStatus> get status$ => _controller.stream;

  @override
  Future<void> sync() async {
    syncCalls += 1;
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeHabitRepository implements HabitRepository {
  ApiException? checkInException;
  int pendingCount = 0;
  int queueCheckInCalls = 0;

  List<UserHabit> cachedHabits = [];
  List<UserHabit> userHabits = [];

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> archiveHabit(String userHabitId) {
    throw UnimplementedError();
  }

  @override
  Future<HabitCheckinResponseModel> checkIn(String userHabitId, String date) {
    if (checkInException != null) {
      throw checkInException!;
    }

    return Future.value(
      const HabitCheckinResponseModel(
        success: true,
        created: true,
        currentStreak: 3,
        longestStreak: 3,
        totalCompletions: 6,
      ),
    );
  }

  @override
  Future<void> undoCheckIn(String userHabitId, String date) {
    throw UnimplementedError();
  }

  @override
  Future<void> queueCheckIn(String userHabitId, String date) async {
    queueCheckInCalls += 1;
  }

  @override
  Future<void> queueUndoCheckIn(String userHabitId, String date) {
    throw UnimplementedError();
  }

  @override
  Future<List<UserHabit>> getCachedHabits() async {
    return cachedHabits;
  }

  @override
  Future<List<Habit>> getHabitCatalog() {
    throw UnimplementedError();
  }

  @override
  Future<List<UserHabit>> getUserHabits() async {
    return userHabits;
  }

  @override
  Future<bool> hasPendingMutations() async {
    return pendingCount > 0;
  }

  @override
  Future<int> pendingMutationsCount() async {
    return pendingCount;
  }

  @override
  Future<void> reorderHabits(List<Map<String, dynamic>> updates) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
  }
}
