import 'dart:math';

import 'package:candrink/services/tflite/stats.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imageLib;
import 'package:candrink/services/tflite/recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Classifier {
  static const MODEL_FILENAME = 'tflite/converted_model-640-fp16-small-v1.tflite';
  static const LABELS_FILENAME = 'assets/tflite/labels.txt';

  /// Input size of image (height = width = 640)
  static const INPUT_SIZE = 640;
  static const THRESHOLD = 0.8;

  // Number of results to show
  static const int NUM_RESULTS = 10;

  bool get ready => labels != null && interpreter != null;

  List<String>? labels;
  Interpreter? interpreter;

  static List<List<int>> _outputShapes = [];

  static ImageProcessor? imageProcessor;

  Classifier({
    Interpreter? interpreter,
    List<String>? labels,
  }) {
    loadModel(interpreter: interpreter);
    loadLabels(labels: labels);
    print('TfliteService initilization complete!');
  }

  Future<void> loadLabels({List<String>? labels}) async {
    this.labels = labels ?? await FileUtil.loadLabels(LABELS_FILENAME);
    print('Successfully loaded labels. There are ${this.labels!.length} labels : (${this.labels!.join(", ")})');
  }

  Future<void> loadModel({Interpreter? interpreter}) async {
    this.interpreter = interpreter ??
        await Interpreter.fromAsset(
          MODEL_FILENAME,
          options: InterpreterOptions()..threads = 4,
        );

    _outputShapes = this.interpreter!.getOutputTensors().map((tensor) => tensor.shape).toList();
  }

  TensorImage resizeImage(TensorImage inputImage) {
    final padSize = max(inputImage.width, inputImage.height);

    imageProcessor ??= ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR))
        .build();

    return imageProcessor!.process(inputImage);
  }

  TensorBuffer tensorBufferedImage(TensorImage inputImage) {
    List<double> temporalMatrixedImage = inputImage.tensorBuffer.getDoubleList().map((pixel) => pixel / 255.0).toList();
    List<double> matrixedImage = [];
    // transpose [inputSize,inputSize,3] to [3,inputSize,inputSize]
    for (var i in [0, 1, 2]) {
      for (var j = i; j < temporalMatrixedImage.length; j += 3) {
        matrixedImage.add(temporalMatrixedImage[j]);
      }
    }

    var normalizedTensorBuffer = TensorBuffer.createFixedSize([3, INPUT_SIZE, INPUT_SIZE], TfLiteType.float32);
    normalizedTensorBuffer.loadList(matrixedImage, shape: [3, INPUT_SIZE, INPUT_SIZE]);
    return normalizedTensorBuffer;
  }

  PredictResult? predict(imageLib.Image image) {
    if (!ready) return null;

    final stats = Stats();

    stats.startPredict();

    // <-- Do PreProcess
    stats.startPreProcess();
    final resizedImage = resizeImage(TensorImage.fromImage(image));
    final normalizedTensorBuffer = tensorBufferedImage(resizedImage);
    stats.finishPreProcess();
    // End PreProces -->

    final inputs = [normalizedTensorBuffer.buffer];

    // tensor for results of inference
    final outputLocations = TensorBufferFloat(_outputShapes[0]);
    final outputs = {
      0: outputLocations.buffer,
    };

    // <-- Do Inference
    stats.startInference();
    interpreter!.runForMultipleInputs(inputs, outputs);
    stats.finishInference();
    // End Inference -->

    final results = outputLocations.getDoubleList();
    final recognitions = <Recognition>[];

    for (var i = 0; i < results.length; i += (5 + labels!.length)) {
      if (results[i + 4] < THRESHOLD) continue;

      final score = results.sublist(i + 5, i + 5 + labels!.length - 1).reduce(max);
      if (score < THRESHOLD) continue;

      final cls = results.sublist(i + 5, i + 5 + labels!.length - 1).indexOf(score) % labels!.length;

      // yolov5 output range:
      // centerX = results[i+0]: 0 ~ INPUT_SIZE
      // centerY = results[i+1]: 0 ~ INPUT_SIZE
      // width = results[i+2]: 0 ~ INPUT_SIZE (in case width is shorter than height, range will reduced)
      // height = results[i+2]: 0 ~ INPUT_SIZE (in case height is shorter than width, range will reduced)
      final outputRect = Rect.fromCenter(
        center: Offset(
          results[i] / INPUT_SIZE,
          results[i + 1] / INPUT_SIZE,
        ),
        width: results[i + 2] / INPUT_SIZE,
        height: results[i + 3] / INPUT_SIZE,
      );

      recognitions.add(Recognition(
        id: cls,
        label: labels![cls],
        score: score,
        location: outputRect,
      ));
    }

    recognitions.sort(((a, b) => b.score.compareTo(a.score)));

    stats.finishPredict();

    return PredictResult(
      recognitions: recognitions.take(NUM_RESULTS).toList(),
      stats: stats,
    );
  }
}

class PredictResult {
  final List<Recognition> recognitions;
  final Stats stats;

  PredictResult({required this.recognitions, required this.stats});
}
