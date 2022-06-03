import 'package:vibration/vibration.dart';

enum FeedbackType {
  week,
  strong,
}

class VibratePattern {
  final int amplitude;
  final List<int> pattern;

  VibratePattern({required this.amplitude, required this.pattern});
}

Map<FeedbackType, VibratePattern> VibrationPatterns = {
  FeedbackType.week: VibratePattern(
    amplitude: 16,
    pattern: [500, 50],
  ),
  FeedbackType.strong: VibratePattern(
    amplitude: 128,
    pattern: [200, 300, 200, 300, 200, 300],
  ),
};

var feedbackMode = FeedbackType.week;
var paused = false;

void vibrateWeek() {
  feedbackMode = FeedbackType.week;
}

void vibrateStrong() {
  feedbackMode = FeedbackType.strong;
}

Future<void> startVibrate() async {
  Future.doWhile(() async {
    if (paused) true;

    final vibrationPattern = VibrationPatterns[feedbackMode]!;
    vibrateWeek();

    await Vibration.vibrate(
      amplitude: vibrationPattern.amplitude,
      pattern: vibrationPattern.pattern,
    );

    await Future.delayed(Duration(milliseconds: vibrationPattern.pattern.reduce((a, b) => a + b)));

    return true;
  });
}

void pauseVibrate() {
  paused = true;
}

void resumeVibrate() {
  paused = false;
}
