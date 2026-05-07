import 'package:flutter_flame_playground/models/pet_maintainance_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/test_database.dart';
import 'package:flutter_flame_playground/utils/stat_degradation_service.dart';

void main() {
  late Database db;
  late PetStatsDatabase petStatsDB;
  late InventoryDatabase inventoryDB;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    petStatsDB = PetStatsDatabase(db);
    inventoryDB = InventoryDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  // test getPetStat
  group('getPetStat', () {
    // test stats that are >= 0 and <= 1
    test('Returns the correct pet stat for a given petId and stat name', () async {
      // Insert test user and pet
      final userId = await TestDatabase.seedUser(db);
      final petId = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 0, hungerLevel: 100, enjoymentLevel: 50);

      // Test hunger level
      final hunger = await petStatsDB.getPetStat(petId, 'hunger_level');
      expect(hunger, 1.0);

      // Test hygiene level
      final hygiene = await petStatsDB.getPetStat(petId, 'hygiene_level');
      expect(hygiene, 0.0);

      // Test enjoyment level
      final enjoyment = await petStatsDB.getPetStat(petId, 'enjoyment_level');
      expect(enjoyment, 0.5);
    });

    test('Returns 0 if pet stat is not found', () async {
      // Do not set any stats, so they should default to 0
      final hunger = await petStatsDB.getPetStat(999, 'hunger_level');
      expect(hunger, 0.0);

      final hygiene = await petStatsDB.getPetStat(999, 'hygiene_level');
      expect(hygiene, 0.0);

      final enjoyment = await petStatsDB.getPetStat(999, 'enjoyment_level');
      expect(enjoyment, 0.0);
    });

    test('Throws an exception if trying to get a stat that does not exist', () async{
      final userId = await TestDatabase.seedUser(db);
      final petId = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 0, hungerLevel: 100, enjoymentLevel: 50);

      expect(
        () => petStatsDB.getPetStat(petId, 'unknown_stat'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // test updatePetStat
  group('updatePetStat', () {
    test('Updates the pet stat correctly for a given petId and stat name', () async {
      // Insert test user and pet
      final userId = await TestDatabase.seedUser(db);
      final petId = await TestDatabase.seedLittleGuy(db, userId: userId);

      // Update hunger level to 0.75
      await petStatsDB.updatePetStat(petId, 'hunger_level', 0.75);
      final hunger = await petStatsDB.getPetStat(petId, 'hunger_level');
      expect(hunger, 0.75);

      // Update hygiene level to 0.25
      await petStatsDB.updatePetStat(petId, 'hygiene_level', 0.25);
      final hygiene = await petStatsDB.getPetStat(petId, 'hygiene_level');
      expect(hygiene, 0.25);

      // Update enjoyment level to 1.0
      await petStatsDB.updatePetStat(petId, 'enjoyment_level', 1.0);
      final enjoyment = await petStatsDB.getPetStat(petId, 'enjoyment_level');
      expect(enjoyment, 1.0);
    });

    test('If stat value is out of bounds, it rounds it up to 0, or down to 1', () async {
      // Insert test user and pet
      final userId = await TestDatabase.seedUser(db);
      final petId = await TestDatabase.seedLittleGuy(db, userId: userId);

      // Update hunger level to -0.5 (should round up to 0)
      await petStatsDB.updatePetStat(petId, 'hunger_level', -0.5);
      final hunger = await petStatsDB.getPetStat(petId, 'hunger_level');
      expect(hunger, 0.0);

      // Update hygiene level to 1.5 (should round down to 1)
      await petStatsDB.updatePetStat(petId, 'hygiene_level', 1.5);
      final hygiene = await petStatsDB.getPetStat(petId, 'hygiene_level');
      expect(hygiene, 1.0);
    });

    test('Throws an exception if trying to update a stat for a pet id that doesnt exist',() async {
      expect(
        () => petStatsDB.updatePetStat(999, 'hunger_level', 1), throwsA(isA<Exception>())
      );
    });

    test('Throws an exception if trying to update a stat that doesnt exist', () async {
      expect(
        () => petStatsDB.updatePetStat(1, 'unknown_level', 1), throwsA(isA<Exception>())
      );
    });
  });

  // test getLastOnlineByUserId
  group('getLastOnlineByUserId', (){
    test('Returns the correct last online time', () async{
      String lastOnline = DateTime.now().toUtc().toIso8601String();
      await TestDatabase.seedUser(db, lastOnline: lastOnline);

      String? retrievedLastOnline = await petStatsDB.getLastOnlineByUserId(1);
      expect(retrievedLastOnline, lastOnline);
    });


  });

  // test updateLastOnlineByUserId

  // test _loadPetStats()
  group('loadPetsStats', () {
    
  });

  // test getFoodByUserId

  // test useFood

}