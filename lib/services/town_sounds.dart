import '../data/town_sound_clips.dart';
import 'audio/clip_player.dart';

/// Renkli Kasaba'nın ses olayları. Kontrolcü yalnızca bu arayüzü tanır, bu
/// yüzden testler sesi kaydeden bir sahte verebilir (satrançtaki
/// `ChessMoveSounds` ile aynı yaklaşım) ve `TownController` ses verilmezse
/// tamamen sessiz çalışır.
abstract class TownSounds {
  void step();
  void coin();
  void star();

  /// Bir kapının yanına gelindi (kısa ipucu).
  void doorNear();

  /// Kapıdan içeri girildi.
  void doorOpen();

  void purchase();

  /// Altın yetmedi ya da işlem geçersiz.
  void denied();

  /// Odaya eşya koyma / döndürme / kaldırma.
  void placeItem();

  /// Hazine Avı'nda sandık bulundu.
  void chest();

  /// Engelli Parkur'da varile/suya çarpıldı.
  void bump();

  void gameStart();
  void win();
  void lose();

  /// Kasaba müziğini başlatır (zaten çalıyorsa etkisizdir, her karede
  /// çağrılabilir) ve durdurur.
  void startMusic();
  void stopMusic();

  void dispose();
}

/// [TownSounds]'ı kod içinde tanımlı kliplerle ([townMusicClip] vb.) çalan
/// uygulama. Klipleri kim çalacağını bilmez; platform ayrımı
/// `audio/clip_player.dart`'ta.
class ClipTownSounds implements TownSounds {
  ClipTownSounds({ClipPlayer? player}) : _player = player ?? createClipPlayer();

  final ClipPlayer _player;
  int _stepIndex = 0;

  @override
  void step() {
    _player.play(townStepClips[_stepIndex % townStepClips.length]);
    _stepIndex++;
  }

  @override
  void coin() => _player.play(townCoinClip);

  @override
  void star() => _player.play(townStarClip);

  @override
  void doorNear() => _player.play(townDoorNearClip);

  @override
  void doorOpen() => _player.play(townDoorOpenClip);

  @override
  void purchase() => _player.play(townPurchaseClip);

  @override
  void denied() => _player.play(townDeniedClip);

  @override
  void placeItem() => _player.play(townPlaceClip);

  @override
  void chest() => _player.play(townChestClip);

  @override
  void bump() => _player.play(townBumpClip);

  @override
  void gameStart() => _player.play(townGameStartClip);

  @override
  void win() => _player.play(townWinClip);

  @override
  void lose() => _player.play(townLoseClip);

  @override
  void startMusic() => _player.startLoop(townMusicClip);

  @override
  void stopMusic() => _player.stopLoop();

  @override
  void dispose() => _player.dispose();
}

TownSounds createTownSounds() => ClipTownSounds();
