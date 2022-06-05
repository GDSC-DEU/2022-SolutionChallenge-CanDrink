class Stats {
  int _predictStart = 0;
  int _preProcessStart = 0;
  int _inferenceStart = 0;

  /// Time taken to pre-process the image
  late final int preProcessingTime;

  /// Time for which inference runs
  late final int inferenceTime;

  /// Total time taken in the isolate where the inference runs
  late final int totalPredictTime;

  /// [totalPredictTime] + communication overhead time
  /// between main isolate and another isolate
  late final int totalElapsedTime;

  Stats();

  void startPredict() {
    _predictStart = DateTime.now().millisecondsSinceEpoch;
  }

  void finishPredict() {
    totalPredictTime = DateTime.now().millisecondsSinceEpoch - _predictStart;
  }

  void startPreProcess() {
    _preProcessStart = DateTime.now().millisecondsSinceEpoch;
  }

  void finishPreProcess() {
    preProcessingTime = DateTime.now().millisecondsSinceEpoch - _preProcessStart;
  }

  void startInference() {
    _inferenceStart = DateTime.now().millisecondsSinceEpoch;
  }

  void finishInference() {
    inferenceTime = DateTime.now().millisecondsSinceEpoch - _inferenceStart;
  }

  @override
  String toString() {
    return 'Stats (totalPredictTime: $totalPredictTime, totalElapsedTime: $totalElapsedTime, inferenceTime: $inferenceTime, preProcessingTime: $preProcessingTime)';
  }
}
