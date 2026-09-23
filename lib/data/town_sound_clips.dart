import '../services/audio/sound_clip.dart';

/// Renkli Kasaba'nın tüm sesleri: **harici ses dosyası yoktur**, hepsi burada
/// veri olarak tanımlanır ve `clip_synth.dart` tarafından anında sentezlenir
/// (`pubspec.yaml`'a asset eklenmez). Yeni bir ses eklerken buraya bir klip,
/// `TownSounds`'a bir metot ve `TownController`'a tetikleyen satırı ekle.
///
/// Perdeler `noteHz` ile nota adından gelir; efektler C majör pentatonik
/// üstünde kaldığı için müzik döngüsüyle uyumsuz duymaz.

// ─────────────────────────── Efektler ───────────────────────────

/// Ayak sesi: alçak geçirenden geçen çok kısa gürültü + hafif bir "tok" ton.
/// Sürekli duyulduğu için en kısık ses; iki varyant dönüşümlü çalınır
/// (klipler önbelleğe alındığından tek klip robotik tekrar ederdi).
SoundClip _stepClip(String note, double cutoffHz) => SoundClip(
  gain: 0.22,
  voices: [
    ToneSpec(
      durMs: 55,
      wave: ToneWave.noise,
      gain: 0.75,
      attackMs: 1,
      lowpassHz: cutoffHz,
      lowpassEndHz: cutoffHz * 0.35,
    ),
    ToneSpec(durMs: 60, hz: noteHz(note), gain: 0.35, attackMs: 1),
  ],
);

final townStepClips = [_stepClip('D3', 900), _stepClip('C3', 780)];

/// Altın: klasik iki notalı "ding" (B5 → E6).
final townCoinClip = SoundClip(
  gain: 0.5,
  voices: [
    ToneSpec(
      durMs: 70,
      hz: noteHz('B5'),
      wave: ToneWave.triangle,
      gain: 0.8,
      attackMs: 2,
      releaseMs: 55,
    ),
    ToneSpec(
      atMs: 65,
      durMs: 200,
      hz: noteHz('E6'),
      wave: ToneWave.triangle,
      gain: 0.8,
      attackMs: 2,
    ),
  ],
);

/// Yıldız: dört notalı yukarı arpej (altından belirgin biçimde farklı).
final townStarClip = SoundClip(
  gain: 0.5,
  voices: [
    for (final (index, note) in ['C6', 'E6', 'G6', 'C7'].indexed)
      ToneSpec(
        atMs: index * 55,
        durMs: index == 3 ? 340 : 70,
        hz: noteHz(note),
        wave: ToneWave.triangle,
        gain: 0.7,
        attackMs: 2,
      ),
  ],
);

/// Kapının yanına gelindi: kısa, nazik bir "burada bir şey var" ipucu.
final townDoorNearClip = SoundClip(
  gain: 0.3,
  voices: [
    ToneSpec(durMs: 60, hz: noteHz('G5'), gain: 0.7, attackMs: 3),
    ToneSpec(atMs: 55, durMs: 110, hz: noteHz('C6'), gain: 0.7, attackMs: 3),
  ],
);

/// Kapı açılışı: süpürülen gürültü (sürtünme) + alçak bir tok vuruş.
final townDoorOpenClip = SoundClip(
  gain: 0.42,
  voices: [
    const ToneSpec(
      durMs: 260,
      wave: ToneWave.noise,
      gain: 0.55,
      attackMs: 12,
      lowpassHz: 2200,
      lowpassEndHz: 350,
    ),
    ToneSpec(durMs: 220, hz: noteHz('F2'), gain: 0.5, attackMs: 4),
  ],
);

/// Satın alma: üç notalı yükselen zil.
final townPurchaseClip = SoundClip(
  gain: 0.45,
  voices: [
    for (final (index, note) in ['G5', 'C6', 'E6'].indexed)
      ToneSpec(
        atMs: index * 90,
        durMs: index == 2 ? 300 : 95,
        hz: noteHz(note),
        wave: ToneWave.triangle,
        gain: 0.75,
        attackMs: 3,
      ),
  ],
);

