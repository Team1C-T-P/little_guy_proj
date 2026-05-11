import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/services/level_service.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late LevelService service;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    service = LevelService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UR2 — LevelService', () {
    group('getLevelAndXp', () {
      test('[TR-LVL-01] returns the stored level and xp for a valid userId', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 3, xp: 40);

        final result = await service.getLevelAndXp(userId);

        expect(result['level'], 3);
        expect(result['xp'], 40);
      });

      test('[TR-LVL-02] returns the default starting state when no pet row exists', () async {
        // No little_guy row seeded
        final result = await service.getLevelAndXp(999);

        expect(result['level'], 1, reason: 'Default starting level is 1');
        expect(result['xp'], 0, reason: 'Default starting xp is 0');
      });
    });

    group('addXp', () {
      test('[TR-LVL-03] accumulates xp without levelling when the total stays below 100', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 1, xp: 30);

        final result = await service.addXp(userId, 40); // 30 + 40 = 70

        expect(result['level'], 1, reason: 'No level-up expected');
        expect(result['xp'], 70);
        expect(result['leveledUp'], 0);

        final persisted = await service.getLevelAndXp(userId);
        expect(persisted['level'], 1);
        expect(persisted['xp'], 70);
      });

      test('[TR-LVL-04] levels up once and resets xp to 0 at exactly 100 (boundary)', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 1, xp: 60);

        final result = await service.addXp(userId, 40); // 60 + 40 = 100

        expect(result['level'], 2);
        expect(result['xp'], 0);
        expect(result['leveledUp'], 1);
      });

      test('[TR-LVL-05] levels up once and carries leftover xp forward when total is between 100 and 200', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 1, xp: 80);

        final result = await service.addXp(userId, 50); // 80 + 50 = 130

        expect(result['level'], 2);
        expect(result['xp'], 30, reason: 'Leftover xp (130 - 100) should be preserved');
        expect(result['leveledUp'], 1);
      });

      test('[TR-LVL-06] loops correctly when one gain spans multiple level boundaries', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 1, xp: 50);

        final result = await service.addXp(userId, 250); // 50 + 250 = 300 → 3 level-ups

        expect(result['level'], 4, reason: '1 + 3 level-ups');
        expect(result['xp'], 0);
        expect(result['leveledUp'], 1);
      });
    });

    group('setLevelAndXp', () {
      test('[TR-LVL-07] writes the values directly to the pet row', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 1, xp: 0);

        await service.setLevelAndXp(userId, 10, 50);

        final result = await service.getLevelAndXp(userId);
        expect(result['level'], 10);
        expect(result['xp'], 50);
      });
    });
  });
}
