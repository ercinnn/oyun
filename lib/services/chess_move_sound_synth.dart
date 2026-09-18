import 'dart:math';
import 'dart:typed_data';

import 'chess_move_sound_recipe.dart';

/// Web Audio kullanılamayan platformlarda (Android/masaüstü) aynı
/// [SoundRecipe]'i sample sample hesaplayıp 16-bit mono WAV baytlarına
/// çevirir. Web Audio grafiğinin birebir karşılığıdır: gürültü → süpürmeli
/// yüksek geçiren süzgeç, sinüs harmonikler → alçak geçiren süzgeç, gürültü +
/// sinüs → band-geçiren çınlama; hepsi aynı atak/üstel sönüm zarfıyla.
/// Saf Dart'tır (platform eklentisi yok), bu yüzden birim testle doğrulanır.
Uint8List renderMoveSoundWav(
  SoundRecipe recipe,
  Random random, {
  int sampleRate = 44100,
}) {
  final total = (sampleRate * recipe.totalMs / 1000).ceil();
  final attack = recipe.attackMs / 1000;
  final decay = recipe.decayMs / 1000;

  final bodyLowpass = _Biquad()..lowpass(recipe.bodyLowpassHz, sampleRate);
  final impactHighpass = [for (final _ in recipe.impacts) _Biquad()];
  // Her (temas, çınlama) çifti kendi süzgeç durumunu taşır.
  final ringFilters = [
    for (final _ in recipe.impacts)
      [
        for (final r in recipe.ringModes)
          _Biquad()..bandpass(r.hz, sampleRate, r.q),
      ],
  ];

  double envelope(double local, double peak) {
    if (local < 0) return 0;
    if (local < attack) return 0.0001 + (peak - 0.0001) * (local / attack);
    final d = local - attack;
    if (d > decay) return 0;
    return peak * pow(0.0001 / peak, d / decay);
  }

  final pcm = Int16List(total);
  for (var n = 0; n < total; n++) {
    final t = n / sampleRate;
    var mix = 0.0;
    var body = 0.0;

    for (var i = 0; i < recipe.impacts.length; i++) {
      final impact = recipe.impacts[i];
      final local = t - impact.atMs / 1000;
      if (local < 0) continue;
      final clickLen = impact.clickMs / 1000;

      // Tık: süpürmeli yüksek geçiren süzgeçten geçen beyaz gürültü.
      var noise = 0.0;
      if (local <= clickLen + 0.01) {
        noise = random.nextDouble() * 2 - 1;
        final sweep = min(local / (impact.sweepMs / 1000), 1.0);
        final cutoff = impact.hpStartHz *
            pow(impact.hpEndHz / impact.hpStartHz, sweep);
        impactHighpass[i].highpass(cutoff.toDouble(), sampleRate);
        if (local <= clickLen) {
          final clickEnv =
              impact.noiseGain * pow(0.001 / impact.noiseGain, local / clickLen);
          mix += impactHighpass[i].process(noise) * clickEnv;
        }
      }

      // Gövde çınlaması (ortak alçak geçirenle süzülecek).
      if (impact.bodyGain > 0) {
        final env = envelope(local, impact.bodyGain);
        if (env > 0) {
          for (final mode in recipe.bodyModes) {
            body += sin(2 * pi * mode.hz * local) * mode.gain * env;
          }
        }
      }

      // Band-geçiren çınlamalar: gürültü patlaması ×10 + düşük seviyeli sinüs.
      for (var k = 0; k < recipe.ringModes.length; k++) {
        final ring = recipe.ringModes[k];
        final env = envelope(local, ring.gain * 0.5);
        if (env <= 0) continue;
        final excite = local <= clickLen + 0.01 ? noise * 10 : 0.0;
        final tone = sin(2 * pi * ring.hz * local) * 0.5;
        mix += ringFilters[i][k].process(excite + tone) * env;
      }
    }
    mix += bodyLowpass.process(body);

    final v = (mix * recipe.gain).clamp(-1.0, 1.0);
    pcm[n] = (v * 32767).round();
  }
  return _wav(pcm, sampleRate);
}

Uint8List _wav(Int16List pcm, int sampleRate) {
  final dataLen = pcm.length * 2;
  final bytes = ByteData(44 + dataLen);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLen, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, dataLen, Endian.little);
  for (var i = 0; i < pcm.length; i++) {
    bytes.setInt16(44 + i * 2, pcm[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

/// RBJ "Audio EQ Cookbook" iki kutuplu süzgeci (Web Audio `BiquadFilterNode`
/// ile aynı formüller). Katsayılar örnekler arasında değiştirilebilir; süzgeç
/// durumu korunur (süpürmeli yüksek geçiren için gerekli).
class _Biquad {
  double _b0 = 1, _b1 = 0, _b2 = 0, _a1 = 0, _a2 = 0;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  void _set(double b0, double b1, double b2, double a0, double a1, double a2) {
    _b0 = b0 / a0;
    _b1 = b1 / a0;
    _b2 = b2 / a0;
    _a1 = a1 / a0;
    _a2 = a2 / a0;
  }

  void lowpass(double hz, int sampleRate, [double q = 0.7071]) {
    final w = 2 * pi * hz / sampleRate;
    final c = cos(w);
    final alpha = sin(w) / (2 * q);
    _set((1 - c) / 2, 1 - c, (1 - c) / 2, 1 + alpha, -2 * c, 1 - alpha);
  }

  void highpass(double hz, int sampleRate, [double q = 0.7071]) {
    final w = 2 * pi * hz / sampleRate;
    final c = cos(w);
    final alpha = sin(w) / (2 * q);
    _set((1 + c) / 2, -(1 + c), (1 + c) / 2, 1 + alpha, -2 * c, 1 - alpha);
  }

  /// Sabit 0 dB tepe kazançlı band-geçiren.
  void bandpass(double hz, int sampleRate, double q) {
    final w = 2 * pi * hz / sampleRate;
    final c = cos(w);
    final alpha = sin(w) / (2 * q);
    _set(alpha, 0, -alpha, 1 + alpha, -2 * c, 1 - alpha);
  }

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}
