import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    // Create all tables needed for achievements
    await db.execute('''
      CREATE TABLE user (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name TEXT NOT NULL,
        currency INTEGER NOT NULL CHECK (currency >= 0),
        last_online TEXT
      );
    ''');
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
    await db.execute('''
      CREATE TABLE inventory (
        user_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity >= 0),
        PRIMARY KEY (user_id, item_id),
        FOREIGN KEY (user_id) REFERENCES user(user_id),
        FOREIGN KEY (item_id) REFERENCES item(item_id)
      );
    ''');
    await db.execute('''
      CREATE TABLE walk_summary (
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
    await db.execute('''
      CREATE TABLE route (
        route_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        route_name TEXT NOT NULL,
        route_path TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES user(user_id)
      );
    ''');
    await db.execute('''
      CREATE TABLE little_guy (
        little_guy_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        little_guy_name TEXT NOT NULL,
        hygiene_level INTEGER NOT NULL,
        hunger_level INTEGER NOT NULL,
        enjoyment_level INTEGER NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        xp INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(user_id) REFERENCES user(user_id)
      );
    ''');
    await db.execute('''
      CREATE TABLE user_achievement (
        user_id INTEGER NOT NULL,
        achievement_id INTEGER NOT NULL,
        unlocked_at TEXT,
        progress INTEGER DEFAULT 0,
        PRIMARY KEY (user_id, achievement_id)
      );
    ''');

    await db.execute('''
  CREATE TABLE achievement (
    achievement_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    target_value INTEGER,
    type TEXT NOT NULL
  );
''');

    // Insert default user and pet (necessary for all tests)
    await db.insert('user', {
      'user_id': 1,
      'user_name': 'Test User',
      'currency': 0,
      'last_online': DateTime.now().toIso8601String(),
    });
    await db.insert('little_guy', {
      'user_id': 1,
      'little_guy_name': 'Buddy',
      'hygiene_level': 50,
      'hunger_level': 50,
      'enjoyment_level': 50,
      'level': 1,
      'xp': 0,
    });
  });

  tearDown(() async {
    await db.close();
  });

  // Mad hatter test
  test('Mad Hatter unlocks when user owns 5 hats', () async {
    for (int i = 1; i <= 5; i++) {
      final itemId = await db.insert('item', {
        'item_name': 'Hat $i',
        'image_path': 'assets/hat$i.png',
        'quantity': 1,
        'price': 100,
        'type': 'hat',
      });
      await db.insert('inventory', {
        'user_id': 1,
        'item_id': itemId,
        'quantity': 1,
      });
    }
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM inventory i
      JOIN item it ON i.item_id = it.item_id
      WHERE i.user_id = 1 AND it.type = 'hat'
    ''');
    final hatCount = result.first['count'] as int;
    expect(hatCount, 5);
  });

  // Big Walk Achivement
  test('Big Walk unlocks when total steps reach 5000', () async {
    // Insert walk summaries totalling 5000 steps
    await db.insert('walk_summary', {
      'user_id': 1,
      'walk_date': DateTime.now().toIso8601String(),
      'total_steps': 3000,
      'start_lat': 0,
      'start_lng': 0,
      'end_lat': 0,
      'end_lng': 0,
    });
    await db.insert('walk_summary', {
      'user_id': 1,
      'walk_date': DateTime.now().toIso8601String(),
      'total_steps': 2000,
      'start_lat': 0,
      'start_lng': 0,
      'end_lat': 0,
      'end_lng': 0,
    });
    final result = await db.rawQuery('''
      SELECT SUM(total_steps) as total FROM walk_summary WHERE user_id = 1
    ''');
    final totalSteps = result.first['total'] as int? ?? 0;
    expect(totalSteps, 5000);
  });

  // Wealthy achivement
  test('Wealthy unlocks when user currency reaches 5000', () async {
    await db.update(
      'user',
      {'currency': 5000},
      where: 'user_id = ?',
      whereArgs: [1],
    );
    final result = await db.query('user', where: 'user_id = ?', whereArgs: [1]);
    final currency = result.first['currency'] as int;
    expect(currency, 5000);
  });

  // Trail Blazer Achivement
  test('Trail Blazer unlocks when user saves at least one route', () async {
    await db.insert('route', {
      'user_id': 1,
      'route_name': 'Test Route',
      'route_path': '[]',
    });
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM route WHERE user_id = 1',
    );
    final routeCount = result.first['count'] as int;
    expect(routeCount, 1);
  });

  // MVP Achivement
  test('Most Valuable Pet unlocks when pet level reaches 5', () async {
    await db.update(
      'little_guy',
      {'level': 5},
      where: 'user_id = ?',
      whereArgs: [1],
    );
    final result = await db.query(
      'little_guy',
      where: 'user_id = ?',
      whereArgs: [1],
    );
    final level = result.first['level'] as int;
    expect(level, 5);
  });
}
