import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  
  setUp(() async {
    TestDatabase.init();
    db = await TestDatabase.createFresh();
  });
  
  tearDown(() async {
    await db.close();
  });
  
  group('User Table Tests', () {
    test('Valid user creation with normal values', () async {
      final userId = await TestDatabase.seedUser(
        db,
        name: 'Normal User',
        currency: 1000,
        lastOnline: '2026-01-01T00:00:00Z',
      );
      
      expect(userId, greaterThan(0));
      
      final result = await db.query('user', where: 'user_id = ?', whereArgs: [userId]);
      expect(result.first['currency'], 1000);
      expect(result.first['user_name'], 'Normal User');
    });
    test('Currency at minimum value 0 (valid)', () async {
      final userId = await TestDatabase.seedUser(db, currency: 0);
      final result = await db.query('user', where: 'user_id = ?', whereArgs: [userId]);
      expect(result.first['currency'], 0);
    });
  });
  
  group('Little Guy Table Tests', () {
    late int userId;
    
    setUp(() async {
      userId = await TestDatabase.seedUser(db);
    });
    
    test('Valid little guy with normal levels (50)', () async {
      final littleGuyId = await TestDatabase.seedLittleGuy(
        db,
        userId: userId,
        hygieneLevel: 50,
        hungerLevel: 50,
        enjoymentLevel: 50,
      );
      
      final result = await db.query('little_guy', where: 'little_guy_id = ?', whereArgs: [littleGuyId]);
      expect(result.first['hygiene_level'], 50);
      expect(result.first['hunger_level'], 50);
      expect(result.first['enjoyment_level'], 50);
    });
    
    test('Hygiene level boundaries (0, 1, 99, 100)', () async {
      // Test lower boundary (0)
      var id = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 0);
      var result = await db.query('little_guy', where: 'little_guy_id = ?', whereArgs: [id]);
      expect(result.first['hygiene_level'], 0);
      
      // Test just above lower boundary (1)
      id = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 1);
      result = await db.query('little_guy', where: 'little_guy_id = ?', whereArgs: [id]);
      expect(result.first['hygiene_level'], 1);
      
      // Test just below upper boundary (99)
      id = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 99);
      result = await db.query('little_guy', where: 'little_guy_id = ?', whereArgs: [id]);
      expect(result.first['hygiene_level'], 99);
      
      // Test upper boundary (100)
      id = await TestDatabase.seedLittleGuy(db, userId: userId, hygieneLevel: 100);
      result = await db.query('little_guy', where: 'little_guy_id = ?', whereArgs: [id]);
      expect(result.first['hygiene_level'], 100);
    });
  });
  
  group('Friend Table Tests', () {
    late int userId1, userId2;
    
    setUp(() async {
      userId1 = await TestDatabase.seedUser(db, name: 'User 1');
      userId2 = await TestDatabase.seedUser(db, name: 'User 2');
    });
    
    test('Valid friendship creation', () async {
      await TestDatabase.seedFriend(db, userId: userId1, friendId: userId2);
      
      final result1 = await db.query('friend', where: 'user_id = ? AND friend_id = ?', whereArgs: [userId1, userId2]);
      final result2 = await db.query('friend', where: 'user_id = ? AND friend_id = ?', whereArgs: [userId2, userId1]);
      
      expect(result1.length, 1);
      expect(result2.length, 1);
    });
    
    test('Friend ID equals user ID (invalid - should be rejected)', () async {
      // CHECK constraint "friend_id != user_id" should reject this
      expect(
        () => db.insert('friend', {
          'user_id': userId1,
          'friend_id': userId1,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
  
  group('Item Table Tests', () {
    test('Item with minimum price (valid - 0)', () async {
      final itemId = await TestDatabase.seedItem(
        db,
        name: 'Free Item',
        imagePath: 'assets/images/free.png',
        price: 0,
        type: 'hat',
      );
      
      final result = await db.query('item', where: 'item_id = ?', whereArgs: [itemId]);
      expect(result.first['price'], 0);
    });
    
    test('Quantity boundaries', () async {
      // Quantity 0 is valid
      var id = await TestDatabase.seedItem(db, name: 'Out of Stock', imagePath: 'path', price: 100, type: 'hat', quantity: 0);
      var result = await db.query('item', where: 'item_id = ?', whereArgs: [id]);
      expect(result.first['quantity'], 0);
      
      // Quantity negative should be rejected - invalid
      expect(
        () => TestDatabase.seedItem(db, name: 'Invalid', imagePath: 'path', price: 100, type: 'hat', quantity: -1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
  group('User Goal Table Tests', () {
    late int userId, goalId;
    
    setUp(() async {
      userId = await TestDatabase.seedUser(db);
      goalId = await TestDatabase.seedGoal(db);
    });
    
    test('Valid user goal with progress', () async {
      await TestDatabase.seedUserGoal(
        db,
        userId: userId,
        goalId: goalId,
        currentProgress: 2500,
      );
      
      final result = await db.query('user_goal', where: 'user_id = ? AND goal_id = ?', whereArgs: [userId, goalId]);
      expect(result.first['current_progress'], 2500);
    });
    
    test('Current progress boundaries', () async {
      // Progress 0 is valid (minimum)
      await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 0);
      var result = await db.query('user_goal', where: 'user_id = ? AND goal_id = ?', whereArgs: [userId, goalId]);
      expect(result.first['current_progress'], 0);
      
      // Progress negative should be rejected - invalid
      expect(
        () => db.insert('user_goal', {
          'user_id': userId,
          'goal_id': goalId + 1,
          'current_progress': -1,
          'week_start_date': '2026-01-01',
          'week_end_date': '2026-01-07',
          'reward_claimed': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
  
  group('Reward Table Tests', () {
    
    test('Invalid reward tier', () async {
      expect(
        () => TestDatabase.seedReward(db, tier: 'invalid'),
        throwsA(isA<DatabaseException>()),
      );
    });
    
    test('Reward currency boundaries', () async {
      // Minimum 0
      var id = await TestDatabase.seedReward(db, rewardCurrency: 0);
      var result = await db.query('reward', where: 'reward_id = ?', whereArgs: [id]);
      expect(result.first['reward_currency'], 0);
      
      // Negative should be rejected - invalid
      expect(
        () => TestDatabase.seedReward(db, rewardCurrency: -1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
  
  group('Walk Summary Table Tests', () {
    late int userId;
    
    setUp(() async {
      userId = await TestDatabase.seedUser(db);
    });
    
    test('Valid walk summary with zero steps', () async {
      final summaryId = await TestDatabase.seedWalkSummary(
        db,
        userId: userId,
        totalSteps: 0,
      );
      
      final result = await db.query('walk_summary', where: 'summary_id = ?', whereArgs: [summaryId]);
      expect(result.first['total_steps'], 0);
    });
  });
  
  group('Composite Primary Key Tests', () {

    test('Composite key properly enforces uniqueness (inventory)', () async {
      final userId = await TestDatabase.seedUser(db);
      final itemId = await TestDatabase.seedHat(db);

      // First insert should succeed
      await TestDatabase.seedInventory(db, userId: userId, itemId: itemId);

      // Second insert with same composite key should fail - invalid
      expect(
        () => db.insert('inventory', {'user_id': userId, 'item_id': itemId, 'quantity': 1}),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('UR1 — AppDatabase.userExists', () {
    test('[TR-PRF-15] returns true when the user table has rows', () async {
      await TestDatabase.seedUser(db);

      final exists = await AppDatabase.instance.userExists(db: db);

      expect(exists, isTrue);
    });

    test('[TR-PRF-16] returns false when the user table is empty', () async {
      final exists = await AppDatabase.instance.userExists(db: db);

      expect(exists, isFalse);
    });
  });
}