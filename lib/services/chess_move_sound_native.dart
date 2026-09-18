import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'chess_move_sound_base.dart';
import 'chess_move_sound_recipe.dart';
import 'chess_move_sound_synth.dart';

ChessMoveSounds createPlatformMoveSounds() => SynthMoveSounds();

/// Web dışı platformlar (Android/masaüstü) için hamle sesleri: Web Audio
/// yok, bu yüzden aynı tarif [renderMoveSoundWav] ile bellekte WAV olarak
/// hesaplanır ve `audioplayers` ile çalınır — diskte/pakette hiç ses dosyası
/// yoktur. Her çalınışta yeni bir oynatıcı açılır ve çalma bitince kapatılır; çalma hata verirse hemen, kalanlar da
/// [dispose]'da kapatılır — oynatıcılar birikmez. (Bilerek zaman aşımı
/// `Timer`'ı yok: widget testlerinde askıda kalan Timer testi bozar.)
class SynthMoveSounds implements ChessMoveSounds {
  SynthMoveSounds({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Set<AudioPlayer> _active = {};
  bool _disposed = false;

  @override
  void playNormalMove() => unawaited(_play(normalMoveRecipe));

  @override
  void playCaptureSound() => unawaited(_play(captureRecipe));

  @override
  void playCheckSound() => unawaited(_play(checkRecipe));

  Future<void> _play(SoundRecipe base) async {
    if (_disposed) return;
    AudioPlayer? player;
    try {
      final bytes = renderMoveSoundWav(base.randomized(_random), _random);
      player = AudioPlayer();
      _active.add(player);
      unawaited(_disposeWhenDone(player));
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(BytesSource(bytes, mimeType: 'audio/wav'));
    } catch (_) {
      // Ses çalınamazsa oyun bozulmasın (bkz. SoundService).
      if (player != null) await _release(player);
    }
  }

  Future<void> _disposeWhenDone(AudioPlayer player) async {
    try {
      await player.onPlayerComplete.first;
    } catch (_) {}
    await _release(player);
  }

  Future<void> _release(AudioPlayer player) async {
    if (!_active.remove(player)) return;
    try {
      await player.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    for (final player in _active.toList()) {
      unawaited(_release(player));
    }
  }
}
