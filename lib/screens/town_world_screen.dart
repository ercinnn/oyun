import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/town_3d.dart';
import '../controllers/town_controller.dart';
import '../widgets/iso_world_view.dart';
import '../widgets/town_3d_view.dart';
import '../widgets/town_hud.dart';
import '../widgets/town_sound_toggles.dart';

/// Serbest kasaba: yürü, altın topla, kapılara gir. Çizim `frame` bildirimiyle
/// yenilenir; bu ekran ağacı yalnızca altın/kapı gibi ayrık değişimlerde
/// yeniden kurulur.
class TownWorldScreen extends StatelessWidget {
  const TownWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TownController>();
    final door = controller.doorPrompt;

    final overlay = <Widget>[
      Positioned(
        top: 12,
        left: 12,
        child: CoinChip(coins: controller.profile.coins),
      ),
      Positioned(
        top: 12,
        right: 12,
        child: HudBadge(text: 'Yürü: joystick, ok tuşları ya da tıkla'),
      ),
      if (door != null)
        Positioned(
          right: 16,
          bottom: 24,
          child: FilledButton.icon(
            key: const Key('townEnterDoor'),
            onPressed: controller.enterNearbyDoor,
            icon: Text(door.emoji, style: const TextStyle(fontSize: 20)),
            label: Text('Gir: ${door.label}'),
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renkli Kasaba'),
        // Geri oku oyundan çıkmak yerine kurulum ekranına döner.
        leading: BackButton(onPressed: controller.leaveToSetup),
        actions: const [TownSoundToggles()],
      ),
      body: townUse3d
          ? Town3DView(
              world: controller.world,
              avatar: controller.profile.avatar,
              onTick: controller.tick,
              onInput: controller.setInput,
              onTapTile: controller.tapTile,
              overlay: overlay,
            )
          : IsoWorldView(
              world: controller.world,
              avatar: controller.profile.avatar,
              frame: controller.frame,
              onTick: controller.tick,
              onInput: controller.setInput,
              onTapTile: controller.tapTile,
              overlay: overlay,
            ),
    );
  }
}
