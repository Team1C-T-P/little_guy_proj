import 'package:flutter_flame_playground/models/step_points_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';

void main() {
  // Copied from walk_summary_test
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.initializeDefaultData();
  });

  setUp(() async {
    final db = await AppDatabase.instance.database;
    await db.delete('user');
  });

  group('awardBonusPoints', () {
    // Successfully award points

    // Error on non-existent user

    // Error on zero or negative points?
  });

  group('recordSteps', () {
    // Steps must be 0 or over

    // User must exist

    // what is step ledger? - test it?

    // Step record - 50/100 steps, expect 0 points, 50 unconverted

    // Step conversion - 150 steps, expect 1 point, 50 unconverted

    // Leftover steps?
  });

  group('getAccountSummary', () {
    // user must exist

    // wtf is step ledger -test it?

    // Correct totals after rewarding points
  });
}
