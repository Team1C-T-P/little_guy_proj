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
        currency INTEGER NOT NULL,
        last_online TEXT
      );
    ''');


    /* item table info:
      - hygiene, hunger and enjoyment levels are stored as integers from 0 to 100, when used this needs to be divided by 100 
    */
    await db.execute('''
        CREATE TABLE little_guy (
          little_guy_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          little_guy_name TEXT NOT NULL,
          hygiene_level INTEGER NOT NULL,
          hunger_level INTEGER NOT NULL,
          enjoyment_level INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user(user_id)
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
        quantity INTEGER NOT NULL,
        price INTEGER NOT NULL
      );
    ''');

    /* inventory table info:
      - quantity will usually be 1, needed for stackable items e.g. food
    */
    await db.execute('''
        CREATE TABLE inventory (
          user_id INTEGER NOT NULL,
          item_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          PRIMARY KEY (user_id, item_id),
          FOREIGN KEY (user_id) REFERENCES user(user_id),
          FOREIGN KEY (item_id) REFERENCES item(item_id)
        );
      ''');

    await db.execute('''
      CREATE TABLE little_guy_wearing (
        little_guy_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        PRIMARY KEY (little_guy_id, item_id),
        FOREIGN KEY (little_guy_id) REFERENCES little_guy(little_guy_id),
        FOREIGN KEY (item_id) REFERENCES wearable_item(item_id)
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
