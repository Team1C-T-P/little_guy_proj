import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'little_guy.db');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    /* user table info:
      - currency is stored in pennies, so when used divide by 100, and updating multiply by 100
      - last_online is stored in the ISO-8601 format, doing this through text
    */
    await db.execute('''
      CREATE TABLE user (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name TEXT NOT NULL,
        currency INTEGER NOT NULL CHECK (currency >= 0),
        last_online TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE friend (
        user_id INTEGER NOT NULL,
        friend_id INTEGER NOT NULL CHECK (friend_id != user_id),
        PRIMARY KEY (user_id, friend_id),
        FOREIGN KEY (user_id) REFERENCES user(user_id)
        FOREIGN KEY (friend_id) REFERENCES user(user_id)
      );
    ''');

    /* route table info:
   - all coordinates are stored using decimal degrees
  */
    await db.execute('''
        CREATE TABLE route (
          route_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          route_name TEXT NOT NULL,
          route_start_coordinate_lat NUMERIC NOT NULL CHECK (route_start_coordinate_lat >= -90 AND route_start_coordinate_lat <= 90),
          route_start_coordinate_lon NUMERIC NOT NULL CHECK (route_start_coordinate_lon >= -180 AND route_start_coordinate_lon <= 180),
          route_end_coordinate_lat NUMERIC NOT NULL CHECK (route_end_coordinate_lat >= -90 AND route_end_coordinate_lat <= 90),
          route_end_coordinate_lon NUMERIC NOT NULL CHECK (route_end_coordinate_lon >= -180 AND route_end_coordinate_lon <= 180),
          FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
          );
      ''');

    /* little_guy table info:
      - hygiene, hunger and enjoyment levels are stored as integers from 0 to 100, when used this needs to be divided by 100 
    */
    await db.execute('''
        CREATE TABLE little_guy (
          little_guy_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          little_guy_name TEXT NOT NULL,
          hygiene_level INTEGER NOT NULL CHECK (hygiene_level BETWEEN 0 AND 100),
          hunger_level INTEGER NOT NULL CHECK (hunger_level BETWEEN 0 AND 100),
          enjoyment_level INTEGER NOT NULL CHECK (enjoyment_level BETWEEN 0 AND 100),
          FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
        );
      ''');

    /* item table info:
      - price is stored in pennies, so when used divide by 100, and updating multiply by 100
      - quantity will usually be 1, needed for stackable items e.g. food
    */
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

    /* inventory table info:
      - quantity will usually be 1, needed for stackable items e.g. food
    */
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

    await db.execute('''
      CREATE TABLE little_guy_wearing (
        little_guy_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        PRIMARY KEY (little_guy_id, item_id),
        FOREIGN KEY (little_guy_id) REFERENCES little_guy(little_guy_id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES inventory(item_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE goal (
        goal_id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_goal INTEGER NOT NULL CHECK (target_goal > 0),
        target_deadline TEXT NOT NULL,
        min_allowed_value INTEGER NOT NULL CHECK (min_allowed_value >= 0),
        is_recurring BOOLEAN NOT NULL DEFAULT 0
      );
    ''');

    /* User_goal table info:
    - current_progress is number of steps taken
    - week start and end date the ISO-8601 format, doing this through text
    - reward_claimed is stored as an integer for boolean
    */
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

    // reward_tier - has four possible tier levels:
    // low level - 2K steps = 20c
    // mid level - 5K steps = 50c
    // high level - 10K steps = 100c
    // personal goal (user-defined) - ?K steps = 50c?
    // tier linked to goal, if user chose low/mid/high no need for user input

    await db.execute('''
      CREATE TABLE reward (
        reward_id INTEGER PRIMARY KEY AUTOINCREMENT,
        reward_tier VARCHAR(4) NOT NULL CHECK (reward_tier IN ('low','mid','high','pers')),
        reward_currency INTEGER NOT NULL CHECK (reward_currency >= 0)
      );
    ''');

    await db.execute('''
      CREATE TABLE goal_reward (
        goal_id INTEGER NOT NULL,
        reward_id INTEGER NOT NULL,
        PRIMARY KEY (goal_id, reward_id),
        FOREIGN KEY (goal_id) REFERENCES goal(goal_id) ON DELETE CASCADE,
        FOREIGN KEY (reward_id) REFERENCES reward(reward_id) ON DELETE CASCADE
      );
    ''');
  }

  // create default to user pet and item to initialize db
  Future<void> initializeDefaultData() async {
    final db = await database;

    // Check if already initialized
    final users = await db.query('user');
    if (users.isNotEmpty) return;

    // Create user
    await db.insert('user', {
      'user_name': 'Default User',
      'currency': 1000,
      'last_online': DateTime.now().toIso8601String(),
    });

    // Create little guy
    await db.insert('little_guy', {
      'user_id': 1,
      'little_guy_name': 'Buddy',
      'hygiene_level': 100,
      'hunger_level': 100,
      'enjoyment_level': 100,
    });

    // Auto-detect and add hats
    await _autoAddHatsFromAssets();
  }

  Future<void> _autoAddHatsFromAssets() async {
    final db = await database;

    // Scan for all images in hats and food
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final hatImages = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/images/hats/') &&
              (path.endsWith('.png') || path.endsWith('.jpg')),
        )
        .toList();

    final foodImages = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/images/food') &&
              (path.endsWith('.png') || path.endsWith('.jpeg')),
        )
        .toList();

    // Price mapping for hats
    final hatPrices = {
      'band': 100,
      'cheese': 150,
      'deeevilhat': 300,
      'mushroomcap': 200,
      'pompom': 250,
      'sleepyslime': 400,
      'sunhat': 180,
      'tophat': 350,
      'witchhat': 500,
    };

    // Price mapping for food
    final foodPrices = {'bread': 100};

    // Add hats
    for (var imagePath in hatImages) {
      final fileName = imagePath.split('/').last.split('.').first.toLowerCase();
      final itemName = _formatItemName(fileName);
      final price = hatPrices[fileName] ?? 200; // Default 200 if not in map

      await db.insert('item', {
        'item_name': itemName,
        'image_path': imagePath,
        'quantity': 1,
        'price': price,
        'type': 'hat',
      });
    }

    // Add food
    for (var imagePath in foodImages) {
      final fileName = imagePath.split('/').last.split('.').first.toLowerCase();
      final itemName = _formatItemName(fileName);
      final price = foodPrices[fileName] ?? 100; // Default 100 for food

      await db.insert('item', {
        'item_name': itemName,
        'image_path': imagePath,
        'quantity': 1,
        'price': price,
        'type': 'food',
      });
    }
  }

  String _formatItemName(String fileName) {
    // Convert filename to nice name
    final formatted = fileName
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
        .trim();

    if (formatted.isEmpty) return fileName;

    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}
