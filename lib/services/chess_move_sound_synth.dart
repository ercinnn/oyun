import 'dart:math';
import 'dart:typed_data';

import 'audio/biquad.dart';
import 'audio/wav.dart';
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

  final bodyLowpass = Biquad()..lowpass(recipe.bodyLowpassHz, sampleRate);
  final impactHighpass = [for (final _ in recipe.impacts) Biquad()];
  // Her (temas, çınlama) çifti kendi süzgeç durumunu taşır.
  final ringFilters = [
    for (final _ in recipe.impacts)
      [
        for (final r in recipe.ringModes)
          Biquad()..bandpass(r.hz, sampleRate, r.q),
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
  return encodeWav16(pcm, sampleRate);
}
