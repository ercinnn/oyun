import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';
import '../widgets/iso_world_view.dart';
import '../widgets/town_3d_view.dart';
import '../widgets/town_hud.dart';

/// Serbest kasaba: yürü, altın topla, kapılara gir. Çizim `frame` bildirimiyle
/// yenilenir; bu ekran ağacı yalnızca altın/kapı gibi ayrık değişimlerde
/// yeniden kurulur.
class TownWorldScreen extends StatelessWidget {
  const TownWorldScreen({super.key});

  /// Gerçek 3D görünüm (`Town3DView`). Varsayılan: **yalnızca web'de** açık
  /// (three_js orada doğrulandı); VM testlerinde (WebGL yok) ve doğrulanmamış
  /// platformlarda 2B `IsoWorldView`'e düşülür. Android/masaüstünde denemek için
  /// `--dart-define=USE_3D=true` ile derle; doğrulanınca varsayılan genişletilir.
  static bool use3d = kIsWeb || const bool.fromEnvironment('USE_3D');

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
      ),
      body: use3d
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
