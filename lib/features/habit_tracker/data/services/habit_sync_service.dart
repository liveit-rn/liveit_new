import 'dart:async';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/network/api_exception.dart';
import '../datasources/habit_remote_data_source.dart';
import '../datasources/outbox_local_data_source.dart';
import '../models/pending_mutation.dart';
import 'sync_status.dart';

class HabitSyncService {
  HabitSyncService({
    required OutboxLocalDataSource outbox,
    required HabitRemoteDataSource remoteDataSource,
    required ConnectivityService connectivity,
  }) : _outbox = outbox,
       _remoteDataSource = remoteDataSource,
       _connectivity = connectivity {
    _connectivitySubscription = _connectivity.onlineStatus$.listen((isOnline) {
      if (isOnline) {
        unawaited(sync());
      }
    });
    unawaited(_emitIdle());
  }

  final OutboxLocalDataSource _outbox;
  final HabitRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivity;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  Stream<SyncStatus> get status$ => _statusController.stream;

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await _outbox.getPendingMutations();
      if (pending.isEmpty) {
        _statusController.add(const SyncIdle(pendingCount: 0));
        return;
      }

      final online = await _connectivity.isOnline;
      if (!online) {
        _statusController.add(
          SyncError(
            message: 'Perangkat sedang offline.',
            pendingCount: pending.length,
          ),
        );
        return;
      }

      final total = pending.length;
      var completed = 0;

      for (final mutation in pending) {
        _statusController.add(
          SyncInProgress(
            total: total,
            completed: completed,
            pendingCount: total - completed,
          ),
        );

        try {
          await _applyMutation(mutation);
          await _outbox.removeMutation(mutation.id);
          completed++;
        } on ApiException catch (error) {
          if (_isNetworkError(error)) {
            _statusController.add(
              SyncError(
                message: error.message,
                pendingCount: total - completed,
              ),
            );
            return;
          }

          if (_isServerWinsDrop(error)) {
            await _outbox.removeMutation(mutation.id);
            completed++;
            continue;
          }

          _statusController.add(
            SyncError(message: error.message, pendingCount: total - completed),
          );
          return;
        } catch (_) {
          _statusController.add(
            SyncError(
              message: 'Sinkronisasi gagal. Coba lagi.',
              pendingCount: total - completed,
            ),
          );
          return;
        }
      }

      await _emitIdle();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _applyMutation(PendingMutation mutation) async {
    final userHabitId = mutation.payload['userHabitId'] as String;
    final date = mutation.payload['date'] as String;

    switch (mutation.type) {
      case PendingMutationType.checkIn:
        await _remoteDataSource.checkIn(userHabitId, date);
        break;
      case PendingMutationType.undoCheckIn:
        await _remoteDataSource.undoCheckIn(userHabitId, date);
        break;
    }
  }

  bool _isNetworkError(ApiException error) {
    return error.type == ApiExceptionType.noInternet ||
        error.type == ApiExceptionType.timeout;
  }

  bool _isServerWinsDrop(ApiException error) {
    final code = error.statusCode;
    if (code == null) return false;
    return code >= 400 && code < 500;
  }

  Future<void> _emitIdle() async {
    final pendingCount = await _outbox.getPendingCount();
    _statusController.add(SyncIdle(pendingCount: pendingCount));
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _statusController.close();
    _connectivity.dispose();
  }
}
