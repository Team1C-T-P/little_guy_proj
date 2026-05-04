import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';

void main() {
  setUpAll(() {
    // Initialize the FFI engine for desktop/test execution
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Completely wipe and rebuild a fresh database BEFORE EACH test
    final dbPath = inMemoryDatabasePath;
    await databaseFactory.deleteDatabase(dbPath);
    await AppDatabase.instance.initializeDefaultData(); 
  });

  group('See Summaries (Limits and Sorting)', () {
    
    // ==========================================
    // BOUNDARY VALUE ANALYSIS (BVA) TESTS
    // ==========================================

    test('[TR-SUM-01] Last 10 BVA: Strictly caps query at 10 items', () async {
      // Setup: Inject 12 summaries (exceeding the limit)
      for (int i = 1; i <= 12; i++) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().add(Duration(days: i)).toIso8601String(),
          'total_steps': 500,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      // Action
      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      
      // Verify
      expect(recent.length, 10, reason: 'BVA: Failed boundary limit of 10');
    });

    test('[TR-SUM-02] Top 3 BVA: Returns highest 3 step counts descending', () async {
      // Setup: Inject 5 randomized step counts (exceeding the limit)
      final stepCounts = [100, 500, 200, 1000, 50];
      for (int steps in stepCounts) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().toIso8601String(),
          'total_steps': steps,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      // Action
      final topWalks = await AppDatabase.instance.getTopWalkSummaries(1);
      
      // Verify
      expect(topWalks.length, 3, reason: 'BVA: Failed boundary limit of 3');
      expect(topWalks[0]['total_steps'], 1000);
      expect(topWalks[1]['total_steps'], 500);
      expect(topWalks[2]['total_steps'], 200);
    });

    // ==========================================
    // EQUIVALENCE PARTITIONING (EP) TESTS
    // ==========================================

    test('[TR-SUM-03] Last 10 EP: Returns exact amount if below cap', () async {
      // Setup: Inject only 5 summaries (Valid EP)
      for (int i = 1; i <= 5; i++) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().add(Duration(days: i)).toIso8601String(),
          'total_steps': 500,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      // Action
      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      
      // Verify
      expect(recent.length, 5, reason: 'EP: Failed to return all items when below limit');
    });

    test('[TR-SUM-04] Top 3 EP: Returns exact amount sorted if below cap', () async {
      // Setup: Inject only 2 summaries (Valid EP)
      final stepCounts = [100, 500];
      
      for (int steps in stepCounts) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().toIso8601String(),
          'total_steps': steps,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      // Action
      final topWalks = await AppDatabase.instance.getTopWalkSummaries(1);

      // Verify
      expect(topWalks.length, 2, reason: 'EP: Failed to return all items when below limit');
      
      // Verify sorting still works correctly even when under the cap
      expect(topWalks[0]['total_steps'], 500); 
      expect(topWalks[1]['total_steps'], 100);
    });
  });
}