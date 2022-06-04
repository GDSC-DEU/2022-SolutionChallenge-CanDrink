import 'package:text_to_speech/text_to_speech.dart';

class TTSService {
  final tts = TextToSpeech();

  set volume(double _volume) => tts.setVolume(_volume);
  set rate(double _rate) => tts.setRate(_rate);
  set pitch(double _pitch) => tts.setPitch(_pitch);
  set languageCode(String _languageCode) => tts.setLanguage(_languageCode);

  static final TTSService _ttsService = TTSService._();

  factory TTSService() {
    return _ttsService;
  }

  TTSService._() {
    volume = 1.0;
    rate = 1.0;
    pitch = 1.0;
    languageCode = "ko-KR";
  }

  Future<void> speak(String text) async {
    await tts.speak(text);
  }
}
