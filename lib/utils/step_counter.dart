class StepCounter {
  static final StepCounter _instance = StepCounter._internal();
  factory StepCounter() => _instance;

  StepCounter._internal();

  int stepCount = 0;

  void addStep() {
    stepCount++;
  }
}
