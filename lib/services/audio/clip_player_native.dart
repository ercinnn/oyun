import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'clip_player.dart';
import 'clip_synth.dart';
import 'sound_clip.dart';

ClipPlayer createPlatformClipPlayer() => NativeClipPlayer();

/// Web dışı platformlar (Android/masaüstü): klip bellekte WAV olarak
/// sentezlenir ve `audioplayers` ile çalınır — pakette hiç ses dosyası yoktur.
///
/// Her klip **kendi kalıcı oynatıcısını** tutar ve tekrar çalınırken aynı
/// oynatıcı baştan başlatılır; satrançtaki "her çalınışta yeni oynatıcı"
/// yaklaşımı burada uygun değil, çünkü ayak sesi saniyede iki kez çalıyor ve
/// sürekli oynatıcı açmak Android'de pahalı. Aynı klibin üst üste binmesi
/// (adım sesi) bilerek kesilir. Bilerek zaman aşımı `Timer`'ı yok — widget
/// testlerinde askıda kalan Timer testi bozar.
class NativeClipPlayer implements ClipPlayer {
  final Map<SoundClip, Future<AudioPlayer>> _players = {};
  AudioPlayer? _loopPlayer;
  SoundClip? _loopClip;
  bool _disposed = false;

  @override
  void play(SoundClip clip) => unawaited(_play(clip));

  Future<void> _play(SoundClip clip) async {
    if (_disposed) return;
    final pending = _players.putIfAbsent(
      clip,
      () => _prepare(clip, ReleaseMode.stop),
    );
    try {
      final player = await pending;
      if (_disposed) return;
      await player.stop();
      await player.resume();
    } catch (_) {
      // Ses çalınamazsa oyun bozulmasın. Hazırlık başarısızsa önbellekten
      // düşür: aksi hâlde hatalı `Future` orada kalır ve bu ses bir daha
      // hiç denenmez (geçici bir hata sesi kalıcı olarak susturmasın).
      if (_players[clip] == pending) _players.remove(clip);
    }
  }

  Future<AudioPlayer> _prepare(SoundClip clip, ReleaseMode mode) async {
    final player = AudioPlayer();
    await player.setReleaseMode(mode);
    await player.setSourceBytes(cachedClipWav(clip), mimeType: 'audio/wav');
    return player;
  }

  @override
  void startLoop(SoundClip clip) {
    if (_disposed || _loopClip == clip) return;
    _loopClip = clip;
    unawaited(_startLoop(clip));
  }

  Future<void> _startLoop(SoundClip clip) async {
    try {
      final player = _loopPlayer ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setSourceBytes(cachedClipWav(clip), mimeType: 'audio/wav');
      // Beklerken müzik kapatılmış olabilir.
      if (_disposed || _loopClip != clip) return;
      await player.resume();
    } catch (_) {}
  }

  @override
  void stopLoop() {
    if (_loopClip == null) return;
    _loopClip = null;
    final player = _loopPlayer;
    if (player != null) unawaited(_quietly(player.stop));
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _loopClip = null;
    final loop = _loopPlayer;
    _loopPlayer = null;
    if (loop != null) unawaited(_quietly(loop.dispose));
    for (final pending in _players.values) {
      unawaited(
        pending.then((player) => _quietly(player.dispose)).catchError((_) {}),
      );
    }
    _players.clear();
  }
}
