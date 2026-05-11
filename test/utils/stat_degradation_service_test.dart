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

  // Helper: build a fresh pet+user with the requested stats and lastOnline,
  // then return a StatDegradation service ready to call.
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
      // lastOnline = effectively "now" (a few ms ago by the time degradeStats reads it)
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final service = await makeService(lastOnlineIso: nowIso);

      await service.degradeStats();

      // 0 hours difference → 0 decay → stats stay at 0.5
      expect(await petDb.getPetStat(service.petID, 'hunger_level'), closeTo(0.5, 0.02));
      expect(await petDb.getPetStat(service.petID, 'hygiene_level'), closeTo(0.5, 0.02));
      expect(await petDb.getPetStat(service.petID, 'enjoyment_level'), closeTo(0.5, 0.02));
    });

    test('[TR-PET-16] applies the 0.1 × (hours/2) decay formula for 4 hours ago', () async {
      final fourHoursAgo = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 4))
          .toIso8601String();
      final service = await makeService(lastOnlineIso: fourHoursAgo);

      await service.degradeStats();

      // Expected decay: 0.1 * (4 / 2) = 0.2, stats 0.5 → 0.3 (within FP tolerance)
      expect(await petDb.getPetStat(service.petID, 'hunger_level'), closeTo(0.3, 0.02));
      expect(await petDb.getPetStat(service.petID, 'hygiene_level'), closeTo(0.3, 0.02));
      expect(await petDb.getPetStat(service.petID, 'enjoyment_level'), closeTo(0.3, 0.02));
    });

    test('[TR-PET-17] clamps stats to the lower bound of 0 when decay would push them negative', () async {
      // 10 hours of decay = 0.5; starting stats at 0.1 (= 10) → -0.4 → clamped to 0
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
