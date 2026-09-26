import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/curie_controller.dart';
import '../data/scientists_catalog.dart';
import '../screens/curie_explore_screen.dart';
import '../screens/scientist/scientist_game_config.dart';
import '../screens/scientist/scientist_game_root.dart';
import '../services/scientist_sounds.dart';
import '../widgets/curie/curie_scene_view.dart';

/// "Bilim İnsanları" altındaki Marie Curie oyunu (radyoaktiviteyi sayaçla
/// keşfetmek, ışın türleri ve kalkanlar, ışınla tedavi).
class CurieGame extends StatelessWidget {
  const CurieGame({super.key});

  static const routeName = '/games/bilim-insanlari/curie';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CurieController()..attachSounds(createScientistSounds()),
      child: const CurieGameRoot(),
    );
  }
}

const curieConfig = ScientistGameConfig(
  scientist: curieScientist,
  title: 'Curie\'nin Laboratuvarı',
  banner: '⚗️ ☢️ 🏅',
  intro: 'Marie Curie, bazı taşların görünmez ışınlar yaydığını ölçtü ve buna '
      '"radyoaktivite" dedi. Polonyum ve radyumu keşfetti; iki farklı alanda '
      'Nobel Ödülü kazanan ilk bilim insanı oldu. Çalışmaları kanser '
      'tedavisinin önünü açtı. Sen de onun gibi ölç ve keşfet — ama gerçek '
      'radyoaktif maddelere asla dokunma!',
  exploreTitle: 'Curie\'nin Laboratuvarı',
  exploreHint: 'Laboratuvarda numuneleri sayaçla tarar, ışınların önüne kalkan '
      'koyar ve bir tedavi planı yaparsın.',
  moral: 'Işımayı gözle göremeyiz ama ölçebiliriz. Uzaklık ve kalkan korur. '
      'Birçok yönden gelen zayıf ışınlar tümörde buluşur, sağlıklı dokuyu korur.',
);

class CurieGameRoot extends StatelessWidget {
  const CurieGameRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ScientistGameRoot<CurieController>(
      config: curieConfig,
      sceneBuilder: (c) => CurieSceneView(scene: c.scene),
      exploreBuilder: (_) => const CurieExploreScreen(),
    );
  }
}
