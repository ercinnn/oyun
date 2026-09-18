import 'dart:math';

/// Hamle seslerinin "tarifi": harici ses dosyası yok, her ses osilatör ve
/// gürültüden anlık üretilir. Tarif saf veridir; iki ayrı çalıcı aynı tarifi
/// yorumlar — web'de Web Audio API grafiği (`chess_move_sound_web.dart`),
/// diğer platformlarda (Android/masaüstü) aynı sesi PCM olarak hesaplayan
/// bir sentezleyici (`chess_move_sound_native.dart`). Böylece APK'da da web'deki
/// sesin aynısı duyulur.
enum ChessMoveSoundKind { normal, capture, check }

/// Tek bir temas: yüksek geçiren süzgeçten geçen kısa bir beyaz gürültü
/// patlaması ([hpStartHz] → [hpEndHz] hızlı süpürme) ve isteğe bağlı olarak
/// aynı anda tetiklenen gövde çınlaması ([bodyGain] > 0).
class ImpactSpec {
  const ImpactSpec({
    this.atMs = 0,
    required this.hpStartHz,
    required this.hpEndHz,
    this.sweepMs = 2,
    this.clickMs = 10,
    this.noiseGain = 1,
    this.bodyGain = 1,
  });

  /// Sesin başlangıcına göre bu temasın zamanı.
  final double atMs;
  final double hpStartHz;
  final double hpEndHz;

  /// Süzgeç frekansının hızlı düşüşünün süresi.
  final double sweepMs;

  /// Gürültü patlamasının toplam (üstel sönen) süresi.
  final double clickMs;
  final double noiseGain;
  final double bodyGain;
}

/// Bir gövde harmoniği (sinüs) ve kendi bağıl kazancı.
class ModeSpec {
  const ModeSpec(this.hz, this.gain);
  final double hz;
  final double gain;
}

/// Dar bantlı (yüksek Q) band-geçiren süzgeçle çınlayan bir ahşap harmoniği.
class RingSpec {
  const RingSpec(this.hz, this.gain, {this.q = 25});
  final double hz;
  final double gain;
  final double q;
}

class SoundRecipe {
  const SoundRecipe({
    required this.impacts,
    required this.bodyModes,
    required this.bodyLowpassHz,
    required this.attackMs,
    required this.decayMs,
    required this.gain,
    this.ringModes = const [],
  });

  final List<ImpactSpec> impacts;
  final List<ModeSpec> bodyModes;
  final double bodyLowpassHz;
  final List<RingSpec> ringModes;

  /// Zarf: doğrusal atak, sonra `0.0001`'e üstel sönüm.
  final double attackMs;
  final double decayMs;
  final double gain;

  /// Sesin bittiği an (son temas + atak + sönüm) ve küçük bir kuyruk payı.
  double get totalMs =>
      impacts.map((i) => i.atMs).reduce(max) + attackMs + decayMs + 25;

  /// Her çalınışta tüm frekanslara tek bir ±%[amount] perde sapması ve
  /// tüm kazanca ayrı bir ±%[amount] ses şiddeti sapması uygular; ses
  /// robotik tekrar etmez. Tek çarpan kullanmak harmonik oranlarını korur
  /// (perde kayar ama ses "bozulmaz").
  SoundRecipe randomized(Random random, {double amount = 0.05}) {
    double jitter() => 1 + (random.nextDouble() * 2 - 1) * amount;
    final pitch = jitter();
    final volume = jitter();
    return SoundRecipe(
      impacts: [
        for (final i in impacts)
          ImpactSpec(
            atMs: i.atMs,
            hpStartHz: i.hpStartHz * pitch,
            hpEndHz: i.hpEndHz * pitch,
            sweepMs: i.sweepMs,
            clickMs: i.clickMs,
            noiseGain: i.noiseGain,
            bodyGain: i.bodyGain,
          ),
      ],
      bodyModes: [for (final m in bodyModes) ModeSpec(m.hz * pitch, m.gain)],
      bodyLowpassHz: bodyLowpassHz * pitch,
      ringModes: [
        for (final r in ringModes) RingSpec(r.hz * pitch, r.gain, q: r.q),
      ],
      attackMs: attackMs,
      decayMs: decayMs,
      gain: gain * volume,
    );
  }
}

/// 1) Boş kareye oynama: yumuşak, doğal ahşap teması.
const normalMoveRecipe = SoundRecipe(
  impacts: [ImpactSpec(hpStartHz: 3000, hpEndHz: 800, noiseGain: 0.6)],
  bodyModes: [ModeSpec(300, 1)],
  bodyLowpassHz: 1200,
  attackMs: 1,
  decayMs: 50,
  gain: 0.5,
);

/// 2) Taş yeme: taş-taş teması (0 ms) + 15 ms sonra taş-tahta teması; daha
/// tok ve rezonanslı gövde (450 + 650 Hz), daha uzun ve gür sönüm.
const captureRecipe = SoundRecipe(
  impacts: [
    ImpactSpec(hpStartHz: 4500, hpEndHz: 1500, noiseGain: 1, bodyGain: 0.5),
    ImpactSpec(
      atMs: 15,
      hpStartHz: 3000,
      hpEndHz: 1000,
      noiseGain: 0.7,
      bodyGain: 1,
    ),
  ],
  bodyModes: [ModeSpec(450, 1), ModeSpec(650, 0.6)],
  bodyLowpassHz: 2500,
  attackMs: 1,
  decayMs: 90,
  gain: 0.8,
);

/// 3) Şah: yapay bip yok; ahşap gövdenin üstünde marimba benzeri, dar
/// bantlı 880 Hz (A5) ve 1760 Hz (A6) çınlaması.
const checkRecipe = SoundRecipe(
  impacts: [
    ImpactSpec(hpStartHz: 3500, hpEndHz: 1200, noiseGain: 0.5, bodyGain: 0.7),
  ],
  bodyModes: [ModeSpec(350, 1)],
  bodyLowpassHz: 1500,
  ringModes: [RingSpec(880, 1), RingSpec(1760, 0.55)],
  attackMs: 1,
  decayMs: 180,
  gain: 0.9,
);

SoundRecipe recipeFor(ChessMoveSoundKind kind) => switch (kind) {
  ChessMoveSoundKind.normal => normalMoveRecipe,
  ChessMoveSoundKind.capture => captureRecipe,
  ChessMoveSoundKind.check => checkRecipe,
};
