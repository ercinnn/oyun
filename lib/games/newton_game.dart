import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/newton_controller.dart';
import '../data/scientists_catalog.dart';
import '../screens/newton_explore_screen.dart';
import '../screens/scientist/scientist_game_config.dart';
import '../screens/scientist/scientist_game_root.dart';
import '../services/scientist_sounds.dart';
import '../widgets/newton/newton_scene_view.dart';

/// "Bilim İnsanları" altındaki Newton oyunu (kütleçekim ve düşen cisimler,
/// prizma ile ışığın renkleri, hareket yasaları). Kendi [NewtonController]'ını
/// route'a her girişte taze kurar.
class NewtonGame extends StatelessWidget {
  const NewtonGame({super.key});

  static const routeName = '/games/bilim-insanlari/newton';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewtonController()..attachSounds(createScientistSounds()),
      child: const NewtonGameRoot(),
    );
  }
}

const newtonConfig = ScientistGameConfig(
  scientist: newtonScientist,
  title: 'Newton\'un Laboratuvarı',
  banner: '🍎 🌈 🛒',
  intro: 'Bir gün Newton\'un başına bir elma düştü ve düşündü: Elmayı yere '
      'çeken nedir? Güneş ışığını bir prizmadan geçirip renklere ayırdı, '
      'cisimlerin nasıl hareket ettiğini kurallara bağladı. Sen de onun gibi '
      'dene!',
  exploreTitle: 'Keşif Laboratuvarı',
  exploreHint: 'Keşif Laboratuvarı\'nda kuleden cisim bırakır, prizmaya ışık '
      'tutar ve yaylı iticiyle araba yarıştırırsın.',
  moral: 'Dünya her şeyi aynı ivmeyle çeker; farkı hava yaratır. Beyaz ışık '
      'renklerin karışımıdır. Aynı itme, hafif arabayı daha çok hızlandırır.',
);

/// Faza göre ekran seçen kök (geliştirme girişi de kullanır).
class NewtonGameRoot extends StatelessWidget {
  const NewtonGameRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ScientistGameRoot<NewtonController>(
      config: newtonConfig,
      sceneBuilder: (c) => NewtonSceneView(scene: c.scene),
      exploreBuilder: (_) => const NewtonExploreScreen(),
    );
  }
}
