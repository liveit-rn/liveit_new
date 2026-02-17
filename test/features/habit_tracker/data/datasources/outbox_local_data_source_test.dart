import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:liveit_new/features/habit_tracker/data/datasources/outbox_local_data_source.dart';
import 'package:liveit_new/features/habit_tracker/data/models/pending_mutation.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late OutboxLocalDataSource outbox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('liveit_outbox_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    box = await Hive.openBox(OutboxLocalDataSourceImpl.boxName);
    outbox = OutboxLocalDataSourceImpl(box);
    await outbox.clear();
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('addMutation persists mutation to box', () async {
    final mutation = PendingMutation(
      id: 'm1',
      type: PendingMutationType.checkIn,
      payload: {'userHabitId': 'h1', 'date': '2026-02-16'},
      createdAt: DateTime(2026, 2, 16, 9),
    );

    await outbox.addMutation(mutation);
    final pending = await outbox.getPendingMutations();

    expect(pending.length, 1);
    expect(pending.first.id, 'm1');
  });

  test('getPendingMutations returns FIFO by createdAt', () async {
    final newer = PendingMutation(
      id: 'm2',
      type: PendingMutationType.undoCheckIn,
      payload: {'userHabitId': 'h2', 'date': '2026-02-16'},
      createdAt: DateTime(2026, 2, 16, 10),
    );
    final older = PendingMutation(
      id: 'm1',
      type: PendingMutationType.checkIn,
      payload: {'userHabitId': 'h1', 'date': '2026-02-16'},
      createdAt: DateTime(2026, 2, 16, 8),
    );

    await outbox.addMutation(newer);
    await outbox.addMutation(older);

    final pending = await outbox.getPendingMutations();
    expect(pending.map((e) => e.id).toList(), ['m1', 'm2']);
  });

  test('removeMutation deletes item by id', () async {
    final mutation = PendingMutation(
      id: 'm1',
      type: PendingMutationType.checkIn,
      payload: {'userHabitId': 'h1', 'date': '2026-02-16'},
      createdAt: DateTime(2026, 2, 16),
    );

    await outbox.addMutation(mutation);
    await outbox.removeMutation('m1');

    final pending = await outbox.getPendingMutations();
    expect(pending, isEmpty);
  });

  test('hasPending returns true when queue is not empty', () async {
    expect(await outbox.hasPending(), isFalse);

    final mutation = PendingMutation(
      id: 'm1',
      type: PendingMutationType.checkIn,
      payload: {'userHabitId': 'h1', 'date': '2026-02-16'},
      createdAt: DateTime(2026, 2, 16),
    );
    await outbox.addMutation(mutation);

    expect(await outbox.hasPending(), isTrue);
  });

  test('clear removes all queued mutations', () async {
    final mutation = PendingMutation(
      id: 'm1',
      type: PendingMutationType.checkIn,
      payload: {'userHabitId': 'h1', 'date': '2026-02-16'},
      createdAt: DateTime(2026, 2, 16),
    );

    await outbox.addMutation(mutation);
    await outbox.clear();

    expect(await outbox.getPendingCount(), 0);
  });
}
