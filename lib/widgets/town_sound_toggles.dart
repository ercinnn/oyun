import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';

/// Ses efekti ve müzik anahtarları (`AppBar.actions` için). Tercih cihazda
/// saklanır; ikonlar açık/kapalı durumu gösterir, isim [Tooltip]'te kalır
/// (dar telefon ekranında iki etiketli düğme sığmaz).
class TownSoundToggles extends StatelessWidget {
  const TownSoundToggles({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TownController>();
    final profile = controller.profile;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('townSoundToggle'),
          tooltip: profile.soundOn ? 'Ses efektleri açık' : 'Ses efektleri kapalı',
          onPressed: controller.toggleSound,
          icon: Icon(profile.soundOn ? Icons.volume_up : Icons.volume_off),
        ),
        IconButton(
          key: const Key('townMusicToggle'),
          tooltip: profile.musicOn ? 'Müzik açık' : 'Müzik kapalı',
          onPressed: controller.toggleMusic,
          icon: Icon(profile.musicOn ? Icons.music_note : Icons.music_off),
        ),
      ],
    );
  }
}
