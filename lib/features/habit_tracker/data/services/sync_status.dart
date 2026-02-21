sealed class SyncStatus {
  const SyncStatus({required this.pendingCount});

  final int pendingCount;
}

class SyncIdle extends SyncStatus {
  const SyncIdle({required super.pendingCount});
}

class SyncInProgress extends SyncStatus {
  const SyncInProgress({
    required this.total,
    required this.completed,
    required super.pendingCount,
  });

  final int total;
  final int completed;
}

class SyncError extends SyncStatus {
  const SyncError({required this.message, required super.pendingCount});

  final String message;
}
