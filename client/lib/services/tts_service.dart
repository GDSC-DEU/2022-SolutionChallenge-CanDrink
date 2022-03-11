import 'package:text_to_speech/text_to_speech.dart';

class TTSService {
  TextToSpeech tts = TextToSpeech();

  double volume = 1.0;
  double rate = 1.0;
  double pitch = 1.0;

  final String languageCode = 'ko-KR';
  String? voice;

  Future<void> initLanguages() async {
    voice = await getVoiceByLang(languageCode);
  }

  Future<String?> getVoiceByLang(String lang) async {
    final List<String>? voices = await tts.getVoiceByLang(languageCode);
    if (voices != null && voices.isNotEmpty) {
      return voices.first;
    }
    return null;
  }

  void speak(String text) {
    tts.setVolume(volume);
    tts.setRate(rate);
    tts.setLanguage(languageCode);
    tts.setPitch(pitch);
    tts.speak(text);
  }
}
