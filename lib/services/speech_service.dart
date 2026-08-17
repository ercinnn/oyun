import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Bulunan (eşleşmiş) hafıza kartlarına tıklanınca kelimenin okunuşunu
/// sesli olarak söyler.
///
/// Platformlar arasında gerçek bir "çocuk sesi" TTS sesi garanti edilemediği
/// için (tarayıcı/işletim sistemine göre değişir), çocuklara uygun anlaşılır
/// bir ton; yüksek perde (`setPitch`) ve yavaş, net bir konuşma hızıyla
/// (`setSpeechRate`) taklit edilir — bu, taşınabilir ve güvenilir yaklaşımdır.
class SpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;
  String? _language;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    _configured = true;
    await _tts.setPitch(1.4);
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    // Web'de sesler `voiceschanged` olayıyla asenkron yüklenir; henüz hiç
    // ses hazır değilse ilk speak() çağrısı sessiz kalabilir. Bu ilk
    // kurulumda sesleri önceden isteyip tarayıcının onları yüklemesi için
    // bir fırsat vermiş oluyoruz.
    try {
      await _tts.getVoices;
    } catch (_) {
      // Bazı platformlarda desteklenmeyebilir, önemli değil.
    }
  }

  Future<void> speak(String text, {required String languageCode}) async {
    try {
      await _ensureConfigured();
      if (_language != languageCode) {
        await _tts.setLanguage(languageCode);
        _language = languageCode;
      }
      await _tts.stop();
      final result = await _tts.speak(text);
      debugPrint('SpeechService: speak("$text", $languageCode) -> $result');
    } catch (e, stackTrace) {
      // Cihaz/tarayıcı seslendirmeyi desteklemiyorsa oyun akışını bozmasın,
      // ama nedeni konsolda görünür kalsın (aksi halde sessiz başarısızlık
      // teşhis edilemez).
      debugPrint('SpeechService: speak failed for "$text": $e\n$stackTrace');
    }
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Bkz. speak.
    }
  }
}
