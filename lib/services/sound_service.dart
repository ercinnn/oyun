import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Kısa oyun efektlerini (bomba, kazanma) çalar. Her efekt için ayrı bir
/// [AudioPlayer] kullanılır ki üst üste tetiklendiğinde birbirini kesmesin.
///
/// Ses baytları [rootBundle] ile doğrudan yüklenip [BytesSource] üzerinden
/// çalınır; [AssetSource]'un web'de asset yolunu "assets/" öneki ile iki kez
/// birleştirip 404 üretmesi riskini (platforma göre değişen davranış) böylece
/// tamamen atlamış oluyoruz.
class SoundService {
  final AudioPlayer _bombPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _winPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  Uint8List? _bombBytes;
  Uint8List? _winBytes;

  Future<Uint8List> _load(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> playBomb() async {
    try {
      _bombBytes ??= await _load('assets/sounds/bomb.wav');
      await _bombPlayer.play(
        BytesSource(_bombBytes!, mimeType: 'audio/wav'),
      );
    } catch (_) {
      // Ses çalma başarısız olursa (ör. tarayıcı autoplay kısıtı, eksik
      // eklenti) oyun akışını bozmasın.
    }
  }

  Future<void> playWin() async {
    try {
      _winBytes ??= await _load('assets/sounds/win.wav');
      await _winPlayer.play(
        BytesSource(_winBytes!, mimeType: 'audio/wav'),
      );
    } catch (_) {
      // Bkz. playBomb.
    }
  }

  void dispose() {
    _bombPlayer.dispose();
    _winPlayer.dispose();
  }
}