/// Altın yetmedi / hamle geçersiz: iki notalı inen, hafif "boğuk" uyarı.
final townDeniedClip = SoundClip(
  gain: 0.3,
  voices: [
    ToneSpec(
      durMs: 110,
      hz: noteHz('A4'),
      wave: ToneWave.square,
      gain: 0.6,
      attackMs: 4,
      lowpassHz: 1300,
    ),
    ToneSpec(
      atMs: 105,
      durMs: 200,
      hz: noteHz('E4'),
      wave: ToneWave.square,
      gain: 0.6,
      attackMs: 4,
      lowpassHz: 1100,
    ),
  ],
);

/// Odaya eşya koyma / döndürme / kaldırma: tek kısa tık.
final townPlaceClip = SoundClip(
  gain: 0.3,
  voices: [
    ToneSpec(durMs: 45, hz: noteHz('C6'), wave: ToneWave.triangle, gain: 0.7, attackMs: 1),
    const ToneSpec(
      durMs: 28,
      wave: ToneWave.noise,
      gain: 0.3,
      attackMs: 1,
      lowpassHz: 4000,
    ),
  ],
);

/// Sandık bulundu (Hazine Avı): satın almadan daha gösterişli, uzun kuyruklu.
final townChestClip = SoundClip(
  gain: 0.5,
  voices: [
    for (final (index, note) in ['C5', 'G5', 'C6', 'E6'].indexed)
      ToneSpec(
        atMs: index * 90,
        durMs: index == 3 ? 460 : 95,
        hz: noteHz(note),
        wave: ToneWave.triangle,
        gain: 0.7,
        attackMs: 3,
      ),
    const ToneSpec(
      atMs: 270,
      durMs: 420,
      wave: ToneWave.noise,
      gain: 0.12,
      attackMs: 20,
      lowpassHz: 7000,
    ),
  ],
);

/// Varile/suya çarpma (Engelli Parkur): inen testere + boğuk gürültü.
final townBumpClip = SoundClip(
  gain: 0.45,
  voices: [
    const ToneSpec(
      durMs: 210,
      hz: 320,
      endHz: 110,
      wave: ToneWave.saw,
      gain: 0.6,
      attackMs: 2,
      lowpassHz: 1400,
    ),
    const ToneSpec(
      durMs: 90,
      wave: ToneWave.noise,
      gain: 0.45,
      attackMs: 1,
      lowpassHz: 900,
    ),
  ],
);

/// Mini oyun başlangıcı: iki kısa, bir uzun (yarış başlangıcı gibi).
final townGameStartClip = SoundClip(
  gain: 0.4,
  voices: [
    ToneSpec(durMs: 130, hz: noteHz('A5'), wave: ToneWave.triangle, gain: 0.7, attackMs: 3),
    ToneSpec(atMs: 180, durMs: 130, hz: noteHz('A5'), wave: ToneWave.triangle, gain: 0.7, attackMs: 3),
    ToneSpec(atMs: 360, durMs: 340, hz: noteHz('E6'), wave: ToneWave.triangle, gain: 0.8, attackMs: 3),
  ],
);

/// Mini oyun kazanıldı (puan > 0).
final townWinClip = SoundClip(
  gain: 0.45,
  voices: [
    for (final (index, note) in ['C6', 'E6', 'G6', 'C7'].indexed)
      ToneSpec(
        atMs: index * 120,
        durMs: index == 3 ? 520 : 125,
        hz: noteHz(note),
        wave: ToneWave.triangle,
        gain: 0.75,
        attackMs: 3,
      ),
    ToneSpec(atMs: 360, durMs: 520, hz: noteHz('E6'), gain: 0.35, attackMs: 8),
  ],
);

/// Mini oyun kaybedildi (puan 0 / süre bitti): inen üç nota.
final townLoseClip = SoundClip(
  gain: 0.38,
  voices: [
    for (final (index, note) in ['G5', 'E5', 'C5'].indexed)
      ToneSpec(
        atMs: index * 180,
        durMs: index == 2 ? 460 : 185,
        hz: noteHz(note),
        wave: ToneWave.triangle,
        gain: 0.7,
        attackMs: 6,
      ),
  ],
);

