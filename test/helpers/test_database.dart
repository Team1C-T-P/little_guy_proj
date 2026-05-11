import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';

class TestDatabase {
  TestDatabase._();
  // one time ffi intialisation
  static void init() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Returns a fresh empty in-memory DB built with the *production* schema
  // function (AppDatabase.createDB). Using production's own DDL here means
  // tests automatically inherit any schema change — no parallel copy to
  // keep in sync, and `_createDB` itself is now covered by every test.
  static Future<Database> createFresh() async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: AppDatabase.instance.createDB,
      ),
    );
    return db;
  }

  // seed helpers, populating tables

  static Future<int> seedUser(
    Database db, {
    String name = 'Test User',
    int currency = 1000, // 10.00 in display units
    String? lastOnline,
  }) async {
    return await db.insert('user', {
      'user_name': name,
      'currency': currency,
      'last_online': lastOnline ?? '2026-01-01T00:00:00Z',
    });
  }

  static Future<int> seedLittleGuy(
    Database db, {
    required int userId,
    String name = 'Buddy',
    int hygieneLevel = 50,
    int hungerLevel = 50,
    int enjoymentLevel = 50,
    int level = 1,
    int xp = 0,
  }) async {
    return await db.insert('little_guy', {
      'user_id': userId,
      'little_guy_name': name,
      'hygiene_level': hygieneLevel,
      'hunger_level': hungerLevel,
      'enjoyment_level': enjoymentLevel,
      'level': level,
      'xp': xp,
    });
  }

  static Future<int> seedItem(
    Database db, {
    required String name,
    required String imagePath,
    required int price, // in pennies
    required String type, // 'hat' | 'food'
    int quantity = 1,
  }) async {
    return await db.insert('item', {
      'item_name': name,
      'image_path': imagePath,
      'quantity': quantity,
      'price': price,
      'type': type,
    });
  }

  static Future<int> seedHat(
    Database db, {
    String name = 'Top Hat',
    String imagePath = 'assets/images/hats/tophat.png',
    int price = 100, // in pennies
  }) async {
    return await seedItem(
      db,
      name: name,
      imagePath: imagePath,
      price: price,
      type: 'hat',
    );
  }

  static Future<int> seedFood(
    Database db, {
    String name = 'Bread',
    String imagePath = 'assets/images/food/bread.png',
    int price = 100, // in pennies
  }) async {
    return await seedItem(
      db,
      name: name,
      imagePath: imagePath,
      price: price,
      type: 'food',
    );
  }

  static Future<void> seedInventory(
    Database db, {
    required int userId,
    required int itemId,
    int quantity = 1,
  }) async {
    await db.insert('inventory', {
      'user_id': userId,
      'item_id': itemId,
      'quantity': quantity,
    });
  }

  static Future<void> seedWearing(
    Database db, {
    required int littleGuyId,
    required int itemId,
  }) async {
    await db.insert('little_guy_wearing', {
      'little_guy_id': littleGuyId,
      'item_id': itemId,
    });
  }

  static Future<int> seedRoute(
    Database db, {
    required int userId,
    String name = 'Test Route',
    String routePath = '[]',
  }) async {
    return await db.insert('route', {
      'user_id': userId,
      'route_name': name,
      'route_path': routePath,
    });
  }

  static Future<int> seedGoal(
    Database db, {
    int targetGoal = 5000,
    String deadline = '2026-12-31T23:59:59Z',
    int minAllowedValue = 0,
    bool isRecurring = false,
  }) async {
    return await db.insert('goal', {
      'target_goal': targetGoal,
      'target_deadline': deadline,
      'min_allowed_value': minAllowedValue,
      'is_recurring': isRecurring ? 1 : 0,
    });
  }

  static Future<void> seedUserGoal(
    Database db, {
    required int userId,
    required int goalId,
    int currentProgress = 0,
    String weekStartDate = '2026-01-01',
    String weekEndDate = '2026-01-07',
    bool rewardClaimed = false,
  }) async {
    await db.insert('user_goal', {
      'user_id': userId,
      'goal_id': goalId,
      'current_progress': currentProgress,
      'week_start_date': weekStartDate,
      'week_end_date': weekEndDate,
      'reward_claimed': rewardClaimed ? 1 : 0,
    });
    
  }

  static Future<int> seedReward(
    Database db, {
    String tier = 'mid',
    int rewardCurrency = 50, // in pennies
  }) async {
    return await db.insert('reward', {
      'reward_tier': tier,
      'reward_currency': rewardCurrency,
    });
  }

  static Future<void> seedGoalReward(
    Database db, {
    required int goalId,
    required int rewardId,
  }) async {
    await db.insert('goal_reward', {'goal_id': goalId, 'reward_id': rewardId});
  }

  static Future<int> seedWalkSummary(
    Database db, {
    required int userId,
    String? walkDate,
    int totalSteps = 0,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
  }) async {
    return await db.insert('walk_summary', {
      'user_id': userId,
      'walk_date': walkDate ?? '2026-01-01T00:00:00Z',
      'total_steps': totalSteps,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
    });
  }
}
