import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'clip_player.dart';
import 'clip_synth.dart';
import 'sound_clip.dart';

ClipPlayer createPlatformClipPlayer() => WebClipPlayer();

/// Web: klip saf Dart'ta örneklere çevrilir (`renderClip`), bir Web Audio
/// tamponuna kopyalanır ve `AudioBufferSourceNode` ile çalınır. Tampon klip
/// başına bir kez üretilip saklanır; düğüm grafiği kurmaya gerek yoktur, bu
/// yüzden web ve native aynı örnekleri duyurur.
class WebClipPlayer implements ClipPlayer {
  web.AudioContext? _context;
  final Map<SoundClip, web.AudioBuffer> _buffers = {};
  web.AudioBufferSourceNode? _loopSource;
  SoundClip? _loopClip;
  bool _disposed = false;

  /// Tarayıcılar sesi ancak bir kullanıcı etkileşiminden sonra başlatır;
  /// bağlam ilk sesle (bir dokunuşun sonucu) kurulur, askıdaysa sürdürülür.
  web.AudioContext? _ensureContext() {
    if (_disposed) return null;
    final ctx = _context ??= web.AudioContext();
    if (ctx.state == 'suspended') ctx.resume();
    return ctx;
  }

  web.AudioBuffer _bufferFor(web.AudioContext ctx, SoundClip clip) =>
      _buffers.putIfAbsent(clip, () {
        final samples = renderClip(clip);
        final buffer = ctx.createBuffer(
          1,
          samples.length,
          clip.sampleRate.toDouble(),
        );
        buffer.copyToChannel(samples.toJS, 0);
        return buffer;
      });

  @override
  void play(SoundClip clip) {
    try {
      final ctx = _ensureContext();
      if (ctx == null) return;
      final source = ctx.createBufferSource()..buffer = _bufferFor(ctx, clip);
      source.connect(ctx.destination);
      // Bellek sızıntısı olmasın: kaynak bitince bağlantısı kesilir.
      source.onended = ((web.Event _) {
        try {
          source.disconnect();
        } catch (_) {}
      }).toJS;
      source.start();
    } catch (_) {
      // Desteksiz tarayıcıda ses olmasın, oyun bozulmasın.
    }
  }

  @override
  void startLoop(SoundClip clip) {
    if (_disposed || _loopClip == clip) return;
    stopLoop();
    try {
      final ctx = _ensureContext();
      if (ctx == null) return;
      final source = ctx.createBufferSource()
        ..buffer = _bufferFor(ctx, clip)
        ..loop = true;
      source.connect(ctx.destination);
      source.start();
      _loopSource = source;
      _loopClip = clip;
    } catch (_) {}
  }

  @override
  void stopLoop() {
    final source = _loopSource;
    _loopSource = null;
    _loopClip = null;
    if (source == null) return;
    try {
      source.stop();
      source.disconnect();
    } catch (_) {}
  }

  @override
  void dispose() {
    stopLoop();
    _disposed = true;
    _buffers.clear();
    final ctx = _context;
    _context = null;
    if (ctx != null) {
      try {
        ctx.close();
      } catch (_) {}
    }
  }
}
