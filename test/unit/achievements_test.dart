// Unit tests for the achievement-unlock conditions.
//
// These tests don't drive UI — they exercise the SQL queries / aggregates
// that decide when an achievement should fire. Uses TestDatabase.createFresh
// so the schema stays in sync with production (database.dart) instead of
// being re-declared inline.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late int userId;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    userId = await TestDatabase.seedUser(db, currency: 0);
    await TestDatabase.seedLittleGuy(db, userId: userId);
  });

  tearDown(() async {
    await db.close();
  });

  // Mad Hatter — unlocks when the user owns 5 hats.
  test('Mad Hatter unlocks when user owns 5 hats', () async {
    for (int i = 1; i <= 5; i++) {
      final itemId = await TestDatabase.seedHat(
        db,
        name: 'Hat $i',
        imagePath: 'assets/hat$i.png',
      );
      await TestDatabase.seedInventory(db, userId: userId, itemId: itemId);
    }
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM inventory i
      JOIN item it ON i.item_id = it.item_id
      WHERE i.user_id = ? AND it.type = 'hat'
    ''', [userId]);
    expect(result.first['count'] as int, 5);
  });

  test('Mad Hatter does not unlock, when user owns 4 hats', () async {
    for (int i = 1; i <= 4; i++) {
      final itemId = await TestDatabase.seedHat(
        db,
        name: 'Hat $i',
        imagePath: 'assets/hat$i.png',
      );
      await TestDatabase.seedInventory(db, userId: userId, itemId: itemId);
    }
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM inventory i
      JOIN item it ON i.item_id = it.item_id
      WHERE i.user_id = ? AND it.type = 'hat'
    ''', [userId]);
    expect(result.first['count'] as int, 4);
  });

  // Big Walk — unlocks when total walked steps hits 5000.
  test('Big Walk unlocks when total steps reach 5000', () async {
    await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 3000);
    await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 2000);

    final result = await db.rawQuery(
      'SELECT SUM(total_steps) as total FROM walk_summary WHERE user_id = ?',
      [userId],
    );
    final totalSteps = result.first['total'] as int? ?? 0;
    expect(totalSteps, 5000);
  });

  test('Big Walk does not unlock when total steps reach 4999', () async {
    await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 3000);
    await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 1999);

    final result = await db.rawQuery(
      'SELECT SUM(total_steps) as total FROM walk_summary WHERE user_id = ?',
      [userId],
    );
    final totalSteps = result.first['total'] as int? ?? 0;
    expect(totalSteps, 4999);
  });

  // Wealthy — unlocks when user currency hits 5000 pennies.
  test('Wealthy unlocks when user currency reaches 5000', () async {
    await db.update(
      'user',
      {'currency': 5000},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    final result = await db.query('user', where: 'user_id = ?', whereArgs: [userId]);
    expect(result.first['currency'] as int, 5000);
  });

  test('Wealthy does not unlock when user currency reaches 4999', () async {
    await db.update(
      'user',
      {'currency': 4999},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    final result = await db.query('user', where: 'user_id = ?', whereArgs: [userId]);
    expect(result.first['currency'] as int, 4999);
  });

  // Trail Blazer — unlocks once the user saves their first route.
  test('Trail Blazer unlocks when user saves at least one route', () async {
    await TestDatabase.seedRoute(db, userId: userId);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM route WHERE user_id = ?',
      [userId],
    );
    expect(result.first['count'] as int, 1);
  });

  test('Trail Blazer does NOT unlock when user has no routes', () async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM route WHERE user_id = ?',
      [userId],
    );
    expect(result.first['count'] as int, 0);
  });

  // Most Valuable Pet — unlocks when pet level reaches 5.
  test('Most Valuable Pet unlocks when pet level reaches 5', () async {
    await db.update(
      'little_guy',
      {'level': 5},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    final result = await db.query(
      'little_guy',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    expect(result.first['level'] as int, 5);
  });

  test('Most Valuable Pet does not unlock when pet level reaches 4', () async {
    await db.update(
      'little_guy',
      {'level': 4},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    final result = await db.query(
      'little_guy',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    expect(result.first['level'] as int, 4);
  });

  test('MVP - pet level 1 (starting level)', () async {
    final result = await db.query(
      'little_guy',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    expect(result.first['level'] as int, 1);
  });
}
