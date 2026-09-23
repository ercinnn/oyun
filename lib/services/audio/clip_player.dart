import 'clip_player_native.dart'
    if (dart.library.js_interop) 'clip_player_web.dart'
    as impl;
import 'sound_clip.dart';

/// [SoundClip]'leri çalan platform katmanı. Ses çalma bir **yan servistir**:
/// her iki uygulama da hataları içeride yutar, oyun asla bozulmaz
/// (bkz. `SoundService`, `SpeechService`).
abstract class ClipPlayer {
  /// Klibi bir kez çalar (aynı klibin çalınışı üst üste binerse baştan başlar).
  void play(SoundClip clip);

  /// [clip]'i sürekli döngüde çalar; zaten aynı klip çalıyorsa hiçbir şey
  /// yapmaz (her karede çağrılabilir).
  void startLoop(SoundClip clip);

  void stopLoop();

  void dispose();
}

ClipPlayer createClipPlayer() => impl.createPlatformClipPlayer();
