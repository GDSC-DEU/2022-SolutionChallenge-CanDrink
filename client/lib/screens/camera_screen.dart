import 'package:camera/camera.dart';
import 'package:candrink/services/tflite/image_classification/classifier_quant.dart';
import 'package:candrink/services/tflite_service.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite/tflite.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../services/tflite/image_classification/classifier.dart';

class CameraScreen extends StatefulWidget {
  List<CameraDescription> cameras;

  CameraScreen(this.cameras, {Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool available = true;
  CameraController? cameraController;
  CameraImage? cameraImage;
  Category? category;
  late Classifier _classifier;
  List recognitionsList = [];

  initCamera() async {
    cameraController =
        CameraController(widget.cameras[0], ResolutionPreset.veryHigh);
    cameraController!.initialize().then(
      (_) {
        if (!mounted) {
          return;
        }

        setState(
          () {
            cameraController?.startImageStream(
              (image) async {
                if (available) {
                  available = false;
                  cameraImage = image;
                  recognitionsList =
                      await runModel(cameraImage, recognitionsList);
                  filterRecognitions();
                  setState(() {
                    cameraImage;
                  });
                  await Future.delayed(const Duration(seconds: 1));
                  available = true;
                }
              },
            );
          },
        );
      },
    );
  }

  void filterRecognitions() {
    var newRecognitionsList = [];
    for (var result in recognitionsList) {
      if (result['detectedClass'] == 'can' ||
          result['detectedClass'] == 'bottle') {
        newRecognitionsList.add(result);
      }
    }
    recognitionsList = newRecognitionsList;
    _predict();
  }

  var shift = (0xFF << 24);
  Future<List<int>?> convertYUV420toImageColor(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;

      // imgLib -> Image package from https://pub.dartlang.org/packages/image
      var imgOrig = img.Image(width, height); // Create Image buffer

      // Fill image buffer with plane[0] from YUV420_888
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex =
              uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          // Calculate pixel color
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          // color: 0x FF  FF  FF  FF
          //           A   B   G   R
          imgOrig.data[index] = shift | (b << 16) | (g << 8) | r;
        }
      }

      img.PngEncoder pngEncoder = img.PngEncoder(level: 0, filter: 0);
      return pngEncoder.encodeImage(imgOrig);
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
  }

  void _predict() async {
    var a = await convertYUV420toImageColor(cameraImage!);
    img.Image? imageInput = img.decodeImage(a!);
    var pred = _classifier.predict(imageInput);
  }

  @override
  void dispose() {
    super.dispose();

    cameraController?.stopImageStream();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();

    _classifier = ClassifierQuant();

    loadModel();
    initCamera();
  }

  List<Widget> boxRecognizedObjects(Size screen) {
    double factorX = screen.width;
    double factorY = screen.height;

    Color colorPick = Colors.red;

    return recognitionsList.map((result) {
      return Positioned(
        left: result["rect"]["x"] * factorX,
        top: result["rect"]["y"] * factorY,
        width: result["rect"]["w"] * factorX,
        height: result["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.red, width: 2.0),
          ),
          child: Text(
            "${result['detectedClass']} ${(result['confidenceInClass'] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.black,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> list = [];

    list.add(
      Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        height: size.height - 100,
        child: SizedBox(
          height: size.height - 100,
          child: (!cameraController!.value.isInitialized)
              ? Container()
              : AspectRatio(
                  aspectRatio: cameraController!.value.aspectRatio,
                  child: CameraPreview(cameraController!),
                ),
        ),
      ),
    );

    list.addAll(boxRecognizedObjects(size));

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          margin: const EdgeInsets.only(top: 50),
          color: Colors.black,
          child: Stack(
            children: list,
          ),
        ),
      ),
    );
  }
}
