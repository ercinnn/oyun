import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/archimedes_controller.dart';
import '../data/scientists_catalog.dart';
import '../screens/archimedes_explore_screen.dart';
import '../screens/scientist/scientist_game_config.dart';
import '../screens/scientist/scientist_game_root.dart';
import '../services/scientist_sounds.dart';
import '../widgets/archimedes/archimedes_scene_view.dart';

/// "Bilim İnsanları" altındaki Arşimet oyunu (kaldırma kuvveti, taç deneyi,
/// gemi, Arşimet vidası). Kendi [ArchimedesController]'ını route'a her
/// girişte taze kurar; diğer bilim insanlarının oyunlarıyla state paylaşmaz.
class ArchimedesGame extends StatelessWidget {
  const ArchimedesGame({super.key});

  static const routeName = '/games/bilim-insanlari/arsimet';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ArchimedesController()..attachSounds(createScientistSounds()),
      child: const ArchimedesGameRoot(),
    );
  }
}

const archimedesConfig = ScientistGameConfig(
  scientist: archimedesScientist,
  title: 'Arşimet\'in Atölyesi',
  banner: '🛁 💧 ⛵',
  intro: 'Arşimet banyoya girince suyun yükseldiğini fark etti ve '
      '"Evreka! (Buldum!)" diye bağırdı. Sen de onun gibi dene: hangi cisim '
      'yüzer, hangisi batar? Gemiler neden batmaz? Su yukarıya nasıl taşınır?',
  exploreTitle: 'Keşif Atölyesi',
  exploreHint: 'Keşif Atölyesi\'nde cisimleri suya kendin bırakır, gemiye '
      'sandık yükler ve Arşimet vidasının kolunu çevirirsin.',
  moral: '"Evreka!" — Bir cisim suya girince, kapladığı yer kadar suyu iter. '
      'Bu itilen su ondan ağırsa cisim yüzer.',
);

/// Faza göre ekran seçen kök; geliştirme girişi (`dev/scientist_3d_probe`)
/// hazır bir controller'la kullanabilsin diye açık.
class ArchimedesGameRoot extends StatelessWidget {
  const ArchimedesGameRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ScientistGameRoot<ArchimedesController>(
      config: archimedesConfig,
      sceneBuilder: (c) => ArchimedesSceneView(scene: c.scene),
      exploreBuilder: (_) => const ArchimedesExploreScreen(),
    );
  }
}
