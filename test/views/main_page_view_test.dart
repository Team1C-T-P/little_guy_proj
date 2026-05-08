import 'package:flutter_flame_playground/models/pet_maintainance_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/test_database.dart';
import 'package:flutter_flame_playground/utils/stat_degradation_service.dart';

void main() {
  late Database db;
  late PetStatsDatabase petStatsDB;
  late StatDegradation statDegradation;
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

    test('Throws an exception if trying to update a stat for a pet id that does not exist',() async {
      expect(
        () => petStatsDB.updatePetStat(999, 'hunger_level', 1), throwsA(isA<Exception>())
      );
    });

    test('Throws an exception if trying to update a stat that does not exist', () async {
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

    test('Return error if the user is not found', () async{
      expect(
        () => petStatsDB.getLastOnlineByUserId(999),
        throwsA(isA<Exception>()),
      );
    });
  });

  // test updateLastOnlineByUserId
  group('updateLastOnlineByUserId', () {
    test('Updates the isoDate correctly', () async {
      final userId = await TestDatabase.seedUser(db);
      String lastOnline = DateTime.now().toUtc().toIso8601String();
      
      await petStatsDB.updateLastOnlineByUserId(userId, lastOnline);
      final updatedLastOnline = petStatsDB.getLastOnlineByUserId(userId);
      expect(updatedLastOnline, completion(lastOnline));
    });

    test('Throws an exception if trying to update last online for a user id that does not exist', () async {
      String lastOnline = DateTime.now().toUtc().toIso8601String();
      expect(
        () => petStatsDB.updateLastOnlineByUserId(999, lastOnline),
        throwsA(isA<Exception>()),
      );
    });

    test('Throws an exception if trying to update last online with an invalid isoDate format', () async {
      final userId = await TestDatabase.seedUser(db);
      String invalidIsoDate = 'not an iso date';
      expect(
        () => petStatsDB.updateLastOnlineByUserId(userId, invalidIsoDate),
        throwsA(isA<Exception>()),
      );
    });

  });  

  // test degradeStats()
  group('degradeStats', () {
    test('Does not degrade stats if last online was less than 2 hours ago', () async {
      final userId = await TestDatabase.seedUser(db, lastOnline: DateTime.now().toUtc().toIso8601String());
      final petId = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 50, hungerLevel: 50, enjoymentLevel: 50);
      statDegradation = StatDegradation(petStatsDB: petStatsDB, userID: userId, petID: petId);

      await statDegradation.degradeStats();

      final hunger = await petStatsDB.getPetStat(petId, 'hunger_level');
      final hygiene = await petStatsDB.getPetStat(petId, 'hygiene_level');
      final enjoyment = await petStatsDB.getPetStat(petId, 'enjoyment_level');

      expect(hunger, 0.5);
      expect(hygiene, 0.5);
      expect(enjoyment, 0.5);
    });

    test('Degrades stats correctly based on hours since last online', () async {
      final userId = await TestDatabase.seedUser(db, lastOnline: DateTime.now().toUtc().subtract(const Duration(hours: 4)).toIso8601String());
      final petId = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 50, hungerLevel: 50, enjoymentLevel: 50);
      statDegradation = StatDegradation(petStatsDB: petStatsDB, userID: userId, petID: petId);

      await statDegradation.degradeStats();

      final hunger = await petStatsDB.getPetStat(petId, 'hunger_level');
      final hygiene = await petStatsDB.getPetStat(petId, 'hygiene_level');
      final enjoyment = await petStatsDB.getPetStat(petId, 'enjoyment_level');

      // With 4 hours since last online, decay should be 0.1 * (4/2) = 0.2
      expect(hunger, 0.3); 
      expect(hygiene, 0.3); 
      expect(enjoyment, 0.3); 
    });
    
    test('Degrades stats to a minimum of 0', () async {
      final userId = await TestDatabase.seedUser(db, lastOnline: DateTime.now().toUtc().subtract(const Duration(hours: 10)).toIso8601String());
      final petId = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 10, hungerLevel: 10, enjoymentLevel: 10);
      statDegradation = StatDegradation(petStatsDB: petStatsDB, userID: userId, petID: petId);

      await statDegradation.degradeStats();

      final hunger = await petStatsDB.getPetStat(petId, 'hunger_level');
      final hygiene = await petStatsDB.getPetStat(petId, 'hygiene_level');
      final enjoyment = await petStatsDB.getPetStat(petId, 'enjoyment_level');

      // With 10 hours since last online, decay should be 0.1 * (10/2) = 0.5
      // Stats should degrade to a minimum of 0
      expect(hunger, 0.0); 
      expect(hygiene, 0.0); 
      expect(enjoyment, 0.0); 
    });

    test('Updates last online time after degrading stats', () async {
      final userId = await TestDatabase.seedUser(db, lastOnline: DateTime.now().toUtc().subtract(const Duration(hours: 4)).toIso8601String());
      final petId = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 50, hungerLevel: 50, enjoymentLevel: 50);
      statDegradation = StatDegradation(petStatsDB: petStatsDB, userID: userId, petID: petId);

      await statDegradation.degradeStats();

      final updatedLastOnline = await petStatsDB.getLastOnlineByUserId(userId);
      final updatedLastOnlineDateTime = DateTime.parse(updatedLastOnline!);
      final now = DateTime.now().toUtc();

      // Check that the updated last online time is within a minute
      expect(updatedLastOnlineDateTime.isAfter(now.subtract(const Duration(minutes: 1))), true);
      expect(updatedLastOnlineDateTime.isBefore(now.add(const Duration(minutes: 1))), true);
    });

    test('Throws an error if user id does not exist', () async {
      statDegradation = StatDegradation(petStatsDB: petStatsDB, userID: 999, petID: 1);
      expect(
        () => statDegradation.degradeStats(),
        throwsA(isA<Exception>()),
      );
    });

    test('Throws an error if pet id does not exist', () async {
      final userId = await TestDatabase.seedUser(db);
      statDegradation = StatDegradation(petStatsDB: petStatsDB, userID: userId, petID: 999);
      expect(
        () => statDegradation.degradeStats(),
        throwsA(isA<Exception>()),
      );
    });

    test('Throws an error if last online time is after current time', () async {
      final userId = await TestDatabase.seedUser(db, lastOnline: DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String());
      final petId = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 50, hungerLevel: 50, enjoymentLevel: 50);
      statDegradation = StatDegradation(petStatsDB: petStatsDB, userID: userId, petID: petId);

      expect(
        () => statDegradation.degradeStats(),
        throwsA(isA<Exception>()),
      );
    });

  });

  // test getFoodByUserId
  group('getFoodByUserId', () {
    test('Returns the correct item ids, quantity, and the item path for a given user id', () async {
      final userId = await TestDatabase.seedUser(db);
      final foodIdOne = await TestDatabase.seedFood(db);
      final foodIdTwo = await TestDatabase.seedFood(db, name: 'Pasta', imagePath: 'assets/images/food/Pasta.png');
      await TestDatabase.seedInventory(db, userId: userId, itemId: foodIdOne, quantity: 5);
      await TestDatabase.seedInventory(db, userId: userId, itemId: foodIdTwo, quantity: 3);

      final food = await inventoryDB.getFoodByUserId(userId);
      expect(food.length, 2);
      expect(food[0]['item_id'], foodIdOne);
      expect(food[0]['quantity'], 5);
      expect(food[0]['image_path'], 'assets/images/food/bread.png');
      expect(food[1]['item_id'], foodIdTwo);
      expect(food[1]['quantity'], 3);
      expect(food[1]['image_path'], 'assets/images/food/Pasta.png');
    });

    test('Returns an empty list if the user has no food in their inventory', () async {
      final userId = await TestDatabase.seedUser(db);
      final food = await inventoryDB.getFoodByUserId(userId);
      expect(food, isEmpty);
    });

    test('Throws an exception if the user id does not exist', () async {
      expect(
        () => inventoryDB.getFoodByUserId(999),
        throwsA(isA<Exception>()),
      );
    });
  });

  // test useFood
  group('useFood', () {
    test('Decreases the quantity of the specified food item in the users inventory by 1', () async {
      final userId = await TestDatabase.seedUser(db);
      final foodIdOne = await TestDatabase.seedFood(db);
      final foodIdTwo = await TestDatabase.seedFood(db, name: 'Pasta', imagePath: 'assets/images/food/Pasta.png');

      await TestDatabase.seedInventory(db, userId: userId, itemId: foodIdOne, quantity: 5);
      await TestDatabase.seedInventory(db, userId: userId, itemId: foodIdTwo, quantity: 3);

      await inventoryDB.useFood(foodIdOne, userId);
      await inventoryDB.useFood(foodIdTwo, userId);
      await inventoryDB.useFood(foodIdTwo, userId);

      final food = await inventoryDB.getFoodByUserId(userId);

      expect(food[0]['quantity'], 4);
      expect(food[1]['quantity'], 1);
    });
    
    test('Does not decrease quantity if the food item quantity is already 0', () async {
      final userId = await TestDatabase.seedUser(db);
      final foodId = await TestDatabase.seedFood(db);
      await TestDatabase.seedInventory(db, userId: userId, itemId: foodId, quantity: 0);

      await inventoryDB.useFood(foodId, userId);

      final food = await inventoryDB.getFoodByUserId(userId);
      
      expect(food[0]['quantity'], 0);
    });

    test('Throws an exception if trying to use a food item for a user id that does not exist', () async {
      final foodId = await TestDatabase.seedFood(db);

      expect(
        () => inventoryDB.useFood(foodId, 999),
        throwsA(isA<Exception>()),
      );
    });

    test('Throws an exception if trying to use a food item that does not exist', () async {
      final userId = await TestDatabase.seedUser(db);

      expect(
        () => inventoryDB.useFood(999, userId),
        throwsA(isA<Exception>()),
      );
    });
  });

}