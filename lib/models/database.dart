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
    await db.execute('''
      CREATE TABLE user (
        user_id     INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name   TEXT NOT NULL
        little_guy_name VARCHAR(20)
        hygiene_level INTEGER NOT NULL
        hunger_level INTEGER NOT NULL
        enjoyment_level INTEGER NOT NULL
      );
    ''');

  await db.execute('''
      CREATE TABLE little_guy (
        little_guy_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id         INTEGER NOT NULL,
        little_guy_name TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user(user_id)
      );
    ''');

  await db.execute('''
      CREATE TABLE wearable_item (
        item_id     INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name   TEXT NOT NULL,
        image_path  TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE little_guy_wearing (
        little_guy_id   INTEGER NOT NULL,
        item_id         INTEGER NOT NULL,
        PRIMARY KEY (little_guy_id, item_id),
        FOREIGN KEY (little_guy_id) REFERENCES little_guy(little_guy_id),
        FOREIGN KEY (item_id)       REFERENCES wearable_item(item_id)
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
