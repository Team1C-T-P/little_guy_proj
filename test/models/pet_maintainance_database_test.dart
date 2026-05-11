import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/pet_maintainance_database.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late PetStatsDatabase petDb;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    petDb = PetStatsDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UR1 — A user should be able to have a profile and update it', () {
    group('getUserName', () {
      test('[TR-PRF-01] returns the stored username for a valid userId', () async {
        final userId = await TestDatabase.seedUser(db, name: 'Test User');

        final name = await petDb.getUserName(userId);

        expect(name, 'Test User');
      });

      test('[TR-PRF-02] throws when the userId has no matching row', () async {
        expect(
          () => petDb.getUserName(999),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get user name: User not found'),
            ),
          ),
        );
      });
    });

    group('updateUserName', () {
      test('[TR-PRF-03] updates the user_name when both inputs are valid', () async {
        final userId = await TestDatabase.seedUser(db, name: 'Test User');

        await petDb.updateUserName(userId, 'Alice');

        expect(await petDb.getUserName(userId), 'Alice');
      });

      test('[TR-PRF-04] treats empty string as "keep current" for a valid user', () async {
        final userId = await TestDatabase.seedUser(db, name: 'Test User');

        await petDb.updateUserName(userId, '');

        expect(await petDb.getUserName(userId), 'Test User',
            reason: 'Empty new name should leave the row unchanged');
      });

      test('[TR-PRF-05] throws when no row matches the userId and the name is non-empty', () async {
        expect(
          () => petDb.updateUserName(999, 'Alice'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update user name: User not found'),
            ),
          ),
        );
      });

      test('[TR-PRF-06] silently no-ops when userId is invalid but name is empty (empty-check runs first)', () async {
        // Should not throw despite the user not existing — the empty-string
        // early return runs before the existence check.
        await petDb.updateUserName(999, '');
        // Reaching this line without an exception is the assertion.
      });
    });

    group('getLastOnlineByUserId', () {
      test('[TR-PRF-07] returns the stored ISO timestamp for a valid userId', () async {
        final userId = await TestDatabase.seedUser(
          db,
          lastOnline: '2026-01-01T00:00:00Z',
        );

        final lastOnline = await petDb.getLastOnlineByUserId(userId);

        expect(lastOnline, '2026-01-01T00:00:00Z');
      });

      test('[TR-PRF-08] throws when the userId has no matching row', () async {
        expect(
          () => petDb.getLastOnlineByUserId(999),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get last online time: User not found'),
            ),
          ),
        );
      });
    });

    group('updateLastOnlineByUserId', () {
      test('[TR-PRF-09] updates the timestamp when both inputs are valid', () async {
        final userId = await TestDatabase.seedUser(db);
        const newDate = '2026-05-11T12:00:00.000Z';

        await petDb.updateLastOnlineByUserId(userId, newDate);

        expect(await petDb.getLastOnlineByUserId(userId), newDate);
      });

      test('[TR-PRF-10] throws Invalid-ISO-date when the date is malformed (valid user)', () async {
        final userId = await TestDatabase.seedUser(db);

        expect(
          () => petDb.updateLastOnlineByUserId(userId, 'not an iso date'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update last online time: Invalid ISO date format'),
            ),
          ),
        );
      });

      test('[TR-PRF-11] throws User-not-found when the userId is invalid (valid date)', () async {
        expect(
          () => petDb.updateLastOnlineByUserId(999, '2026-05-11T12:00:00.000Z'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update last online time: User not found'),
            ),
          ),
        );
      });

      test('[TR-PRF-12] throws Invalid-ISO-date for invalid user + malformed date (parse runs first)', () async {
        expect(
          () => petDb.updateLastOnlineByUserId(999, 'not an iso date'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update last online time: Invalid ISO date format'),
            ),
          ),
        );
      });
    });
  });

  group('UR2 — A user should be able to have a pet and update its name, stats, level, and hats', () {
    group('getPetName', () {
      test('[TR-PET-01] returns the stored pet name for a valid userId', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, name: 'Buddy');

        final name = await petDb.getPetName(userId);

        expect(name, 'Buddy');
      });

      test('[TR-PET-02] throws when the user has no pet row', () async {
        // User exists but no little_guy row
        await TestDatabase.seedUser(db);

        expect(
          () => petDb.getPetName(999),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get pet name: Pet not found'),
            ),
          ),
        );
      });
    });

    group('updatePetName', () {
      test('[TR-PET-03] updates little_guy_name when both inputs are valid', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, name: 'Buddy');

        await petDb.updatePetName(userId, 'Sparky');

        expect(await petDb.getPetName(userId), 'Sparky');
      });

      test('[TR-PET-04] treats empty new name as "keep current" for a valid user', () async {
        final userId = await TestDatabase.seedUser(db);
        await TestDatabase.seedLittleGuy(db, userId: userId, name: 'Buddy');

        await petDb.updatePetName(userId, '');

        expect(await petDb.getPetName(userId), 'Buddy');
      });

      test('[TR-PET-05] throws when no row matches the userId and the name is non-empty', () async {
        expect(
          () => petDb.updatePetName(999, 'Sparky'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update pet name: Pet not found'),
            ),
          ),
        );
      });

      test('[TR-PET-06] silently no-ops when userId is invalid but name is empty (empty-check runs first)', () async {
        // Should not throw — empty-string early return runs before existence check.
        await petDb.updatePetName(999, '');
      });
    });

    group('getPetStat', () {
      test('[TR-PET-07] returns the stat value scaled to 0.0-1.0 for valid pet + valid stat', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(
          db,
          userId: userId,
          hungerLevel: 50,
        );

        final value = await petDb.getPetStat(petId, 'hunger_level');

        expect(value, 0.5);
      });

      test('[TR-PET-08] throws when stat name is not in the allowed whitelist (valid pet)', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);

        expect(
          () => petDb.getPetStat(petId, 'unknown_stat'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Stat does not exist'),
            ),
          ),
        );
      });

      test('[TR-PET-09] returns 0 when the pet does not exist (valid stat)', () async {
        final value = await petDb.getPetStat(999, 'hunger_level');

        expect(value, 0.0,
            reason: 'getPetStat should return 0 for a missing pet rather than throwing');
      });

      test('[TR-PET-10] throws for invalid pet + invalid stat (whitelist runs before query)', () async {
        expect(
          () => petDb.getPetStat(999, 'unknown_stat'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Stat does not exist'),
            ),
          ),
        );
      });
    });

    group('updatePetStat', () {
      test('[TR-PET-11] writes the exact scaled value when inputs are valid', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(
          db,
          userId: userId,
          hungerLevel: 50,
        );

        await petDb.updatePetStat(petId, 'hunger_level', 0.75);

        expect(await petDb.getPetStat(petId, 'hunger_level'), closeTo(0.75, 0.01));
      });

      test('[TR-PET-12] clamps an under-range value to the lower bound of 0', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(
          db,
          userId: userId,
          hungerLevel: 50,
        );

        await petDb.updatePetStat(petId, 'hunger_level', -0.5);

        expect(await petDb.getPetStat(petId, 'hunger_level'), 0.0);
      });

      test('[TR-PET-13] clamps an over-range value to the upper bound of 1', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(
          db,
          userId: userId,
          hungerLevel: 50,
        );

        await petDb.updatePetStat(petId, 'hunger_level', 1.5);

        expect(await petDb.getPetStat(petId, 'hunger_level'), 1.0);
      });

      test('[TR-PET-14] throws when no pet row matches the petId', () async {
        expect(
          () => petDb.updatePetStat(999, 'hunger_level', 0.5),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update pet stat'),
            ),
          ),
        );
      });
    });
  });
}
