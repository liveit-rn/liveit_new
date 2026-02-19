import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:liveit_new/core/connectivity/connectivity_service.dart';
import 'package:liveit_new/core/network/api_exception.dart';
import 'package:liveit_new/features/habit_tracker/data/datasources/habit_remote_data_source.dart';
import 'package:liveit_new/features/habit_tracker/data/datasources/outbox_local_data_source.dart';
import 'package:liveit_new/features/habit_tracker/data/models/habit_checkin_response_model.dart';
import 'package:liveit_new/features/habit_tracker/data/models/habit_model.dart';
import 'package:liveit_new/features/habit_tracker/data/models/pending_mutation.dart';
import 'package:liveit_new/features/habit_tracker/data/models/user_habit_model.dart';
import 'package:liveit_new/features/habit_tracker/data/services/habit_sync_service.dart';
import 'package:liveit_new/features/habit_tracker/data/services/sync_status.dart';

void main() {
  late _FakeOutboxLocalDataSource outbox;
  late _FakeHabitRemoteDataSource remote;
  late _FakeConnectivityService connectivity;
  late HabitSyncService syncService;

  setUp(() {
    outbox = _FakeOutboxLocalDataSource();
    remote = _FakeHabitRemoteDataSource();
    connectivity = _FakeConnectivityService(initialOnline: true);
    syncService = HabitSyncService(
      outbox: outbox,
      remoteDataSource: remote,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await syncService.dispose();
    connectivity.dispose();
  });

  test('drains queue FIFO when online', () async {
    outbox.seed([
      PendingMutation(
        id: '1',
        type: PendingMutationType.checkIn,
        payload: {'userHabitId': 'habit-1', 'date': '2026-02-16'},
        createdAt: DateTime(2026, 2, 16, 8),
      ),
      PendingMutation(
        id: '2',
        type: PendingMutationType.undoCheckIn,
        payload: {'userHabitId': 'habit-2', 'date': '2026-02-16'},
        createdAt: DateTime(2026, 2, 16, 9),
      ),
    ]);

    await syncService.sync();

    expect(remote.calls, [
      'checkIn:habit-1:2026-02-16',
      'undo:habit-2:2026-02-16',
    ]);
    expect(await outbox.getPendingCount(), 0);
  });

  test('stops on network error and keeps remaining mutations', () async {
    outbox.seed([
      PendingMutation(
        id: '1',
        type: PendingMutationType.checkIn,
        payload: {'userHabitId': 'habit-1', 'date': '2026-02-16'},
        createdAt: DateTime(2026, 2, 16, 8),
      ),
      PendingMutation(
        id: '2',
        type: PendingMutationType.undoCheckIn,
        payload: {'userHabitId': 'habit-2', 'date': '2026-02-16'},
        createdAt: DateTime(2026, 2, 16, 9),
      ),
    ]);

    remote.failCheckInWith = ApiException.noInternet(message: 'Offline');

    await syncService.sync();

    expect(await outbox.getPendingCount(), 2);
  });

  test('drops mutation on 4xx error (server-wins)', () async {
    outbox.seed([
      PendingMutation(
        id: '1',
        type: PendingMutationType.checkIn,
        payload: {'userHabitId': 'habit-1', 'date': '2026-02-16'},
        createdAt: DateTime(2026, 2, 16, 8),
      ),
    ]);

    remote.failCheckInWith = ApiException.validationError(
      message: 'Already checked in',
    );

    await syncService.sync();

    expect(await outbox.getPendingCount(), 0);
  });

  test('emits progress and idle statuses during sync', () async {
    outbox.seed([
      PendingMutation(
        id: '1',
        type: PendingMutationType.checkIn,
        payload: {'userHabitId': 'habit-1', 'date': '2026-02-16'},
        createdAt: DateTime(2026, 2, 16, 8),
      ),
    ]);

    final statuses = <SyncStatus>[];
    final sub = syncService.status$.listen(statuses.add);

    await syncService.sync();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await sub.cancel();

    expect(statuses.any((s) => s is SyncInProgress), isTrue);
    expect(statuses.any((s) => s is SyncIdle && s.pendingCount == 0), isTrue);
  });

  test('sync is triggered when connectivity turns online', () async {
    outbox.seed([
      PendingMutation(
        id: '1',
        type: PendingMutationType.checkIn,
        payload: {'userHabitId': 'habit-1', 'date': '2026-02-16'},
        createdAt: DateTime(2026, 2, 16, 8),
      ),
    ]);

    connectivity.setOnline(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    connectivity.setOnline(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(await outbox.getPendingCount(), 0);
  });
}

class _FakeConnectivityService extends ConnectivityService {
  _FakeConnectivityService({required bool initialOnline})
    : _isOnline = initialOnline;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isOnline;

  @override
  Stream<bool> get onlineStatus$ => _controller.stream;

  @override
  Future<bool> get isOnline async => _isOnline;

  void setOnline(bool value) {
    _isOnline = value;
    _controller.add(value);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class _FakeOutboxLocalDataSource implements OutboxLocalDataSource {
  final List<PendingMutation> _items = [];

  void seed(List<PendingMutation> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> addMutation(PendingMutation mutation) async {
    _items.add(mutation);
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }

  @override
  Future<bool> hasPending() async {
    return _items.isNotEmpty;
  }

  @override
  Future<List<PendingMutation>> getPendingMutations() async {
    final sorted = List<PendingMutation>.from(_items)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  @override
  Future<int> getPendingCount() async {
    return _items.length;
  }

  @override
  Future<void> removeMutation(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

class _FakeHabitRemoteDataSource implements HabitRemoteDataSource {
  ApiException? failCheckInWith;
  final List<String> calls = [];

  @override
  Future<HabitCheckinResponseModel> checkIn(
    String userHabitId,
    String date,
  ) async {
    if (failCheckInWith != null) {
      throw failCheckInWith!;
    }
    calls.add('checkIn:$userHabitId:$date');
    return const HabitCheckinResponseModel(
      success: true,
      created: true,
      currentStreak: 1,
      longestStreak: 1,
      totalCompletions: 1,
    );
  }

  @override
  Future<void> undoCheckIn(String userHabitId, String date) async {
    calls.add('undo:$userHabitId:$date');
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> archiveHabit(String userHabitId) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<HabitModel>> getHabitCatalog() {
    throw UnimplementedError();
  }

  @override
  Future<List<UserHabitModel>> getUserHabits() {
    throw UnimplementedError();
  }

  @override
  Future<void> reorderHabits(List<Map<String, dynamic>> updates) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
  }
}
