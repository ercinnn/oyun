import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'chess_move_sound_base.dart';
import 'chess_move_sound_recipe.dart';

ChessMoveSounds createPlatformMoveSounds() => WebAudioMoveSounds();

/// Web Audio API ile, harici dosya olmadan üretilen hamle sesleri.
///
/// Her çalınışta küçük bir düğüm grafiği kurulur (gürültü patlaması →
/// yüksek geçiren süzgeç, sinüs osilatörler → alçak geçiren süzgeç,
/// band-geçiren çınlamalar → zarf kazancı → çıkış). Bellek sızıntısı
/// olmasın diye grafik kendini temizler: her kaynak (osilatör/tampon
/// kaynağı) bitince sayılır, hepsi bittiğinde tüm düğümlerin bağlantısı
/// `disconnect()` ile kesilir ve referanslar bırakılır. Gürültü tamponları
/// çalınışa özel oluşturulur (aynı gürültü tekrar etmesin) ve kaynak
/// bittiğinde çöp toplayıcıya bırakılır.
class WebAudioMoveSounds implements ChessMoveSounds {
  WebAudioMoveSounds({Random? random}) : _random = random ?? Random();

  final Random _random;
  web.AudioContext? _context;
  bool _disposed = false;

  @override
  void playNormalMove() => _play(normalMoveRecipe);

  @override
  void playCaptureSound() => _play(captureRecipe);

  @override
  void playCheckSound() => _play(checkRecipe);

  void _play(SoundRecipe base) {
    if (_disposed) return;
    try {
      // Tarayıcılar sesi ancak kullanıcı etkileşiminden sonra başlatır;
      // AudioContext ilk hamlede (bir dokunuşun sonucu) oluşturulur ve
      // askıdaysa devam ettirilir.
      final ctx = _context ??= web.AudioContext();
      if (ctx.state == 'suspended') {
        ctx.resume();
      }
      _schedule(ctx, base.randomized(_random));
    } catch (_) {
      // Ses çalınamazsa (desteksiz tarayıcı vb.) oyun bozulmasın.
    }
  }

  void _schedule(web.AudioContext ctx, SoundRecipe r) {
    final t0 = ctx.currentTime + 0.005;
    final nodes = <web.AudioNode>[];
    var pendingSources = 0;

    void onSourceEnded() {
      pendingSources--;
      if (pendingSources > 0) return;
      for (final node in nodes) {
        try {
          node.disconnect();
        } catch (_) {}
      }
      nodes.clear();
    }

    void trackSource(web.AudioScheduledSourceNode source) {
      pendingSources++;
      source.onended = ((web.Event _) => onSourceEnded()).toJS;
      nodes.add(source);
    }

    // Ana zarf kazancı: her şey buradan çıkışa gider.
    final master = ctx.createGain()..gain.value = r.gain;
    master.connect(ctx.destination);
    nodes.add(master);

    // Gövde çınlamalarının ortak alçak geçiren süzgeci.
    final bodyLowpass = ctx.createBiquadFilter()
      ..type = 'lowpass'
      ..frequency.value = r.bodyLowpassHz;
    bodyLowpass.connect(master);
    nodes.add(bodyLowpass);

    final attack = r.attackMs / 1000;
    final decay = r.decayMs / 1000;

    web.GainNode envelope(double start, double peak) {
      final g = ctx.createGain();
      g.gain
        ..setValueAtTime(0.0001, start)
        ..linearRampToValueAtTime(peak, start + attack)
        ..exponentialRampToValueAtTime(0.0001, start + attack + decay);
      nodes.add(g);
      return g;
    }

    for (final impact in r.impacts) {
      final start = t0 + impact.atMs / 1000;

      // 1) Tık: yüksek geçiren süzgeçli beyaz gürültü, süzgeç hızla süpürülür.
      final clickLen = impact.clickMs / 1000;
      final noise = _noiseSource(ctx, clickLen + 0.01);
      final highpass = ctx.createBiquadFilter()..type = 'highpass';
      highpass.frequency
        ..setValueAtTime(impact.hpStartHz, start)
        ..exponentialRampToValueAtTime(
          impact.hpEndHz,
          start + impact.sweepMs / 1000,
        );
      final clickGain = ctx.createGain();
      clickGain.gain
        ..setValueAtTime(impact.noiseGain, start)
        ..exponentialRampToValueAtTime(0.001, start + clickLen);
      noise.connect(highpass);
      highpass.connect(clickGain);
      clickGain.connect(master);
      nodes.addAll([highpass, clickGain]);
      trackSource(noise);
      noise.start(start);
      noise.stop(start + clickLen + 0.01);

      // 2) Gövde çınlaması: sinüs harmonikler, atak + üstel sönüm.
      if (impact.bodyGain > 0) {
        final bodyEnv = envelope(start, impact.bodyGain);
        bodyEnv.connect(bodyLowpass);
        for (final mode in r.bodyModes) {
          final osc = ctx.createOscillator()
            ..type = 'sine'
            ..frequency.value = mode.hz;
          final modeGain = ctx.createGain()..gain.value = mode.gain;
          osc.connect(modeGain);
          modeGain.connect(bodyEnv);
          nodes.add(modeGain);
          trackSource(osc);
          osc.start(start);
          osc.stop(start + attack + decay + 0.02);
        }
      }

      // 3) Çınlama: dar bantlı band-geçiren süzgeçler (marimba benzeri
      // ahşap tınısı). Gürültü patlaması süzgeci uyarır; net bir perde
      // duyulsun diye altına düşük seviyeli aynı frekansta sinüs eklenir.
      for (final ring in r.ringModes) {
        final ringEnv = envelope(start, ring.gain * 0.5);
        final bandpass = ctx.createBiquadFilter()
          ..type = 'bandpass'
          ..frequency.value = ring.hz
          ..Q.value = ring.q;
        bandpass.connect(ringEnv);
        ringEnv.connect(master);
        nodes.add(bandpass);

        final ringNoise = _noiseSource(ctx, clickLen + 0.01);
        final ringExcite = ctx.createGain()..gain.value = 10;
        ringNoise.connect(ringExcite);
        ringExcite.connect(bandpass);
        nodes.add(ringExcite);
        trackSource(ringNoise);
        ringNoise.start(start);
        ringNoise.stop(start + clickLen + 0.01);

        final tone = ctx.createOscillator()
          ..type = 'sine'
          ..frequency.value = ring.hz;
        final toneGain = ctx.createGain()..gain.value = 0.5;
        tone.connect(toneGain);
        toneGain.connect(bandpass);
        nodes.add(toneGain);
        trackSource(tone);
        tone.start(start);
        tone.stop(start + attack + decay + 0.02);
      }
    }
  }

  /// [seconds] uzunluğunda taze bir beyaz gürültü kaynağı.
  web.AudioBufferSourceNode _noiseSource(web.AudioContext ctx, double seconds) {
    final length = max(1, (ctx.sampleRate * seconds).round());
    final buffer = ctx.createBuffer(1, length, ctx.sampleRate);
    final samples = Float32List.fromList([
      for (var i = 0; i < length; i++) _random.nextDouble() * 2 - 1,
    ]);
    buffer.copyToChannel(samples.toJS, 0);
    return ctx.createBufferSource()..buffer = buffer;
  }

  @override
  void dispose() {
    _disposed = true;
    final ctx = _context;
    _context = null;
    if (ctx != null) {
      try {
        ctx.close();
      } catch (_) {}
    }
  }
}
