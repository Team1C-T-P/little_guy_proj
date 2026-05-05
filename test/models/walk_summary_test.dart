import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.initializeDefaultData(); 
  });

  setUp(() async {
    // Hard clear the table so math counts are perfectly isolated
    final db = await AppDatabase.instance.database;
    await db.delete('walk_summary'); 
  });

  group('See Summaries (Limits and Sorting)', () {
    
    test('[TR-SUM-01] Last 10 BVA: Strictly caps query at 10 items', () async {
      for (int i = 1; i <= 12; i++) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().add(Duration(days: i)).toIso8601String(),
          'total_steps': 500,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      expect(recent.length, 10, reason: 'BVA: Failed boundary limit of 10');
    });

    test('[TR-SUM-02] Top 3 BVA: Returns highest 3 step counts descending', () async {
      final stepCounts = [100, 500, 200, 1000, 50];
      for (int steps in stepCounts) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().toIso8601String(),
          'total_steps': steps,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final topWalks = await AppDatabase.instance.getTopWalkSummaries(1);
      
      expect(topWalks.length, 3, reason: 'BVA: Failed boundary limit of 3');
      expect(topWalks[0]['total_steps'], 1000);
      expect(topWalks[1]['total_steps'], 500);
      expect(topWalks[2]['total_steps'], 200);
    });

    test('[TR-SUM-03] Last 10 EP: Returns exact amount if below cap', () async {
      for (int i = 1; i <= 5; i++) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().add(Duration(days: i)).toIso8601String(),
          'total_steps': 500,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      expect(recent.length, 5, reason: 'EP: Failed to return all items when below limit');
    });

    test('[TR-SUM-04] Top 3 EP: Returns exact amount sorted if below cap', () async {
      final stepCounts = [100, 500];
      
      for (int steps in stepCounts) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().toIso8601String(),
          'total_steps': steps,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final topWalks = await AppDatabase.instance.getTopWalkSummaries(1);

      expect(topWalks.length, 2, reason: 'EP: Failed to return all items when below limit');
      expect(topWalks[0]['total_steps'], 500); 
      expect(topWalks[1]['total_steps'], 100);
    });
  });
}