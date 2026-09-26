import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/einstein_controller.dart';
import '../data/scientists_catalog.dart';
import '../screens/einstein_explore_screen.dart';
import '../screens/scientist/scientist_game_config.dart';
import '../screens/scientist/scientist_game_root.dart';
import '../services/scientist_sounds.dart';
import '../widgets/einstein/einstein_scene_view.dart';

/// "Bilim İnsanları" altındaki Einstein oyunu (uzay-zamanın bükülmesi, hızla
/// yavaşlayan zaman, E=mc²).
class EinsteinGame extends StatelessWidget {
  const EinsteinGame({super.key});

  static const routeName = '/games/bilim-insanlari/einstein';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EinsteinController()..attachSounds(createScientistSounds()),
      child: const EinsteinGameRoot(),
    );
  }
}

const einsteinConfig = ScientistGameConfig(
  scientist: einsteinScientist,
  title: 'Einstein\'ın Laboratuvarı',
  banner: '🌌 ⏱️ ⚡',
  intro: 'Albert Einstein hayal gücüyle deney yapardı: "Bir ışık ışınının '
      'üstünde gitseydim ne görürdüm?" Görelilik Teorisi\'yle kütlenin uzayı '
      'büktüğünü, hızla giden saatin yavaşladığını, E = mc² ile de minicik bir '
      'kütlenin dev bir enerji olduğunu gösterdi. Sen de onun gibi düşün!',
  exploreTitle: 'Einstein\'ın Laboratuvarı',
  exploreHint: 'Laboratuvarda uzay-zaman örtüsüne bilye fırlatır, ışık hızına '
      'yakın gemiyle yolculuğa çıkar ve minik kütleleri enerjiye çevirirsin.',
  moral: 'Kütle uzay-zamanı büker; hızlı giden saat yavaş işler; kütle çok '
      'yoğun bir enerjidir: E = m·c².',
);

class EinsteinGameRoot extends StatelessWidget {
  const EinsteinGameRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ScientistGameRoot<EinsteinController>(
      config: einsteinConfig,
      sceneBuilder: (c) => EinsteinSceneView(scene: c.scene),
      exploreBuilder: (_) => const EinsteinExploreScreen(),
    );
  }
}
