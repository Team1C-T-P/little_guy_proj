import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestDatabase {
  TestDatabase._();
  // one time ffi intialisation
  static void init() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // return new empty db with full schema, allows test to start with clean slate
  static Future<Database> createFresh() async {
    // Mirror production version so any version-dependent code path
    // (e.g. db.getVersion checks, future onUpgrade-driven seeding)
    // sees the same value tests do.
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 2, onCreate: _createSchema),
    );
    return db;
  }

  // schema to mirror database.dart
  static Future<void> _createSchema(Database db, int version) async {
    // user table
    await db.execute('''
      CREATE TABLE user (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name TEXT NOT NULL,
        currency INTEGER NOT NULL CHECK (currency >= 0),
        last_online TEXT
      );
    ''');

    // routes table
    await db.execute('''
        CREATE TABLE route (
          route_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          route_name TEXT NOT NULL,
          route_path TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
        );
      ''');

    // little guy table — matches production schema (includes level/xp)
    await db.execute('''
        CREATE TABLE little_guy (
          little_guy_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          little_guy_name TEXT NOT NULL,
          hygiene_level INTEGER NOT NULL CHECK (hygiene_level BETWEEN 0 AND 100),
          hunger_level INTEGER NOT NULL CHECK (hunger_level BETWEEN 0 AND 100),
          enjoyment_level INTEGER NOT NULL CHECK (enjoyment_level BETWEEN 0 AND 100),
          level INTEGER NOT NULL DEFAULT 1,
          xp INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
        );
      ''');

    // item table
    await db.execute('''
      CREATE TABLE item (
        item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        image_path TEXT NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity >= 0),
        price INTEGER NOT NULL CHECK (price >= 0),
        type TEXT NOT NULL
      );
    ''');

    // user inventory table
    await db.execute('''
        CREATE TABLE inventory (
          user_id INTEGER NOT NULL,
          item_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL CHECK (quantity >= 0),
          PRIMARY KEY (user_id, item_id),
          FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
          FOREIGN KEY (item_id) REFERENCES item(item_id) ON DELETE CASCADE
        );
      ''');

    // little guy clothing
    await db.execute('''
      CREATE TABLE little_guy_wearing (
        little_guy_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        PRIMARY KEY (little_guy_id, item_id),
        FOREIGN KEY (little_guy_id) REFERENCES little_guy(little_guy_id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES item(item_id) ON DELETE CASCADE
      );
    ''');

    // goals table
    await db.execute('''
      CREATE TABLE goal (
        goal_id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_goal INTEGER NOT NULL CHECK (target_goal > 0),
        target_deadline TEXT NOT NULL,
        min_allowed_value INTEGER NOT NULL CHECK (min_allowed_value >= 0),
        is_recurring BOOLEAN NOT NULL DEFAULT 0
      );
    ''');

    // user goals table
    await db.execute('''
      CREATE TABLE user_goal (
        user_id INTEGER NOT NULL,
        goal_id INTEGER NOT NULL,
        current_progress INTEGER NOT NULL CHECK (current_progress >= 0),
        week_start_date TEXT NOT NULL,
        week_end_date TEXT NOT NULL,
        reward_claimed INT NOT NULL CHECK (reward_claimed IN (0, 1)),
        PRIMARY KEY (user_id, goal_id),
        FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
        FOREIGN KEY (goal_id) REFERENCES goal(goal_id) ON DELETE CASCADE
      );
    ''');

    // rewards table
    await db.execute('''
      CREATE TABLE reward (
        reward_id INTEGER PRIMARY KEY AUTOINCREMENT,
        reward_tier VARCHAR(4) NOT NULL CHECK (reward_tier IN ('low','mid','high','pers')),
        reward_currency INTEGER NOT NULL CHECK (reward_currency >= 0)
      );
    ''');

    // goal rewards
    await db.execute('''
      CREATE TABLE goal_reward (
        goal_id INTEGER NOT NULL,
        reward_id INTEGER NOT NULL,
        PRIMARY KEY (goal_id, reward_id),
        FOREIGN KEY (goal_id) REFERENCES goal(goal_id) ON DELETE CASCADE,
        FOREIGN KEY (reward_id) REFERENCES reward(reward_id) ON DELETE CASCADE
      );
    ''');

    // walk summaries table
    await db.execute('''
      CREATE TABLE walk_summary(
      summary_id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      walk_date TEXT NOT NULL,
      total_steps INTEGER NOT NULL,
      start_lat REAL,
      start_lng REAL,
      end_lat REAL,
      end_lng REAL,
      FOREIGN KEY(user_id) REFERENCES user(user_id)
      );
    ''');

    // achievement table — mirrors production schema in database.dart
    await db.execute('''
      CREATE TABLE achievement (
        achievement_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        target_value INTEGER,
        type TEXT NOT NULL
      );
    ''');

    // user_achievement table — tracks which achievements each user has unlocked
    await db.execute('''
      CREATE TABLE user_achievement (
        user_id INTEGER NOT NULL,
        achievement_id INTEGER NOT NULL,
        unlocked_at TEXT NOT NULL,
        progress INTEGER DEFAULT 0,
        PRIMARY KEY (user_id, achievement_id),
        FOREIGN KEY (user_id) REFERENCES user(user_id),
        FOREIGN KEY (achievement_id) REFERENCES achievement(achievement_id)
      );
    ''');
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
