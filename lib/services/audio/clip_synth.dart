import 'dart:math';
import 'dart:typed_data';

import 'biquad.dart';
import 'sound_clip.dart';
import 'wav.dart';

/// [SoundClip]'i örneklere çevirir. **Tek yorumlayıcı vardır**: web'de de
/// bu örnekler bir Web Audio tamponuna kopyalanır, diğer platformlarda aynı
/// örnekler WAV'a çevrilip çalınır. (Satranç hamle sesleri bunun aksine iki
/// ayrı yorumlayıcı taşır — burada o tuzak bilerek tekrarlanmıyor.)
///
/// Saf Dart'tır ve deterministiktir: gürültü [random] ile üretilir, verilmezse
/// sabit bir tohum kullanılır (aynı klip her çalınışta aynı duyulur; çeşitlilik
/// gereken yerde birden fazla klip tanımlanır, bkz. `townStepClips`).
Float32List renderClip(SoundClip clip, {Random? random}) {
  final sampleRate = clip.sampleRate;
  final total = (sampleRate * clip.totalMs / 1000).ceil();
  final out = Float32List(total);
  final rng = random ?? Random(7);

  for (final voice in clip.voices) {
    final start = (voice.atMs / 1000 * sampleRate).round();
    final length = (voice.durMs / 1000 * sampleRate).round();
    if (length <= 0) continue;

    final attack = max(1, (voice.attackMs / 1000 * sampleRate).round());
    final release = max(1, (voice.effectiveReleaseMs / 1000 * sampleRate).round());
    final sweeping = voice.lowpassHz != null && voice.lowpassEndHz != null;
    final lowpass = voice.lowpassHz == null ? null : Biquad();
    if (lowpass != null && !sweeping) {
      lowpass.lowpass(voice.lowpassHz!, sampleRate);
    }

    var phase = 0.0;
    for (var i = 0; i < length; i++) {
      final n = start + i;
      if (n >= total) break;
      final u = i / length;

      var sample = 0.0;
      if (voice.wave == ToneWave.noise) {
        sample = rng.nextDouble() * 2 - 1;
      } else {
        final hz = voice.endHz == null
            ? voice.hz
            : voice.hz * pow(voice.endHz! / voice.hz, u).toDouble();
        phase += hz / sampleRate;
        phase -= phase.floor();
        sample = switch (voice.wave) {
          // Hepsi 0'dan başlar: nota başında tık (discontinuity) olmasın.
          ToneWave.sine => sin(2 * pi * phase),
          ToneWave.triangle => phase < 0.25
              ? 4 * phase
              : (phase < 0.75 ? 2 - 4 * phase : 4 * phase - 4),
          ToneWave.saw => phase < 0.5 ? 2 * phase : 2 * phase - 2,
          ToneWave.square => phase < 0.5 ? 1.0 : -1.0,
          ToneWave.noise => 0.0,
        };
      }

      if (lowpass != null) {
        if (sweeping) {
          final cutoff = voice.lowpassHz! *
              pow(voice.lowpassEndHz! / voice.lowpassHz!, u).toDouble();
          lowpass.lowpass(cutoff, sampleRate);
        }
        sample = lowpass.process(sample);
      }

      final double envelope;
      if (i < attack) {
        envelope = i / attack;
      } else if (i >= length - release) {
        final remaining = (length - i) / release;
        envelope = remaining * remaining;
      } else {
        envelope = 1;
      }

      if (n >= 0) out[n] += sample * voice.gain * envelope;
    }
  }

  for (var i = 0; i < total; i++) {
    out[i] = (out[i] * clip.gain).clamp(-1.0, 1.0).toDouble();
  }
  return out;
}

/// [clip]'in WAV baytları (web dışı platformlarda `audioplayers` bunu çalar).
Uint8List renderClipWav(SoundClip clip, {Random? random}) =>
    encodeWavFromFloat(renderClip(clip, random: random), clip.sampleRate);

final _wavCache = <SoundClip, Uint8List>{};

/// [renderClipWav]'ın önbellekli hâli: aynı klip yalnızca bir kez sentezlenir
/// (müzik döngüsü birkaç yüz kilobayttır, her girişte yeniden üretilmemeli).
Uint8List cachedClipWav(SoundClip clip) =>
    _wavCache.putIfAbsent(clip, () => renderClipWav(clip));
