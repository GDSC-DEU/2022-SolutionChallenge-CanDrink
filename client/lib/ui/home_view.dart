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
  int countAISpeechRepeated = 0;
  String lastAISpeech = '';
  bool isYouSpeaking = false;
  String lastYouSpeech = '';
  List<Recognition> recognitions = [];

  void onRecognized(List<Recognition> recognitions) async {
    setState(() {
      this.recognitions = recognitions;
    });
    if (this.recognitions.isEmpty) return;

    print('RECOGNITIONS (${this.recognitions.length}) ====> ${this.recognitions.map((recognition) => recognition.label).join(", ")}');

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

    // 사용자가 말하는 중에는 TTS 멈추기
    if (isYouSpeaking) return;

    setState(() {
      lastAISpeech = speech;
    });

    if (speech.isNotEmpty) {
      if (lastAISpeech == speech) {
        countAISpeechRepeated++;
        if (countAISpeechRepeated < 2) {
          return;
        }
      }
      countAISpeechRepeated = 0;
      await widget.tts.speak(speech);
    }
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
    print(result.recognizedWords);
    if (_lastWord != "") {
      print("STT Result : " + _lastWord);
      setState(() {
        lastYouSpeech = _lastWord;
      });
      for (var recognition in recognitions) {
        if (_lastWord != "" && recognition.label.contains(_lastWord) && isYouSpeaking) {
          setState(() {
            lastAISpeech = "${recognition.label}가 있습니다.";
          });
          widget.tts.speak(lastAISpeech);
          await widget.stt.stopListening();
          break;
        }
      }
      _lastWord = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (details) async {
          await widget.stt.startingListening(onSpeechResult);
          setState(() {
            lastYouSpeech = '';
            isYouSpeaking = true;
            widget.tts.stop();
          });
          vibrateLong();
        },
        onTapUp: (details) async {
          await widget.stt.stopListening();
          setState(() {
            isYouSpeaking = false;
          });
          vibrateWeek();
        },
        child: Stack(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Stack(children: [
                  Positioned.fill(child: CameraView(onRecognized: onRecognized)),

                  // draw object's bounding boxes
                  boundingBoxes(recognitions),
                ]),
              ),
              Container(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'A.I. : $lastAISpeech',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              Container(
                color: isYouSpeaking ? Colors.green : null,
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'You : ${isYouSpeaking ? '$lastYouSpeech (listening ...)'.trim() : lastYouSpeech}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
