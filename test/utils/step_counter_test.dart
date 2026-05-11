// Tests for StepCounter — a global in-memory singleton that the map view
// increments as the pedometer reports new steps. No database involved;
// the counter is just a process-local integer.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flame_playground/utils/step_counter.dart';

void main() {
  group('UR3 — StepCounter', () {
    // Reset the singleton before each test so prior test state doesn't bleed.
    setUp(() {
      StepCounter().stepCount = 0;
    });

    test('[TR-STP-01] StepCounter singleton increments correctly', () {
      final counter = StepCounter();

      counter.addStep();
      counter.addStep();
      counter.addStep();

      expect(counter.stepCount, 3);

      // Verify the singleton — a second reference sees the same value.
      final counterCheck = StepCounter();
      expect(counterCheck.stepCount, 3, reason: 'Singleton state failed');
    });

    test('[TR-STP-02] accumulates correctly over many additions', () {
      final counter = StepCounter();

      for (int i = 0; i < 100; i++) {
        counter.addStep();
      }

      expect(counter.stepCount, 100, reason: 'Failed to accumulate 100 increments');
    });

    test('[TR-STP-03] stepCount can be reset to 0 (lower boundary)', () {
      final counter = StepCounter();
      counter.addStep();
      counter.addStep();
      expect(counter.stepCount, 2);

      counter.stepCount = 0;

      expect(counter.stepCount, 0, reason: 'Failed to reset to lower boundary');
      expect(StepCounter().stepCount, 0, reason: 'Singleton reset did not propagate');
    });
  });
}
