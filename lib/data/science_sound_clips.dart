import '../services/audio/sound_clip.dart';
import '../services/scientist_sounds.dart';

/// Bilim İnsanları oyunlarının ses efektleri. Kasabadaki gibi **harici ses
/// dosyası yoktur**: her ses burada bir tariftir ve `clip_synth.dart`
/// tarafından anında sentezlenir (`pubspec.yaml`'a asset eklenmez). Yeni bir
/// ses eklerken [ScienceSound]'a bir değer, buraya bir klip ekle; bir test her
/// değerin bir klibi olduğunu doğrular.
///
/// Klipler `final` üst düzey değerlerdir: oynatıcılar sentezlenmiş sesi klip
/// **kimliğine** göre önbelleğe alır, her çalınışta yeni klip üretmek
/// önbelleği boşa çıkarırdı.

// ───────────────────────── Görev akışı ─────────────────────────

/// Doğru cevap: iki notalı yükselen, parlak bir "ding-ding".
final _correct = SoundClip(
  gain: 0.45,
  voices: [
    ToneSpec(durMs: 110, hz: noteHz('E5'), wave: ToneWave.triangle, gain: 0.8, attackMs: 3),
    ToneSpec(atMs: 100, durMs: 320, hz: noteHz('A5'), wave: ToneWave.triangle, gain: 0.8, attackMs: 3),
    ToneSpec(atMs: 100, durMs: 320, hz: noteHz('E6'), gain: 0.25, attackMs: 6),
  ],
);

/// Yanlış cevap: cezalandırıcı değil, yumuşak bir "hımm" (inen iki nota,
/// kare dalga süzülerek boğuklaştırıldı). Açıklama asıl ders olduğu için
/// üzücü bir "bıı" sesi bilerek kullanılmadı.
final _wrong = SoundClip(
  gain: 0.28,
  voices: [
    ToneSpec(durMs: 140, hz: noteHz('D5'), wave: ToneWave.square, gain: 0.55, attackMs: 6, lowpassHz: 1500),
    ToneSpec(atMs: 130, durMs: 260, hz: noteHz('A4'), wave: ToneWave.square, gain: 0.55, attackMs: 6, lowpassHz: 1200),
  ],
);

/// Oyun bitti: dört notalı yükselen fanfar + uzun bir akor kuyruğu.
final _fanfare = SoundClip(
  gain: 0.42,
  voices: [
    for (final (index, note) in ['C5', 'E5', 'G5', 'C6'].indexed)
      ToneSpec(
        atMs: index * 130,
        durMs: index == 3 ? 700 : 135,
        hz: noteHz(note),
        wave: ToneWave.triangle,
        gain: 0.75,
        attackMs: 3,
      ),
    ToneSpec(atMs: 390, durMs: 700, hz: noteHz('E5'), gain: 0.3, attackMs: 10),
    ToneSpec(atMs: 390, durMs: 700, hz: noteHz('G5'), gain: 0.3, attackMs: 10),
  ],
);

/// Sıra öbür oyuncuya geçti: iki notalı nazik çağrı.
final _turn = SoundClip(
  gain: 0.32,
  voices: [
    ToneSpec(durMs: 120, hz: noteHz('G5'), wave: ToneWave.triangle, gain: 0.7, attackMs: 3),
    ToneSpec(atMs: 130, durMs: 220, hz: noteHz('D6'), wave: ToneWave.triangle, gain: 0.7, attackMs: 3),
  ],
);

// ───────────────────────── Genel ─────────────────────────

/// Seçim / istasyon / düğme: tek kısa tık.
final _click = SoundClip(
  gain: 0.25,
  voices: [
    ToneSpec(durMs: 40, hz: noteHz('A5'), wave: ToneWave.triangle, gain: 0.7, attackMs: 1),
    const ToneSpec(durMs: 25, wave: ToneWave.noise, gain: 0.3, attackMs: 1, lowpassHz: 4500),
  ],
);

