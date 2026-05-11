// Tests for LevelService — the pet's experience and level-up logic.
// XP accumulates and every 100 XP triggers a level-up; leftover XP carries
// forward. If a single addXp call spans multiple level boundaries, the
// while-loop inside runs more than once.
//
// getLevelAndXp returns a sensible default ({level: 1, xp: 0}) when no pet
// row exists, so addXp on a missing user computes mathematically valid
// results but doesn't persist anything.

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
        // Seed at level 3, xp 40 — distinct enough to catch a "default returned" bug.
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 3, xp: 40);

        final result = await service.getLevelAndXp(userId);

        expect(result['level'], 3);
        expect(result['xp'], 40);
      });

      test('[TR-LVL-02] returns the default starting state when no pet row exists', () async {
        // No pet seeded. Rather than throwing, the method returns the
        // "fresh pet" defaults so the rest of the app can keep going.
        final result = await service.getLevelAndXp(999);

        expect(result['level'], 1);
        expect(result['xp'], 0);
      });
    });

    // addXp has four interesting xp totals:
    //   1. under 100   -> no level-up
    //   2. exactly 100 -> single level-up, xp resets to 0
    //   3. 100-200     -> single level-up, leftover xp preserved
    //   4. 200 or more -> multi level-up (while-loop runs > 1 time)
    group('addXp', () {
      test('[TR-LVL-03] accumulates xp without levelling when the total stays below 100', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 1, xp: 30);

        final result = await service.addXp(userId, 40); // 30 + 40 = 70

        expect(result['level'], 1, reason: 'No level-up expected');
        expect(result['xp'], 70);
        expect(result['leveledUp'], 0);

        // Confirm the values were actually persisted, not just returned.
        final persisted = await service.getLevelAndXp(userId);
        expect(persisted['level'], 1);
        expect(persisted['xp'], 70);
      });

      test('[TR-LVL-04] levels up once and resets xp to 0 at exactly 100 (boundary)', () async {
        // 60 + 40 = 100. Boundary case: xp lands on exactly 100, so we
        // level up once and xp drops to 0 (not 100).
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 1, xp: 60);

        final result = await service.addXp(userId, 40);

        expect(result['level'], 2);
        expect(result['xp'], 0);
        expect(result['leveledUp'], 1);
      });

      test('[TR-LVL-05] levels up once and carries leftover xp forward when total is between 100 and 200', () async {
        // 80 + 50 = 130. Loop runs once, xp settles at 30.
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 1, xp: 80);

        final result = await service.addXp(userId, 50);

        expect(result['level'], 2);
        expect(result['xp'], 30, reason: 'Leftover xp (130 - 100) should be preserved');
        expect(result['leveledUp'], 1);
      });

      test('[TR-LVL-06] loops correctly when one gain spans multiple level boundaries', () async {
        // 50 + 250 = 300. The while-loop should run three times:
        // 300 -> 200 -> 100 -> 0, gaining a level each pass. Final: level 4, xp 0.
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, level: 1, xp: 50);

        final result = await service.addXp(userId, 250);

        expect(result['level'], 4, reason: '1 + 3 level-ups');
        expect(result['xp'], 0);
        expect(result['leveledUp'], 1);
      });
    });

    group('setLevelAndXp', () {
      test('[TR-LVL-07] writes the values directly to the pet row', () async {
        // This is the "admin / testing" path — it just writes whatever you
        // give it, no validation or level-up logic. One partition is enough.
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
