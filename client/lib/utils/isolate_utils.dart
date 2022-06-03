import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:candrink/services/tflite/classifier.dart';
import 'package:candrink/utils/image_utils.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateUtils {
  static const String DEBUG_NAME = "InferenceIsolate";

  late Isolate isolate;
  ReceivePort _receivePort = ReceivePort();
  late SendPort sendPort;

  Future<void> start() async {
    isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );

    sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final IsolateData? isolateData in port) {
      if (isolateData != null) {
        final classifier = Classifier(
          interpreter: Interpreter.fromAddress(isolateData.interpreterAddress),
          labels: isolateData.labels,
        );
        Image image = ImageUtils.convertCameraImage(isolateData.cameraImage);
        if (Platform.isAndroid) {
          image = copyRotate(image, 90);
        }
        final recognitions = classifier.predict(image);
        isolateData.responsePort.send(recognitions);
      }
    }
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  CameraImage cameraImage;
  int interpreterAddress;
  List<String> labels;
  late SendPort responsePort;

  IsolateData(
    this.cameraImage,
    this.interpreterAddress,
    this.labels,
  );
}
