// Renkli Kasaba'nın seslerini dinlemek için WAV olarak dışa aktarır.
//
// Kasaba sesleri uygulamada **dosyadan yüklenmez**: kod içindeki tariflerden
// (`lib/data/town_sound_clips.dart`) anında sentezlenir. Bu betik yalnızca bir
// geliştirici aracıdır — tarifi değiştirdikten sonra sonucu kulakla kontrol
// edebilmek için aynı sentezleyiciyi çalıştırıp çıktıyı diske yazar. Yazdığı
// klasör `build/` altındadır, yani depoya girmez ve APK'ya/web derlemesine
// dahil olmaz.
//
// Çalıştırmak için: dart run tool/preview_town_sounds.dart
import 'dart:io';

import 'package:bombali_sayilar/data/town_sound_clips.dart';
import 'package:bombali_sayilar/services/audio/clip_synth.dart';
import 'package:bombali_sayilar/services/audio/sound_clip.dart';

void main(List<String> args) {
  final outPath = args.isEmpty ? 'build/town_sounds' : args.first;
  final clips = <String, SoundClip>{
    'coin': townCoinClip,
    'star': townStarClip,
    'door_near': townDoorNearClip,
    'door_open': townDoorOpenClip,
    'purchase': townPurchaseClip,
    'denied': townDeniedClip,
    'place': townPlaceClip,
    'chest': townChestClip,
    'bump': townBumpClip,
    'game_start': townGameStartClip,
    'win': townWinClip,
    'lose': townLoseClip,
    'music_loop': townMusicClip,
    for (final (index, clip) in townStepClips.indexed) 'step_$index': clip,
  };

  final dir = Directory(outPath);
  if (!dir.existsSync()) dir.createSync(recursive: true);

  clips.forEach((name, clip) {
    final bytes = renderClipWav(clip);
    File('${dir.path}/$name.wav').writeAsBytesSync(bytes);
    stdout.writeln(
      '$name.wav — ${clip.totalMs.round()} ms, '
      '${clip.sampleRate} Hz, ${(bytes.length / 1024).round()} KB',
    );
  });
  stdout.writeln('\n${clips.length} ses ${dir.absolute.path} altına yazıldı.');
}
