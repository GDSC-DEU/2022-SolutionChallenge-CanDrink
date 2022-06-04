import 'dart:isolate';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:camera/camera.dart';
import 'package:candrink/services/asset_download.dart';
import 'package:candrink/services/barcode_scanner.dart';
import 'package:candrink/services/tflite/classifier.dart';
import 'package:candrink/services/tflite/recognition.dart';
import 'package:candrink/services/tts_service.dart';
import 'package:candrink/ui/camera_view_singleton.dart';
import 'package:candrink/utils/isolate_utils.dart';
import 'package:candrink/utils/vibration.dart';
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  final Function(List<Recognition> recognitions) onRecognized;

  @override
  _CameraViewState createState() => _CameraViewState();

  const CameraView({required this.onRecognized, Key? key}) : super(key: key);
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  /// List of available cameras
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  late Classifier classifier;
  late IsolateUtils isolateUtils;

  bool cameraOccupied = false;

  final tts = TTSService();
  final assetsAudioPlayer = AssetsAudioPlayer();
  final assetDownloader = AssetDownloader();

  _CameraViewState();

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    WidgetsBinding.instance!.addObserver(this);

    isolateUtils = IsolateUtils();
    await isolateUtils.start();

    classifier = Classifier();

    await initCamera();

    // all ready! play initialize sound to notify user
    assetsAudioPlayer.open(Audio("assets/sound/beep.mp3"));
    startVibrate();
    vibrateWeek();

    // all initialization done, refresh state to start camera preview.
    setState(() {});
  }

  initCamera() async {
    cameras = await availableCameras();

    cameraController = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
    await cameraController!.initialize().then((_) async {
      await cameraController!.startImageStream(onLatestImageAvailable);

      determineCameraPreviewActualSize();
    });
  }

  onLatestImageAvailable(CameraImage cameraImage) async {
    if (!classifier.ready) return;

    if (cameraOccupied) {
      return;
    }
    setState(() {
      cameraOccupied = true;
    });

    // do 2 inference job simultaneously
    List<List<Recognition>> results = await Future.wait<List<Recognition>>([
      inferenceObjects(cameraImage),
      inferenceBarcodes(cameraImage),
    ]);

    // flatten 2 results
    final recognitions = results.expand((i) => i).toList();
    widget.onRecognized(recognitions);

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      cameraOccupied = false;
    });
  }

  Future<List<Recognition>> inferenceObjects(CameraImage cameraImage) async {
    final isolateData = IsolateData(cameraImage, classifier.interpreter!.address, classifier.labels!);
    ReceivePort responsePort = ReceivePort();

    isolateUtils.sendPort.send(isolateData..responsePort = responsePort.sendPort);
    final recognitions = (await responsePort.first) as List<Recognition>;
    return recognitions;
  }

  Future<List<Recognition>> inferenceBarcodes(CameraImage cameraImage) async {
    final barcodes = await scanBarcodes(cameraImage);
    if (barcodes.isNotEmpty) {
      final barcode = barcodes[0];
      final expiration = getExpirationFromBarcode(barcode);

      final productName = (await getProductNameFromBarcode(barcode)) ?? (expiration != null ? '유통기한이 $expiration 까지 입니다' : null);
      print('barcode(barcode: $barcode, productName: $productName, expiration: $expiration)');
      if (productName != null) {
        // Recognition, but no bounding box, no id.
        return [Recognition(id: -1, label: productName, score: 1.0)];
      }
    }
    return [];
  }

  void determineCameraPreviewActualSize() {
    /// previewSize is size of each image frame captured by controller
    ///
    /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
    final previewSize = cameraController!.value.previewSize!;

    /// previewSize is size of raw input image to the model
    CameraViewSingleton.inputImageSize = previewSize;

    // the display width of image on screen is
    // same as screenWidth while maintaining the aspectRatio
    final screenSize = MediaQuery.of(context).size;

    CameraViewSingleton.screenSize = screenSize;
    CameraViewSingleton.ratio = screenSize.width / previewSize.height;
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Container();
    }

    return AspectRatio(
      aspectRatio: cameraController!.value.aspectRatio,
      child: CameraPreview(cameraController!),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        cameraController!.stopImageStream();
        pauseVibrate();
        break;
      case AppLifecycleState.resumed:
        resumeVibrate();
        if (cameraController != null && !cameraController!.value.isStreamingImages) {
          await cameraController!.startImageStream(onLatestImageAvailable);
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    cameraController?.dispose();
    super.dispose();
  }
}