/// Zaman ilerledi (gece, gün): yumuşak, saat tıkırtısı gibi iki vuruş.
final _tick = SoundClip(
  gain: 0.3,
  voices: [
    ToneSpec(durMs: 35, hz: noteHz('E6'), gain: 0.6, attackMs: 1),
    ToneSpec(atMs: 90, durMs: 60, hz: noteHz('B5'), gain: 0.5, attackMs: 1),
  ],
);

/// Bir sonuç hazır (bekletme bitti, tarla doldu): tek, parlak zil.
final _ding = SoundClip(
  gain: 0.38,
  voices: [
    ToneSpec(durMs: 600, hz: noteHz('C6'), gain: 0.7, attackMs: 2),
    ToneSpec(durMs: 450, hz: noteHz('G6'), gain: 0.25, attackMs: 2),
    ToneSpec(durMs: 300, hz: noteHz('C7'), gain: 0.12, attackMs: 2),
  ],
);

// ───────────────────────── Deneyler ─────────────────────────

/// Suya düşme (Arşimet): cisim ekranda önce düştüğü için ses biraz
/// gecikmeli başlar; süzgeci inen gürültü "şlap" + alçak bir "blop".
final _splash = SoundClip(
  gain: 0.5,
  voices: [
    const ToneSpec(
      atMs: 300,
      durMs: 380,
      wave: ToneWave.noise,
      gain: 0.7,
      attackMs: 4,
      lowpassHz: 5000,
      lowpassEndHz: 500,
    ),
    const ToneSpec(atMs: 300, durMs: 180, hz: 420, endHz: 140, gain: 0.55, attackMs: 3),
  ],
);

/// Kabarcıklar (gemi batıyor, kap boşaltıldı): yükselen kısa "blup"lar.
final _bubbles = SoundClip(
  gain: 0.4,
  voices: [
    for (final (index, hz) in [220.0, 300.0, 260.0, 360.0, 310.0, 420.0].indexed)
      ToneSpec(
        atMs: index * 85.0,
        durMs: 90,
        hz: hz,
        endHz: hz * 1.8,
        gain: 0.6,
        attackMs: 4,
      ),
  ],
);

/// Tahta sandık konuldu: tok bir "tak".
final _knock = SoundClip(
  gain: 0.45,
  voices: [
    const ToneSpec(durMs: 90, hz: 190, endHz: 120, wave: ToneWave.triangle, gain: 0.8, attackMs: 1),
    const ToneSpec(durMs: 40, wave: ToneWave.noise, gain: 0.35, attackMs: 1, lowpassHz: 2200),
  ],
);

/// Vida kolu çevrildi: su şırıltısı gibi kısa, parlak gürültü.
final _trickle = SoundClip(
  gain: 0.22,
  voices: [
    for (var i = 0; i < 3; i++)
      ToneSpec(
        atMs: i * 45.0,
        durMs: 60,
        hz: 900.0 + i * 260,
        endHz: 1500.0 + i * 260,
        gain: 0.4,
        attackMs: 3,
      ),
    const ToneSpec(durMs: 160, wave: ToneWave.noise, gain: 0.25, attackMs: 10, lowpassHz: 3000),
  ],
);

/// Hareket (bırakma, fırlatma): havada süzülen "vuuş".
final _whoosh = SoundClip(
  gain: 0.4,
  voices: [
    const ToneSpec(
      durMs: 420,
      wave: ToneWave.noise,
      gain: 0.7,
      attackMs: 90,
      lowpassHz: 600,
      lowpassEndHz: 3200,
    ),
  ],
);

/// Yay (Newton'un arabası itildi): kayan, titrek "boyng".
final _boing = SoundClip(
  gain: 0.4,
  voices: [
    const ToneSpec(durMs: 320, hz: 180, endHz: 520, wave: ToneWave.triangle, gain: 0.7, attackMs: 2),
    const ToneSpec(durMs: 320, hz: 186, endHz: 530, gain: 0.35, attackMs: 2),
  ],
);

