import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flame_playground/utils/step_counter.dart';

void main() {
  group('Track Steps Logic', () {
    test('[TR-STP-01] StepCounter singleton increments correctly', () {
      final counter = StepCounter();
      counter.stepCount = 0; // Reset for test
      
      counter.addStep();
      counter.addStep();
      counter.addStep();

      expect(counter.stepCount, 3);

      // Verify singleton persistence
      final counterCheck = StepCounter();
      expect(counterCheck.stepCount, 3, reason: 'Singleton state failed');
    });
  });
}