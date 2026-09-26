import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/galileo_controller.dart';
import '../screens/galileo_explore_screen.dart';
import '../screens/scientist/scientist_game_config.dart';
import '../screens/scientist/scientist_game_root.dart';
import '../widgets/galileo/galileo_scene_view.dart';

/// "Bilim İnsanları" altındaki Galileo oyunu (teleskop, Jüpiter'in uyduları,
/// Güneş merkezli sistem ve Venüs'ün evreleri).
class GalileoGame extends StatelessWidget {
  const GalileoGame({super.key});

  static const routeName = '/games/bilim-insanlari/galileo';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GalileoController(),
      child: const GalileoGameRoot(),
    );
  }
}

const galileoConfig = ScientistGameConfig(
  title: 'Galileo\'nun Gözlemevi',
  banner: '🔭 🪐 🌖',
  intro: 'Galileo 1609\'da kendi teleskobunu yaptı ve gökyüzüne çevirdi. '
      'Ay\'daki dağları, Jüpiter\'in dört uydusunu ve Venüs\'ün Ay gibi '
      'evrelerini gördü. Bunlar, Dünya\'nın ve gezegenlerin Güneş\'in '
      'etrafında döndüğünü gösteriyordu. Sen de onun gibi gözlem yap!',
  exploreTitle: 'Gözlemevi',
  exploreHint: 'Gözlemevi\'nde teleskobu kendin kurup odaklar, Jüpiter\'in '
      'uydularını gece gece deftere çizer ve Güneş sisteminde zamanı '
      'ilerletirsin.',
  moral: 'İki mercek uzağı yakın gösterir. Jüpiter\'in uyduları Jüpiter\'in, '
      'gezegenler Güneş\'in etrafında döner. Gözlem yapmak, tahminden '
      'güçlüdür!',
);

class GalileoGameRoot extends StatelessWidget {
  const GalileoGameRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ScientistGameRoot<GalileoController>(
      config: galileoConfig,
      sceneBuilder: (c) => GalileoSceneView(scene: c.scene),
      exploreBuilder: (_) => const GalileoExploreScreen(),
    );
  }
}
