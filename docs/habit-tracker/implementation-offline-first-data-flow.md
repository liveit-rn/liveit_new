Offline-First Data Flow — Check-in Outbox Implementation
Implements the "write outbox" gap identified in 
offline-first-data-flow.md
. Currently, write operations (check-in, undo) fail immediately when offline and the BLoC rolls back the optimistic UI. After this change, check-in/undo actions will be queued locally and synced automatically when connectivity returns.

IMPORTANT

Scope: This plan focuses on check-in and undo check-in outbox only (the highest-impact offline write). Other writes (add/update/archive/reorder) remain API-first because they are low-frequency actions that benefit from immediate server validation.

User Review Required
IMPORTANT

Conflict resolution strategy: This plan uses server-wins. If a pending check-in conflicts with the server state (e.g., already checked in from another device), the server response takes precedence and we silently drop the pending mutation. Is this acceptable, or do you prefer last-write-wins?

WARNING

No new package dependencies needed. connectivity_plus (^7.0.0) and 
hive
/hive_flutter are already in 
pubspec.yaml
. The implementation only adds new Dart files and modifies existing ones.

Proposed Changes
Core: Connectivity Service
Wraps connectivity_plus into a simple, injectable service that exposes a Stream<bool> for online/offline status. Currently connectivity_plus is in pubspec but unused.

[NEW] 
connectivity_service.dart
dart
/// Thin wrapper around connectivity_plus.
/// Exposes `Stream<bool> onlineStatus$` and `Future<bool> isOnline`.
/// WHY: Decouples BLoC/SyncService from connectivity_plus specifics.
class ConnectivityService {
  Stream<bool> get onlineStatus$ => ...
  Future<bool> get isOnline => ...
  void dispose() => ...
}
Habit Tracker: Outbox Data Layer
[NEW] 
pending_mutation.dart
Immutable model representing a queued write operation, stored in Hive as JSON.

dart
/// Discriminated union via `type` field.
/// type: 'checkin' | 'undo_checkin'
/// payload: { userHabitId, date }
/// createdAt: timestamp for ordering
/// id: UUID for dedup
class PendingMutation {
  final String id;
  final String type;          // 'checkin' | 'undo_checkin'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
}
[NEW] 
outbox_local_data_source.dart
Hive-backed FIFO queue of PendingMutation.

dart
/// Box name: 'habit_outbox'
/// Key: mutation.id
/// API:
///   addMutation(PendingMutation) → persist
///   getPendingMutations() → List<PendingMutation> ordered by createdAt
///   removeMutation(String id) → delete after successful sync
///   hasPending() → bool (quick check)
///   clear() → wipe all (for testing/reset)
class OutboxLocalDataSourceImpl implements OutboxLocalDataSource { ... }
Habit Tracker: Sync Service
[NEW] 
habit_sync_service.dart
Orchestrates draining the outbox queue when online.

dart
/// Core responsibilities:
/// 1. Listen to ConnectivityService.onlineStatus$
/// 2. When online → drain queue FIFO
/// 3. For each mutation:
///    - Call appropriate repo method (checkIn / undoCheckIn)
///    - On success → remove from outbox
///    - On network error → stop (will retry next online event)
///    - On 4xx (conflict/validation) → remove from outbox (server-wins)
/// 4. Expose Stream<SyncStatus> for UI (idle, syncing, error, pendingCount)
/// 5. Expose manual sync() trigger
class HabitSyncService {
  Stream<SyncStatus> get status$ => ...
  Future<void> sync() => ...
  void dispose() => ...
}
[NEW] 
sync_status.dart
dart
/// Discriminated union:
///   SyncIdle
///   SyncInProgress { int total, int completed }
///   SyncError { String message, int pendingCount }
sealed class SyncStatus { int get pendingCount; }
Habit Tracker: Repository Changes
[MODIFY] 
habit_repository.dart
Add new methods to the abstract interface:

diff
+ Future<void> queueCheckIn(String userHabitId, String date);
+ Future<void> queueUndoCheckIn(String userHabitId, String date);
+ Future<bool> hasPendingMutations();
[MODIFY] 
habit_repository_impl.dart
Inject OutboxLocalDataSource alongside existing data sources
Implement queueCheckIn / queueUndoCheckIn → save PendingMutation to outbox
hasPendingMutations() → delegate to outbox
No changes to 
getUserHabits()
 read path (stays stale-while-revalidate)
Habit Tracker: BLoC Changes
[MODIFY] 
habit_state.dart
Add sync indicator to 
HabitLoaded
:

diff
class HabitLoaded extends HabitState {
   final List<UserHabit> habits;
   final DateTime lastUpdated;
   final CelebrationData? celebration;
+  final int pendingSyncCount;  // 0 = all synced
 
