import 'package:camera/camera.dart';
import 'package:candrink/services/ml_kit/barcode_scanner.dart';
import 'package:candrink/services/tflite/image_classification/classifier.dart';
import 'package:candrink/services/tflite/image_classification/classifier_quant.dart';
import 'package:candrink/services/tflite/object_detection/tflite_service.dart';
import 'package:candrink/utils/image_convert.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:tflite/tflite.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

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
                  var barcodes = await scanBarcode(cameraImage);
                  if (barcodes.isEmpty) {
                    recognitionsList =
                        await runModel(cameraImage, recognitionsList);
                  } else {
                    for (Barcode barcode in barcodes) {
                      final BarcodeType type = barcode.type;
                      final Rect? boundingBox = barcode.value.boundingBox;
                      final String? displayValue = barcode.value.displayValue;
                      final String? rawValue = barcode.value.rawValue;

                      print(
                          "type: $type, displayValue: $displayValue, rawValue: $rawValue");
                    }
                  }
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
    if (recognitionsList.isNotEmpty) {
      _predict();
    }
  }

  void _predict() async {
    var a = await convertYUV420toImageColor(cameraImage!);
    img.Image? imageInput = img.decodeImage(a!);
    var pred = _classifier.predict(imageInput);
    print(pred);
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
