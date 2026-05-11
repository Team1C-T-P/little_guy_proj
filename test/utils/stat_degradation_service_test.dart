// Tests for StatDegradation — the service that drops a pet's stats over time
// when the user has been offline. The decay formula is 0.1 * (hours_offline / 2),
// applied to hunger, hygiene, and enjoyment. Stats clamp to 0 (can't go negative),
// and a "last online time in the future" is rejected as obviously invalid input.
//
// Floating-point note: hours are integer (30 min counts as 0 hours), and
// updatePetStat truncates when converting doubles back to ints, so we use
// closeTo() to allow for small drift.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/pet_maintainance_database.dart';
import 'package:flutter_flame_playground/utils/stat_degradation_service.dart';
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

  // Helper: seed a user + pet with the requested starting state and return
  // a StatDegradation service ready to call. Saves a lot of boilerplate.
  Future<StatDegradation> makeService({
    required String lastOnlineIso,
    int hungerLevel = 50,
    int hygieneLevel = 50,
    int enjoymentLevel = 50,
  }) async {
    final userId = await TestDatabase.seedUser(db, lastOnline: lastOnlineIso);
    final petId = await TestDatabase.seedLittleGuy(
      db,
      userId: userId,
      hungerLevel: hungerLevel,
      hygieneLevel: hygieneLevel,
      enjoymentLevel: enjoymentLevel,
    );
    return StatDegradation(petStatsDB: petDb, userID: userId, petID: petId);
  }

  group('UR2 — StatDegradation.degradeStats', () {
    test('[TR-PET-15] applies minimal/no decay when last online is under 2 hours ago', () async {
      // Set lastOnline to "now". By the time degradeStats runs, hours-since
      // is still 0, so the decay is 0 and stats stay where they were.
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final service = await makeService(lastOnlineIso: nowIso);

      await service.degradeStats();

      expect(await petDb.getPetStat(service.petID, 'hunger_level'), closeTo(0.5, 0.02));
      expect(await petDb.getPetStat(service.petID, 'hygiene_level'), closeTo(0.5, 0.02));
      expect(await petDb.getPetStat(service.petID, 'enjoyment_level'), closeTo(0.5, 0.02));
    });

    test('[TR-PET-16] applies the 0.1 * (hours/2) decay formula for 4 hours ago', () async {
      // 4 hours of decay = 0.1 * (4/2) = 0.2 off each stat. Starting at 0.5
      // we expect to land at 0.3, give or take FP truncation.
      final fourHoursAgo = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 4))
          .toIso8601String();
      final service = await makeService(lastOnlineIso: fourHoursAgo);

      await service.degradeStats();

      expect(await petDb.getPetStat(service.petID, 'hunger_level'), closeTo(0.3, 0.02));
      expect(await petDb.getPetStat(service.petID, 'hygiene_level'), closeTo(0.3, 0.02));
      expect(await petDb.getPetStat(service.petID, 'enjoyment_level'), closeTo(0.3, 0.02));
    });

    test('[TR-PET-17] clamps stats to the lower bound of 0 when decay would push them negative', () async {
      // 10 hours offline gives 0.5 decay. Stats already at 0.1 — that would
      // be -0.4 without the clamp. updatePetStat saves them at 0.0 instead.
      final tenHoursAgo = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 10))
          .toIso8601String();
      final service = await makeService(
        lastOnlineIso: tenHoursAgo,
        hungerLevel: 10,
        hygieneLevel: 10,
        enjoymentLevel: 10,
      );

      await service.degradeStats();

      expect(await petDb.getPetStat(service.petID, 'hunger_level'), 0.0);
      expect(await petDb.getPetStat(service.petID, 'hygiene_level'), 0.0);
      expect(await petDb.getPetStat(service.petID, 'enjoyment_level'), 0.0);
    });

    test('[TR-PET-18] throws when last online time is in the future', () async {
      // If the user's last_online is somehow in the future (clock drift, bad
      // input, whatever), refuse to "decay" anything — that's nonsense.
      final oneHourAhead = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .toIso8601String();
      final service = await makeService(lastOnlineIso: oneHourAhead);

      expect(
        () => service.degradeStats(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Last online time is in the future'),
          ),
        ),
      );
    });
  });
}
