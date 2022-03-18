import 'package:text_to_speech/text_to_speech.dart';

class TTSService {
  final tts = TextToSpeech();

  set volume(double _volume) => tts.setVolume(_volume);
  set rate(double _rate) => tts.setRate(_rate);
  set pitch(double _pitch) => tts.setPitch(_pitch);

  String? voice;
  set languageCode(String languageCode) => {
        tts.getVoiceByLang(languageCode).then((voices) => {voice = voices?.first})
      };

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

  void speak(String text) {
    tts.speak(text);
  }
}
