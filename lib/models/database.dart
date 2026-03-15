import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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

  /* route table info:
   - all coordinates are stored using decimal degrees
  */
    await db.execute('''
        CREATE TABLE route (
          route_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          route_name TEXT NOT NULL,
          route_start_coordinate_lat NUMERIC NOT NULL,
          route_start_coordinate_lon NUMERIC NOT NULL,
          route_end_coordinate_lat NUMERIC NOT NULL,
          route_end_coordinate_lon NUMERIC NOT NULL,
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
        price INTEGER NOT NULL CHECK (price >= 0)
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
          FOREIGN KEY (item_id) REFERENCES item(item_id)
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

Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
