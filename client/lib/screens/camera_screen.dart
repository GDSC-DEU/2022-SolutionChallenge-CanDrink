import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:camera/camera.dart';
import 'package:candrink/services/asset_download.dart';
import 'package:candrink/services/barcode_scanner.dart';
import 'package:candrink/services/tflite/image_classification/classifier.dart';
import 'package:candrink/services/tflite/image_classification/classifier_quant.dart';
import 'package:candrink/services/tflite/tflite_service.dart';
import 'package:candrink/services/tts_service.dart';
import 'package:candrink/utils/barcode_information.dart';
import 'package:candrink/utils/image_convert.dart';
import 'package:candrink/utils/vibration.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite/tflite.dart';

class CameraScreen extends StatefulWidget {
  List<CameraDescription> cameras;

  CameraScreen(this.cameras, {Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  TTSService tts = TTSService();
  final assetsAudioPlayer = AssetsAudioPlayer();
  AssetDownloader assetDownloader = AssetDownloader();

  bool cameraOccupied = false;
  late CameraController cameraController;
  CameraImage? cameraImage;
  late Classifier _classifier;

  late double ratio;
  late Size actualPreviewSize;

  List<Recognition> recognitions = [];

  initCamera() async {
    cameraController = CameraController(widget.cameras[0], ResolutionPreset.low);
    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }

      cameraController.startImageStream((image) async {
        setState(() {
          cameraImage = image;
        });

        if (cameraOccupied) {
          return;
        }
        cameraOccupied = true;

        // run 2 jobs simultaneously
        List<List<String>> _products = await Future.wait([
          // Barcode
          (() async {
            final barcodes = await scanBarcodes(cameraImage);
            if (barcodes.isNotEmpty) {
              final productName = await getProductNameFromBarcode(barcodes[0].value.rawValue!);
              if (productName != null) {
                return [productName];
              }
            }
            return <String>[];
          })(),
          // Yolov5
          (() async {
            if (cameraImage != null) {
              final recognitions = TfliteService.predict(cameraImage!);
              setState(() {
                this.recognitions = recognitions;
              });
              return recognitions.map((recognition) => recognition.label).toList();
            }
            return <String>[];
          })(),
        ]);

        // flatten results and remove dup
        final products = _products.expand((i) => i).toList().toSet().toList();

        if (products.isNotEmpty) {
          vibrateStrong();

          // 음료의 종류가 2종류 이하일 시 그대로 읽어주기
          if (products.length <= 2) {
            tts.speak(products.join(' 그리고 '));
          }
          // 음료의 종류가 3종류 이상일 시 많다고만 하기
          else {
            tts.speak('음료의 종류가 많습니다');
          }
        }

        await Future.delayed(const Duration(seconds: 1));
        cameraOccupied = false;
      });
    });
  }

  void playInitializationSound() {
    assetsAudioPlayer.open(
      Audio("assets/sound/beep.mp3"),
    );
  }

  void _downloadAsset() async {
    await assetDownloader.initAssetDownloader();
    if (!await assetDownloader.isDownloaded()) {
      await assetDownloader.downloadAsset();
    }
  }

  @override
  void dispose() {
    super.dispose();

    cameraController.stopImageStream();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();

    _classifier = ClassifierQuant();

    _downloadAsset();
    TfliteService.initialize();

    initCamera();
    playInitializationSound();

    startVibrate();
    vibrateWeek();
  }

  Widget getRecognizedBox(Size screenSize, Recognition recognition) {
    const color = Colors.red;
    final location = recognition.location;

    print('recognition = ${recognition.label}, $location');

    return Positioned(
      top: location.top,
      right: location.left,
      width: location.width,
      height: location.height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          border: Border.all(color: color, width: 2.0),
        ),
        child: Text(
          "${recognition.label} (${recognition.score.toStringAsFixed(3)})%",
          style: TextStyle(
            background: Paint()..color = color,
            color: Colors.black,
            fontSize: 18.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    actualPreviewSize = Size(
      screenSize.width,
      screenSize.height,
    );

    final cameraView = Positioned(
      top: 0.0,
      left: 0.0,
      width: screenSize.width,
      height: screenSize.height - 100,
      child: SizedBox(
        height: screenSize.height - 100,
        child: (!cameraController.value.isInitialized)
            ? Container()
            : AspectRatio(
                aspectRatio: cameraController.value.aspectRatio,
                child: CameraPreview(cameraController),
              ),
      ),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          margin: const EdgeInsets.only(top: 50),
          color: Colors.black,
          child: Stack(
            children: [
              cameraView,
              ...recognitions.map((recognition) => BoundingBox(
                    recognition: recognition,
                    actualPreviewSize: actualPreviewSize,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class BoundingBox extends StatelessWidget {
  const BoundingBox({
    Key? key,
    required this.recognition,
    required this.actualPreviewSize,
  }) : super(key: key);

  final Recognition recognition;
  final Size actualPreviewSize;

  @override
  Widget build(BuildContext context) {
    final location = recognition.location;

    print('actualPreviewSize=$actualPreviewSize');
    print('location=${location}');

    return Positioned(
      left: location.left * actualPreviewSize.width,
      top: location.top * actualPreviewSize.height,
      width: location.width * actualPreviewSize.width,
      height: location.height * actualPreviewSize.height,
      child: Container(
        width: location.width * actualPreviewSize.width,
        height: location.height * actualPreviewSize.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red,
            width: 1,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(2),
          ),
        ),
        child: buildBoxLabel(recognition, context),
      ),
    );
  }

  Align buildBoxLabel(Recognition result, BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: FittedBox(
        child: ColoredBox(
          color: Colors.red,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.label,
              ),
              Text(
                ' (${result.score.toStringAsFixed(2)})',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
