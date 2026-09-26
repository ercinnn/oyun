import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/tesla_controller.dart';
import '../data/scientists_catalog.dart';
import '../screens/scientist/scientist_game_config.dart';
import '../screens/scientist/scientist_game_root.dart';
import '../screens/tesla_explore_screen.dart';
import '../services/scientist_sounds.dart';
import '../widgets/tesla/tesla_scene_view.dart';

/// "Bilim İnsanları" altındaki Tesla oyunu (alternatif akım, transformatör ve
/// uzağa elektrik taşıma, Tesla bobini ile kablosuz enerji).
class TeslaGame extends StatelessWidget {
  const TeslaGame({super.key});

  static const routeName = '/games/bilim-insanlari/tesla';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeslaController()..attachSounds(createScientistSounds()),
      child: const TeslaGameRoot(),
    );
  }
}

const teslaConfig = ScientistGameConfig(
  scientist: teslaScientist,
  title: 'Tesla\'nın Laboratuvarı',
  banner: '⚡ 💡 🏙️',
  intro: 'Nikola Tesla, evlerimize gelen alternatif akımı geliştirdi. Niagara '
      'Şelalesi\'ndeki santralden kilometrelerce uzaktaki şehirlere elektrik '
      'taşıdı ve kablosuz enerjiyi hayal etti. Sen de onun gibi dene: '
      'jeneratörü çevir, şehri aydınlat, lambayı kablosuz yak!',
  exploreTitle: 'Tesla\'nın Laboratuvarı',
  exploreHint: 'Laboratuvarda jeneratörle pili karşılaştırır, transformatörle '
      'şehre elektrik gönderir ve Tesla bobiniyle kablosuz lamba yakarsın.',
  moral: 'Alternatif akım yön değiştirir ve transformatörle yükseltilip uzağa '
      'taşınabilir. Aynı frekansa ayarlanan alıcı enerjiyi kablosuz toplar.',
);

class TeslaGameRoot extends StatelessWidget {
  const TeslaGameRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ScientistGameRoot<TeslaController>(
      config: teslaConfig,
      sceneBuilder: (c) => TeslaSceneView(scene: c.scene),
      exploreBuilder: (_) => const TeslaExploreScreen(),
    );
  }
}
