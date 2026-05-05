import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flame_playground/widgets/progress_bar.dart';

void main() {
  // Note: ProgressBar uses Image.asset which requires actual assets.
  // These tests focus on widget properties and State creation instead of rendering.

  test('ProgressBar has correct properties', () {
    const progressBar = ProgressBar(
      iconPath: 'assets/images/hunger.png',
      progress: 0.5,
    );

    expect(progressBar.progress, equals(0.5));
    expect(progressBar.iconPath, equals('assets/images/hunger.png'));
  });

  test('ProgressBar progress property with different values', () {
    final progressValues = [0.0, 0.25, 0.5, 0.75, 1.0];

    for (double progress in progressValues) {
      final progressBar = ProgressBar(
        iconPath: 'assets/images/hunger.png',
        progress: progress,
      );
      expect(progressBar.progress, equals(progress));
    }
  });

  test('ProgressBar iconPath property with different values', () {
    final paths = [
      'assets/images/hunger.png',
      'assets/images/enjoyment.png',
      'assets/images/hygiene.png',
    ];

    for (String path in paths) {
      final progressBar = ProgressBar(
        iconPath: path,
        progress: 0.5,
      );
      expect(progressBar.iconPath, equals(path));
    }
  });

  test('ProgressBar is StatefulWidget', () {
    const progressBar = ProgressBar(
      iconPath: 'assets/images/hunger.png',
      progress: 0.5,
    );

    expect(progressBar, isInstanceOf<StatefulWidget>());
  });

  test('ProgressBar createState returns _ProgressBarState', () {
    const progressBar = ProgressBar(
      iconPath: 'assets/images/hunger.png',
      progress: 0.5,
    );

    final state = progressBar.createState();
    expect(state, isNotNull);
    expect(state.runtimeType.toString(), contains('_ProgressBarState'));
  });

  test('ProgressBar is const constructible', () {
    const progressBar = ProgressBar(
      iconPath: 'assets/images/hunger.png',
      progress: 0.5,
    );

    expect(progressBar, isNotNull);
  });

  test('ProgressBar with key is const constructible', () {
    const progressBar = ProgressBar(
      key: ValueKey('progress_1'),
      iconPath: 'assets/images/enjoyment.png',
      progress: 0.5,
    );

    expect(progressBar.key, isNotNull);
  });

  test('ProgressBar properties are immutable', () {
    const progressBar1 = ProgressBar(
      iconPath: 'assets/images/hunger.png',
      progress: 0.5,
    );

    const progressBar2 = ProgressBar(
      iconPath: 'assets/images/hunger.png',
      progress: 0.5,
    );

    expect(progressBar1.progress, equals(progressBar2.progress));
    expect(progressBar1.iconPath, equals(progressBar2.iconPath));
  });

  test('ProgressBar accepts edge case progress values', () {
    final edgeCases = [0.0, 0.001, 0.999, 1.0];

    for (double progress in edgeCases) {
      final progressBar = ProgressBar(
        iconPath: 'assets/images/hygiene.png',
        progress: progress,
      );
      expect(progressBar.progress, equals(progress));
    }
  });

  test('ProgressBar accepts empty iconPath', () {
    const progressBar = ProgressBar(
      iconPath: '',
      progress: 0.5,
    );

    expect(progressBar.iconPath, equals(''));
    expect(progressBar.progress, equals(0.5));
  });

  test('ProgressBar runtimeType is correct', () {
    const progressBar = ProgressBar(
      iconPath: 'assets/images/enjoyment.png',
      progress: 0.5,
    );

    expect(progressBar.runtimeType.toString(), equals('ProgressBar'));
  });

  test('ProgressBar is const constructible', () {
    const progressBar = ProgressBar(
      iconPath: 'assets/images/hunger.png',
      progress: 0.5,
    );

    expect(progressBar, isNotNull);
  });
}

