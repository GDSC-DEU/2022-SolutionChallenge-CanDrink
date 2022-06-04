import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:candrink/services/asset_download.dart';
import 'package:candrink/services/stt_service.dart';
import 'package:candrink/services/tflite/recognition.dart';
import 'package:candrink/services/tts_service.dart';
import 'package:candrink/ui/bounding_box.dart';
import 'package:candrink/ui/camera_view.dart';
import 'package:candrink/utils/vibration.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class HomeView extends StatefulWidget {
  final stt = STTService();
  final tts = TTSService();
  final assetsAudioPlayer = AssetsAudioPlayer();
  final assetDownloader = AssetDownloader();

  void downloadAsset() async {
    await assetDownloader.initAssetDownloader();
    if (!await assetDownloader.isDownloaded()) {
      await assetDownloader.downloadAsset();
    }
  }

  @override
  _HomeViewState createState() => _HomeViewState();

  HomeView({Key? key}) : super(key: key);
}

class _HomeViewState extends State<HomeView> {
  bool speaking = false;
  bool sttSpeaking = false;
  String previousSpeech = '';
  List<Recognition> recognitions = [];

  void onRecognized(List<Recognition> recognitions) async {
    setState(() {
      this.recognitions = recognitions;
    });
    if (this.recognitions.isEmpty) return;

    print('RECOGNITIONS (${this.recognitions.length}) ====> ${this.recognitions.map((recognition) => recognition.label).join(", ")}');

    if (speaking) return;
    speaking = true;

    // 중복된 제품은 제거
    final products = this.recognitions.map((recognition) => recognition.label).toSet().toList();
    var speech = '';

    vibrateStrong();
    // 음료의 종류가 2종류 이하일 시 그대로 읽어주기
    if (products.length <= 2) {
      speech = products.join(' 그리고 ');
    }
    // 음료의 종류가 3종류 이상일 시 많다고만 하기
    else {
      speech = '음료의 종류가 많습니다';
    }

    if (speech.isNotEmpty) {
      await widget.tts.speak(speech);
      previousSpeech = speech;
    }
    speaking = false;
  }

  Widget boundingBoxes(List<Recognition> recognitions) {
    return Stack(
      children: recognitions
          .where((recognition) => recognition.location != null)
          .map((recognition) => BoundingBox(recognition: recognition))
          .toList(),
    );
  }

  onSpeechResult(SpeechRecognitionResult result) async {
    var _lastWord = result.recognizedWords;

    if (_lastWord != "") {
      print("STT Result : " + _lastWord);
      for (var recognition in recognitions) {
        if (_lastWord != "" && recognition.label.contains(_lastWord) && !sttSpeaking) {
          sttSpeaking = true;
          widget.tts.speak("${recognition.label}가 있습니다.");
          await widget.stt.stopListening();
          break;
        }
      }
      sttSpeaking = false;
      _lastWord = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        onLongPressStart: (details) async {
          speaking = true;
          await widget.stt.startingListening(onSpeechResult);
          vibrateStrong();
        },
        onLongPressEnd: (details) async {
          await widget.stt.stopListening();
          speaking = false;
        },
        child: Stack(children: [
          Positioned(
            top: 0.0,
            left: 0.0,
            width: screenSize.width,
            height: screenSize.height,
            child: SizedBox(
              height: screenSize.height,
              child: CameraView(onRecognized: onRecognized),
            ),
          ),

          // draw object's bounding boxes
          boundingBoxes(recognitions),
        ]),
      ),
    );
  }
}