// ─────────────────────────── Müzik döngüsü ───────────────────────────

/// 100 BPM'de bir vuruş (ms). Döngü 16 vuruş = 4 ölçü = 9,6 saniyedir.
const double _beatMs = 600;
const double _loopBeats = 16;

/// Notalar arasında bırakılan kısa boşluk: hem notalar ayrışır hem de son
/// notanın sönümü döngü dikişine taşmaz (zarf `durMs` içinde bittiği için
/// döngü dikişsiz olur).
const double _gapMs = 30;

ToneSpec _musicNote(
  String note,
  double beat,
  double beats, {
  ToneWave wave = ToneWave.triangle,
  double gain = 0.42,
  double attackMs = 10,
  double? releaseMs,
}) => ToneSpec(
  atMs: beat * _beatMs,
  durMs: beats * _beatMs - _gapMs,
  hz: noteHz(note),
  wave: wave,
  gain: gain,
  attackMs: attackMs,
  releaseMs: releaseMs,
);

/// Ezgi: C – Am – F – G, C majör pentatonik üstünde neşeli bir tema.
const List<(double, double, String)> _melody = [
  // 1. ölçü (C)
  (0.0, 0.5, 'G5'), (0.5, 0.5, 'E5'), (1.0, 1.0, 'C6'),
  (2.0, 0.5, 'A5'), (2.5, 0.5, 'G5'), (3.0, 1.0, 'E5'),
  // 2. ölçü (Am)
  (4.0, 0.5, 'A5'), (4.5, 0.5, 'C6'), (5.0, 1.0, 'E6'),
  (6.0, 0.5, 'D6'), (6.5, 0.5, 'C6'), (7.0, 1.0, 'A5'),
  // 3. ölçü (F)
  (8.0, 0.5, 'F5'), (8.5, 0.5, 'A5'), (9.0, 1.0, 'C6'),
  (10.0, 0.5, 'A5'), (10.5, 0.5, 'F5'), (11.0, 1.0, 'G5'),
  // 4. ölçü (G)
  (12.0, 0.5, 'G5'), (12.5, 0.5, 'B5'), (13.0, 1.0, 'D6'),
  (14.0, 1.0, 'B5'), (15.0, 1.0, 'G5'),
];

/// Bas: her ölçüde iki yarım nota (akor kökleri ve beşlileri).
const List<(double, double, String)> _bass = [
  (0.0, 2.0, 'C3'), (2.0, 2.0, 'G3'),
  (4.0, 2.0, 'A3'), (6.0, 2.0, 'E3'),
  (8.0, 2.0, 'F3'), (10.0, 2.0, 'C3'),
  (12.0, 2.0, 'G3'), (14.0, 2.0, 'D3'),
];

/// Kasaba müziği: kısa, dikişsiz döngü. 22050 Hz'de üretilir — ezgi 1,6 kHz'in
/// altında kaldığı için duyulur bir kayıp yoktur ve sentez maliyeti/bellek
/// yarıya iner (döngü 9,6 saniyedir, tek seferde sentezlenip önbelleğe alınır).
final townMusicClip = SoundClip(
  gain: 0.24,
  sampleRate: 22050,
  loopMs: _loopBeats * _beatMs,
  voices: [
    for (final (beat, beats, note) in _melody) _musicNote(note, beat, beats),
    for (final (beat, beats, note) in _bass)
      _musicNote(
        note,
        beat,
        beats,
        wave: ToneWave.sine,
        gain: 0.5,
        attackMs: 20,
        releaseMs: 200,
      ),
    // Sekizlik ara vuruşlarda çok kısık bir gürültü tıkı (ritim duyulsun).
    for (var eighth = 0.5; eighth < _loopBeats; eighth += 1)
      ToneSpec(
        atMs: eighth * _beatMs,
        durMs: 26,
        wave: ToneWave.noise,
        gain: 0.06,
        attackMs: 1,
        lowpassHz: 7000,
        lowpassEndHz: 3000,
      ),
  ],
);
