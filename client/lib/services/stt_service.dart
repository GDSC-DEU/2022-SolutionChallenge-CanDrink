import 'package:candrink/services/tts_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

class STTService {
  static final STTService _sttService = STTService._internal();
  factory STTService() => _sttService;

  STTService._internal() {
    _speechToText = SpeechToText();
  }

  late SpeechToText _speechToText;

  final tts = TTSService();

  initSpeech() async {
    print("Initialized STT Service");
    await _speechToText.initialize();
  }

  startingListening(onSpeechResult) async {
    print("Start STT Mode");
    tts.stop();
    await _speechToText.listen(onResult: onSpeechResult, pauseFor: const Duration(seconds: 999));
  }

  stopListening() async {
    print("Stop STT Mode");
    await _speechToText.stop();
  }
}
