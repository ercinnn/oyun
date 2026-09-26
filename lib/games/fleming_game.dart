import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/fleming_controller.dart';
import '../data/scientists_catalog.dart';
import '../screens/fleming_explore_screen.dart';
import '../screens/scientist/scientist_game_config.dart';
import '../screens/scientist/scientist_game_root.dart';
import '../services/scientist_sounds.dart';
import '../widgets/fleming/fleming_scene_view.dart';

/// "Bilim İnsanları" altındaki Alexander Fleming oyunu (penisilinin keşfi,
/// mikroplar ve temizlik, antibiyotiği doğru kullanmak).
class FlemingGame extends StatelessWidget {
  const FlemingGame({super.key});

  static const routeName = '/games/bilim-insanlari/fleming';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FlemingController()..attachSounds(createScientistSounds()),
      child: const FlemingGameRoot(),
    );
  }
}

const flemingConfig = ScientistGameConfig(
  scientist: flemingScientist,
  title: 'Fleming\'in Laboratuvarı',
  banner: '🧫 🔬 💊',
  intro: 'Alexander Fleming tatilden döndüğünde, bakteri ektiği bir kapta küf '
      'ürediğini ve küfün çevresindeki bakterilerin öldüğünü gördü. Böylece '
      'ilk antibiyotik olan penisilini keşfetti ve milyonlarca insanın hayatı '
      'kurtuldu. Sen de onun gibi gözlem yap!',
  exploreTitle: 'Fleming\'in Laboratuvarı',
  exploreHint: 'Laboratuvarda kaplara küf koyar, mikropların nereden geldiğini '
      'dener ve ilacı doğru kullanmanın neden önemli olduğunu görürsün.',
  moral: 'Penisilin bakterileri öldürür. Temizlik mikropları uzak tutar. '
      'Antibiyotik virüslere işe yaramaz ve doktorun dediği kadar kullanılır.',
);

class FlemingGameRoot extends StatelessWidget {
  const FlemingGameRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ScientistGameRoot<FlemingController>(
      config: flemingConfig,
      sceneBuilder: (c) => FlemingSceneView(scene: c.scene),
      exploreBuilder: (_) => const FlemingExploreScreen(),
    );
  }
}
