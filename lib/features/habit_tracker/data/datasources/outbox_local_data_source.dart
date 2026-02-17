import 'package:hive_flutter/hive_flutter.dart';

import '../models/pending_mutation.dart';

abstract class OutboxLocalDataSource {
  Future<void> addMutation(PendingMutation mutation);
  Future<List<PendingMutation>> getPendingMutations();
  Future<void> removeMutation(String id);
  Future<bool> hasPending();
  Future<int> getPendingCount();
  Future<void> clear();
}

class OutboxLocalDataSourceImpl implements OutboxLocalDataSource {
  static const String boxName = 'habit_outbox';

  OutboxLocalDataSourceImpl(this._box);

  final Box _box;

  static Future<Box> openBox() async {
    return Hive.openBox(boxName);
  }

  @override
  Future<void> addMutation(PendingMutation mutation) async {
    await _box.put(mutation.id, mutation.toJson());
  }

  @override
  Future<List<PendingMutation>> getPendingMutations() async {
    final mutations = <PendingMutation>[];

    for (final dynamic raw in _box.values) {
      if (raw is! Map) continue;

      try {
        final mutation = PendingMutation.fromJson(
          Map<String, dynamic>.from(raw),
        );
        mutations.add(mutation);
      } catch (_) {
        // Skip corrupted rows to avoid breaking sync pipeline.
      }
    }

    mutations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return mutations;
  }

  @override
  Future<void> removeMutation(String id) async {
    await _box.delete(id);
  }

  @override
  Future<bool> hasPending() async {
    return _box.isNotEmpty;
  }

  @override
  Future<int> getPendingCount() async {
    return _box.length;
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