/// Cam (prizma, petri kabı kapağı): yüksek, kısa çınlama.
final _clink = SoundClip(
  gain: 0.3,
  voices: [
    ToneSpec(durMs: 260, hz: noteHz('E7'), gain: 0.6, attackMs: 1),
    ToneSpec(durMs: 180, hz: 3900, gain: 0.3, attackMs: 1),
  ],
);

/// Elektrik (Tesla bobini): cızırtılı, süzgeçsiz gürültü + testere uğultu.
final _zap = SoundClip(
  gain: 0.3,
  voices: [
    const ToneSpec(durMs: 380, wave: ToneWave.noise, gain: 0.55, attackMs: 2, releaseMs: 200),
    const ToneSpec(durMs: 380, hz: 120, wave: ToneWave.saw, gain: 0.4, attackMs: 2, lowpassHz: 1800),
  ],
);

/// Bir şey çalıştı (ışın açıldı, kütle enerjiye dönüştü): yükselen süpürme.
final _powerUp = SoundClip(
  gain: 0.35,
  voices: [
    const ToneSpec(durMs: 520, hz: 160, endHz: 880, wave: ToneWave.saw, gain: 0.5, attackMs: 20, lowpassHz: 900, lowpassEndHz: 3500),
    ToneSpec(atMs: 460, durMs: 420, hz: noteHz('A5'), wave: ToneWave.triangle, gain: 0.5, attackMs: 4),
  ],
);

/// Kalem (Galileo'nun defteri): kısa, sürtünmeli çizgi sesleri.
final _scratch = SoundClip(
  gain: 0.28,
  voices: [
    for (var i = 0; i < 3; i++)
      ToneSpec(
        atMs: i * 110.0,
        durMs: 90,
        wave: ToneWave.noise,
        gain: 0.6,
        attackMs: 8,
        lowpassHz: 6000,
        lowpassEndHz: 2500,
      ),
  ],
);

/// Roket (Einstein'ın ışık gemisi): alçak, giderek güçlenen gürleme.
final _rumble = SoundClip(
  gain: 0.45,
  voices: [
    const ToneSpec(durMs: 900, wave: ToneWave.noise, gain: 0.7, attackMs: 250, lowpassHz: 300, lowpassEndHz: 900),
    const ToneSpec(durMs: 900, hz: 55, endHz: 80, wave: ToneWave.saw, gain: 0.35, attackMs: 250, lowpassHz: 400),
  ],
);

/// Geiger sayacı tıkı (Curie): çok kısa, keskin bir çıtırtı.
final _geiger = SoundClip(
  gain: 0.35,
  voices: [
    const ToneSpec(durMs: 9, wave: ToneWave.noise, gain: 1, attackMs: 0.3),
    const ToneSpec(durMs: 8, hz: 2600, gain: 0.4, attackMs: 0.3),
  ],
);

/// Her [ScienceSound] için klip. Eksik bir değer derlenir ama test yakalar.
final Map<ScienceSound, SoundClip> scienceSoundClips = {
  ScienceSound.correct: _correct,
  ScienceSound.wrong: _wrong,
  ScienceSound.fanfare: _fanfare,
  ScienceSound.turn: _turn,
  ScienceSound.click: _click,
  ScienceSound.tick: _tick,
  ScienceSound.ding: _ding,
  ScienceSound.splash: _splash,
  ScienceSound.bubbles: _bubbles,
  ScienceSound.knock: _knock,
  ScienceSound.trickle: _trickle,
  ScienceSound.whoosh: _whoosh,
  ScienceSound.boing: _boing,
  ScienceSound.clink: _clink,
  ScienceSound.zap: _zap,
  ScienceSound.powerUp: _powerUp,
  ScienceSound.scratch: _scratch,
  ScienceSound.rumble: _rumble,
  ScienceSound.geiger: _geiger,
};
