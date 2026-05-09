import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_flame_playground/models/database.dart';

Future<void> checkAndUnlockTrailBlazer(BuildContext context, int userId) async {
  final prefs = await SharedPreferences.getInstance();
  final alreadyClaimed = prefs.getBool('trailBlazerClaimed') ?? false;
  if (alreadyClaimed) return;

  final db = await AppDatabase.instance.database;
  final count =
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM route WHERE user_id = ?', [
          userId,
        ]),
      ) ??
      0;

  if (count >= 1) {
    await prefs.setBool('trailBlazerClaimed', true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trail Blazer achievement unlocked! You saved your first route!',
          ),
        ),
      );
    }
  }
}