   const HabitLoaded({
     required this.habits,
     required this.lastUpdated,
     this.celebration,
+    this.pendingSyncCount = 0,
   });
[MODIFY] 
habit_event.dart
diff
+ /// Triggered when sync completes or connectivity changes.
+ class HabitSyncCompleted extends HabitEvent {}
+
+ /// Manual sync trigger from UI.
+ class HabitSyncRequested extends HabitEvent {}
[MODIFY] 
habit_bloc.dart
Key changes to 
_onHabitCheckInRequested
:

dart
// Current: try API → catch → rollback
// New:     try API → catch network error → queue to outbox (stay optimistic)
//          catch non-network error → rollback (server rejection)
try {
  final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
  final response = await _repository.checkIn(event.userHabitId, dateStr);
  // ... existing celebration logic ...
  add(HabitStarted());
} catch (e) {
  if (_isNetworkError(e)) {
    // OFFLINE: Queue to outbox, keep optimistic UI
    await _repository.queueCheckIn(event.userHabitId, dateStr);
    // Update pending count in state
    emit(HabitLoaded(
      habits: optimisticHabits,
      lastUpdated: DateTime.now(),
      pendingSyncCount: await _repository.pendingCount(),
    ));
  } else {
    // SERVER REJECTION: Rollback as before
    emit(HabitLoaded(habits: originalHabits, lastUpdated: DateTime.now()));
    emit(HabitError('Gagal menyimpan check-in: ${e.toString()}'));
  }
}
Same pattern for 
_onHabitUndoCheckInRequested
.

New handlers:

_onHabitSyncRequested → call SyncService.sync() + refresh
_onHabitSyncCompleted → 
add(HabitStarted())
 to refresh from server
Inject HabitSyncService into 
HabitBloc
 and subscribe to status$ stream.

DI Container
[MODIFY] 
injection_container.dart
diff
+ // Connectivity
+ getIt.registerLazySingleton<ConnectivityService>(
+   () => ConnectivityService(),
+ );
+
  // Habit Tracker
  final habitCacheBox = await HabitLocalDataSourceImpl.openBox();
+ final outboxBox = await OutboxLocalDataSourceImpl.openBox();
+
  getIt.registerLazySingleton<HabitLocalDataSource>(
    () => HabitLocalDataSourceImpl(habitCacheBox),
  );
+ getIt.registerLazySingleton<OutboxLocalDataSource>(
+   () => OutboxLocalDataSourceImpl(outboxBox),
+ );
  
  // Repository now gets outbox too
  getIt.registerLazySingleton<HabitRepository>(
    () => HabitRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
+     outboxDataSource: getIt(),
    ),
  );
+
+ // Sync Service
+ getIt.registerLazySingleton<HabitSyncService>(
+   () => HabitSyncService(
+     outbox: getIt(),
+     remoteDataSource: getIt(),
+     connectivity: getIt(),
+   ),
+ );
  
  // BLoC now gets sync service
  getIt.registerFactory<HabitBloc>(
-   () => HabitBloc(repository: getIt()),
+   () => HabitBloc(
+     repository: getIt(),
+     syncService: getIt(),
+   ),
  );
UI Changes
[MODIFY] 
habit_tracker_page.dart
Minimal UI additions:

Sync indicator banner: When pendingSyncCount > 0, show a subtle banner below header: "X perubahan menunggu sinkronisasi" with a manual Sync button
Pending badge on habit items: Subtle dot or clock icon on habits with pending mutations (optional, can be deferred)
Architecture Diagram
Core
Data Layer
Domain Layer
Presentation Layer
events
read/write
subscribe status$
online write
cache read/write
queue offline write
drain queue
replay mutations
listen online$
connectivity_plus
HabitTrackerPage
HabitBloc
HabitRepository
HabitRemoteDataSource(API / Dio)
HabitLocalDataSource(Hive: habits_cache)
OutboxLocalDataSource(Hive: habit_outbox)
HabitSyncService
ConnectivityService(connectivity_plus)
Verification Plan
Automated Tests
All tests use flutter test and existing dev dependencies (flutter_test, bloc_test).

1. Outbox Data Source Unit Test
File: test/features/habit_tracker/data/datasources/outbox_local_data_source_test.dart

flutter test test/features/habit_tracker/data/datasources/outbox_local_data_source_test.dart
Tests:

addMutation() persists to Hive box
getPendingMutations() returns FIFO order
removeMutation() deletes by id
hasPending() returns correct boolean
clear()
 wipes all
2. Sync Service Unit Test
File: test/features/habit_tracker/data/services/habit_sync_service_test.dart

flutter test test/features/habit_tracker/data/services/habit_sync_service_test.dart
Tests:

Drains queue FIFO when online
Stops on network error, retains remaining mutations
Removes mutation on 4xx (server-wins conflict)
Emits correct SyncStatus transitions
Manual sync() trigger works
3. HabitBloc Updated Tests
File: test/features/habit_tracker/presentation/bloc/habit_bloc_test.dart

flutter test test/features/habit_tracker/presentation/bloc/habit_bloc_test.dart
Tests:

Check-in offline → queues mutation, stays optimistic
Check-in online → existing behavior unchanged
Undo offline → queues mutation, stays optimistic
Sync completed → refreshes habit list
pendingSyncCount reflects outbox state
4. Static Analysis
dart analyze lib/
Must be clean (zero issues).

Manual Verification
NOTE

Karena ini melibatkan konektivitas real, manual testing penting untuk memastikan end-to-end flow.

Steps (setelah implementasi selesai):

Buka app → pastikan habit list muncul normal (dari cache atau API)
Matikan WiFi/data (airplane mode di device/emulator)
Tap check-in pada salah satu habit
✅ Expected: Checkbox terisi instan (optimistic), muncul banner "1 perubahan menunggu sinkronisasi"
Tap undo check-in pada habit lain
✅ Expected: Checkbox dikosongkan instan, banner update "2 perubahan menunggu sinkronisasi"
Nyalakan kembali WiFi/data
✅ Expected: Banner hilang dalam beberapa detik, habit list refresh dari server
Verifikasi di server bahwa check-in dan undo terefleksi