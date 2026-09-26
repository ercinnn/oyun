import 'package:shared_preferences/shared_preferences.dart';

import '../data/science_sound_clips.dart';
import 'audio/clip_player.dart';

/// Bilim İnsanları oyunlarının ses olayları. Klipler
/// `data/science_sound_clips.dart`'tadır.
enum ScienceSound {
  // Görev akışı (ortak tabanda çalınır).
  correct,
  wrong,
  fanfare,
  turn,

  // Genel.
  click,
  tick,
  ding,

  // Deneyler.
  splash,
  bubbles,
  knock,
  trickle,
  whoosh,
  boing,
  clink,
  zap,
  powerUp,
  scratch,
  rumble,
  geiger,
}

/// Kontrolcünün tanıdığı ses arayüzü (kasabadaki `TownSounds` ile aynı
/// yaklaşım): testler kaydeden bir sahte verir; hiç verilmezse oyun tamamen
/// sessizdir ve ses düğmesi görünmez.
abstract class ScientistSounds {
  /// Ses açık mı (kullanıcının tercihi, [load] ile okunur).
  bool get enabled;
  set enabled(bool value);

  /// Kaydedilmiş tercihi okur. Hata verirse varsayılan (açık) kalır.
  Future<void> load();

  void play(ScienceSound sound);

  void dispose();
}

/// Kodla sentezlenen kliplerle çalan uygulama. Tercih tüm bilim insanları
/// için tektir (`shared_preferences`'ta [prefsKey]); ses çalma ve tercih
/// kaydı **yan servistir**, hataları yutulur ve oyunu asla bozmaz.
class ClipScientistSounds implements ScientistSounds {
  ClipScientistSounds({ClipPlayer? player})
    : _player = player ?? createClipPlayer();

  static const prefsKey = 'scientists_sound_on';

  final ClipPlayer _player;
  bool _enabled = true;

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) {
    _enabled = value;
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(prefsKey, value);
      } catch (_) {}
    }();
  }

  @override
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(prefsKey) ?? true;
    } catch (_) {}
  }

  @override
  void play(ScienceSound sound) {
    if (!_enabled) return;
    final clip = scienceSoundClips[sound];
    if (clip != null) _player.play(clip);
  }

  @override
  void dispose() => _player.dispose();
}

ScientistSounds createScientistSounds() => ClipScientistSounds();
