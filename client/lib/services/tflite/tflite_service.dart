import 'dart:math';

import 'package:camera/camera.dart';
import 'package:candrink/utils/image_convert.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

const String modelFilename = 'tflite/candrink_v4.tflite';
const String labelsFilename = 'assets/tflite/candrink_v4.txt';
const int inputSize = 640;
const double objectConfThreshold = 0.80;
const double classConfThreshold = 0.80;

class Recognition {
  final int id;
  final int labelId;
  final String label;
  final double score;
  final Rect location;

  Recognition(this.id, this.labelId, this.label, this.score, this.location);

  Rect getRenderLocation(Size actualPreviewSize, double pixelRatio) {
    final ratioX = pixelRatio;
    final ratioY = ratioX;

    final transLeft = max(0.1, location.left * ratioX);
    final transTop = max(0.1, location.top * ratioY);
    final transWidth = min(
      location.width * ratioX,
      actualPreviewSize.width,
    );
    final transHeight = min(
      location.height * ratioY,
      actualPreviewSize.height,
    );
    final transformedRect = Rect.fromLTWH(transLeft, transTop, transWidth, transHeight);
    return transformedRect;
  }
}

class TfliteService {
  static bool initializing = false;
  static bool get initialized => _labels != null && _interpreter != null;

  static List<String>? _labels;
  static Interpreter? _interpreter;

  static List<List<int>> _outputShapes = [];

  static ImageProcessor? imageProcessor;

  static Future<void> initialize() async {
    if (initializing) {
      return print('TfliteService is already initializing.');
    }
    if (initialized) {
      return print('TfliteService was initialized.');
    }

    await Future.wait([
      loadLabels(),
      loadModel(),
    ]);

    print('TfliteService initilization complete!');
  }

  static Future<void> loadLabels() async {
    _labels = await FileUtil.loadLabels(labelsFilename);
    print('Successfully loaded labels. There are ${_labels!.length} labels ... (${_labels!.join(", ")})');
  }

  static Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      modelFilename,
      options: InterpreterOptions()..threads = 4,
    );
    final outputTensors = _interpreter!.getOutputTensors();
    _outputShapes = outputTensors.map((tensor) => tensor.shape).toList();
  }

  static TensorImage normalizeImage(TensorImage inputImage) {
    final padSize = max(inputImage.width, inputImage.height);

    imageProcessor ??= ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .build();

    return imageProcessor!.process(inputImage);
  }

  static TensorBuffer tensorBufferedImage(TensorImage inputImage) {
    List<double> temporalMatrixedImage = inputImage.tensorBuffer.getDoubleList().map((pixel) => pixel / 255.0).toList();
    List<double> matrixedImage = [];
    // transpose [640,640,3] to [3,640,640]
    for (var i in [0, 1, 2]) {
      for (var j = i; j < temporalMatrixedImage.length; j += 3) {
        matrixedImage.add(temporalMatrixedImage[j]);
      }
    }

    var normalizedTensorBuffer = TensorBuffer.createDynamic(TfLiteType.float32);
    normalizedTensorBuffer.loadList(matrixedImage, shape: [3, inputSize, inputSize]);
    return normalizedTensorBuffer;
  }

  static List<Recognition> predict(CameraImage cameraImage) {
    if (!initialized) return [];

    final sourceImage = convertYUV420ToImage(cameraImage);

    final image = normalizeImage(TensorImage.fromImage(sourceImage));
    final normalizedTensorBuffer = tensorBufferedImage(image);

    final inputs = [normalizedTensorBuffer.buffer];

    // tensor for results of inference
    final outputLocations = TensorBufferFloat(_outputShapes[0]);
    final outputs = {
      0: outputLocations.buffer,
    };

    _interpreter!.runForMultipleInputs(inputs, outputs);
    final results = outputLocations.getDoubleList();
    print('RESULT (${results.length}) ====> ${results}');

    final recognitions = <Recognition>[];

    for (var i = 0; i < results.length; i += (5 + _labels!.length)) {
      if (results[i + 4] < objectConfThreshold) continue;

      final score = results.sublist(i + 5, i + 5 + _labels!.length - 1).reduce(max);
      if (score < classConfThreshold) continue;

      final cls = results.sublist(i + 5, i + 5 + _labels!.length - 1).indexOf(score) % _labels!.length;
      final outputRect = Rect.fromCenter(
        center: Offset(
          results[i],
          results[i + 1],
        ),
        width: results[i + 2],
        height: results[i + 3],
      );
      final transformRect = imageProcessor!.inverseTransformRect(outputRect, image.height, image.width);

      recognitions.add(Recognition(
        i,
        cls,
        _labels![cls],
        score,
        Rect.fromLTWH(
          transformRect.left / inputSize,
          transformRect.top / inputSize,
          transformRect.width / inputSize,
          transformRect.height / inputSize,
        ),
      ));
    }

    print('RECOGNITIONS (${recognitions.length}) ====> ${recognitions.map((recognition) => recognition.label).join(", ")}');
    return recognitions;
  }
}
