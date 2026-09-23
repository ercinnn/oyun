import 'dart:math';

/// Bir sesin dalga biçimi.
enum ToneWave {
  sine,
  triangle,
  square,
  saw,

  /// Beyaz gürültü (ayak sesi, kapı sürtünmesi, çarpma gibi perdesiz sesler).
  noise,
}

/// Klip içindeki tek bir ses ("nota" ya da gürültü patlaması).
///
/// Zarf tamamen [durMs] içindedir: [attackMs] boyunca doğrusal yükselir,
/// sonuna kadar sürer ve son [releaseMs] boyunca sıfıra iner. Bu, notaların
/// ayrılmış süresini asla aşmaması demektir — müzik döngüsünün dikişsiz
/// olmasının nedeni budur (bkz. [SoundClip.loopMs]).
class ToneSpec {
  const ToneSpec({
    this.atMs = 0,
    required this.durMs,
    this.hz = 440,
    this.endHz,
    this.wave = ToneWave.sine,
    this.gain = 1,
    this.attackMs = 3,
    this.releaseMs,
    this.lowpassHz,
    this.lowpassEndHz,
  });

  /// Klibin başına göre başlangıç anı.
  final double atMs;

  /// Toplam süre (zarf dahil).
  final double durMs;

  /// Başlangıç frekansı.
  final double hz;

  /// Verilirse frekans [hz] → [endHz] üstel olarak kayar (kayma/whoosh).
  final double? endHz;

  final ToneWave wave;
  final double gain;
  final double attackMs;

  /// Sönüm süresi; verilmezse atak sonrası kalan tüm süre (perküsif).
  final double? releaseMs;

  /// Verilirse ses alçak geçiren süzgeçten geçer; [lowpassEndHz] ile
  /// kesim frekansı süre boyunca üstel olarak süpürülür.
  final double? lowpassHz;
  final double? lowpassEndHz;

  double get effectiveReleaseMs =>
      releaseMs ?? max(0.0, durMs - attackMs);

  double get endMs => atMs + durMs;
}

/// Tek seferde çalınan bir ses (efekt ya da müzik döngüsü). Harici ses dosyası
/// yoktur: `clip_synth.dart` bu tarifi örneklere çevirir, `clip_player.dart`
/// da platforma göre çalar (web'de Web Audio tamponu, diğerlerinde WAV).
class SoundClip {
  const SoundClip({
    required this.voices,
    this.gain = 1,
    this.sampleRate = 44100,
    this.loopMs,
  });

  final List<ToneSpec> voices;

  /// Tüm seslerin toplamına uygulanan kazanç (ardından [-1, 1]'e kırpılır).
  final double gain;
  final int sampleRate;

  /// Döngü uzunluğu: müzik için klibin **tam** süresi (son notanın bitişine
  /// değil bu değere göre kırpılır), böylece döngü dikişi duyulmaz.
  final double? loopMs;

  double get totalMs =>
      loopMs ?? voices.fold(0.0, (best, v) => max(best, v.endMs));
}

const _semitoneOfLetter = {
  'C': 0,
  'D': 2,
  'E': 4,
  'F': 5,
  'G': 7,
  'A': 9,
  'B': 11,
};

/// Nota adını frekansa çevirir: `'A4'` → 440, `'C#5'`, `'Eb3'` de olur.
/// Geçersiz adda [ArgumentError] atar (tarifler derleme zamanı veri olduğu
/// için hata sessizce yutulmamalı).
double noteHz(String name) {
  final letter = name.isEmpty ? '' : name[0].toUpperCase();
  final semitone = _semitoneOfLetter[letter];
  if (semitone == null) throw ArgumentError('Geçersiz nota: $name');
  var index = 1;
  var accidental = 0;
  if (name.length > 1 && (name[1] == '#' || name[1] == 'b')) {
    accidental = name[1] == '#' ? 1 : -1;
    index = 2;
  }
  final octave = int.tryParse(name.substring(index));
  if (octave == null) throw ArgumentError('Geçersiz nota: $name');
  final midi = (octave + 1) * 12 + semitone + accidental;
  return 440 * pow(2, (midi - 69) / 12).toDouble();
}
