import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/utils/last_online_updater.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
  });

  tearDown(() async {
    await db.close();
  });

  group('UR1 — LastOnlineUpdater', () {
    test('[TR-PRF-13] updates the last_online column for a valid user', () async {
      final userId = await TestDatabase.seedUser(
        db,
        lastOnline: '2026-01-01T00:00:00Z',
      );

      await LastOnlineUpdater.update(userId, db: db);

      final rows = await db.query('user', where: 'user_id = ?', whereArgs: [userId]);
      final stored = rows.first['last_online'] as String;

      expect(stored, isNot('2026-01-01T00:00:00Z'),
          reason: 'last_online should have been overwritten with the current timestamp');
      expect(() => DateTime.parse(stored), returnsNormally,
          reason: 'stored value should be a valid ISO-8601 string');
    });

    test('[TR-PRF-14] silently no-ops when the userId has no matching row', () async {
      // Should not throw — sqflite update returns 0 affected rows without exception.
      await LastOnlineUpdater.update(999, db: db);

      final rows = await db.query('user');
      expect(rows, isEmpty,
          reason: 'No user row should have been created by the failed update');
    });
  });
}
