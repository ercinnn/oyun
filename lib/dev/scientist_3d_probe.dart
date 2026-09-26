// Geliştirme girişi: giriş (Google) kapısını atlayıp doğrudan bir bilim
// insanı oyununu açar.
//   flutter run -d chrome -t lib/dev/scientist_3d_probe.dart
//
// `?who=arsimet|newton|galileo|tesla|curie|einstein|fleming` (varsayılan
// arsimet), `&go=explore` keşif atölyesini,
// `&go=tasks` tek kişilik görevleri açar; `&station=<ad>` keşifte o istasyonla
// başlar (Arşimet: tank|boat|screw, Newton: fall|prism|cart, Galileo:
// telescope|jupiter|solar, Tesla: generator|transmission|wireless, Curie:
// geiger|shield|therapy, Einstein: sheet|clock|energy, Fleming:
// petri|hygiene|medicine). Uygulamanın
// parçası değildir.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/archimedes_controller.dart';
import '../controllers/curie_controller.dart';
import '../controllers/einstein_controller.dart';
import '../controllers/fleming_controller.dart';
import '../controllers/galileo_controller.dart';
import '../controllers/newton_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/scientist_game_controller.dart';
import '../controllers/tesla_controller.dart';
import '../games/archimedes_game.dart';
import '../games/curie_game.dart';
import '../games/einstein_game.dart';
import '../games/fleming_game.dart';
import '../games/galileo_game.dart';
import '../games/newton_game.dart';
import '../games/tesla_game.dart';
import '../models/archimedes/archimedes_scene.dart';
import '../models/curie/curie_scene.dart';
import '../models/einstein/einstein_scene.dart';
import '../models/fleming/fleming_scene.dart';
import '../models/galileo/galileo_scene.dart';
import '../models/newton/newton_scene.dart';
import '../models/tesla/tesla_scene.dart';
import '../services/scientist_sounds.dart';

void main() {
  final params = Uri.base.queryParameters;
  final station = params['station'];
  final who = params['who'];

  void open(ScientistGameController c) {
    switch (params['go']) {
      case 'explore':
        c.startExplore();
      case 'tasks':
        c.startGame(['Deneme']);
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ProfileController(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: switch (who) {
          'newton' => ChangeNotifierProvider(
            create: (_) {
              final c = NewtonController()..attachSounds(createScientistSounds());
              open(c);
              final s = NewtonStation.values
                  .where((s) => s.name == station)
                  .firstOrNull;
              if (s != null) c.setStation(s);
              return c;
            },
            child: const NewtonGameRoot(),
          ),
          'galileo' => ChangeNotifierProvider(
            create: (_) {
              final c = GalileoController()..attachSounds(createScientistSounds());
              open(c);
              final s = GalileoStation.values
                  .where((s) => s.name == station)
                  .firstOrNull;
              if (s != null) c.setStation(s);
              return c;
            },
            child: const GalileoGameRoot(),
          ),
          'tesla' => ChangeNotifierProvider(
            create: (_) {
              final c = TeslaController()..attachSounds(createScientistSounds());
              open(c);
              final s = TeslaStation.values
                  .where((s) => s.name == station)
                  .firstOrNull;
              if (s != null) c.setStation(s);
              return c;
            },
            child: const TeslaGameRoot(),
          ),
          'curie' => ChangeNotifierProvider(
            create: (_) {
              final c = CurieController()..attachSounds(createScientistSounds());
              open(c);
              final s = CurieStation.values
                  .where((s) => s.name == station)
                  .firstOrNull;
              if (s != null) c.setStation(s);
              return c;
            },
            child: const CurieGameRoot(),
          ),
          'einstein' => ChangeNotifierProvider(
            create: (_) {
              final c = EinsteinController()..attachSounds(createScientistSounds());
              open(c);
              final s = EinsteinStation.values
                  .where((s) => s.name == station)
                  .firstOrNull;
              if (s != null) c.setStation(s);
              return c;
            },
            child: const EinsteinGameRoot(),
          ),
          'fleming' => ChangeNotifierProvider(
            create: (_) {
              final c = FlemingController()..attachSounds(createScientistSounds());
              open(c);
              final s = FlemingStation.values
                  .where((s) => s.name == station)
                  .firstOrNull;
              if (s != null) c.setStation(s);
              return c;
            },
            child: const FlemingGameRoot(),
          ),
          _ => ChangeNotifierProvider(
            create: (_) {
              final c = ArchimedesController()..attachSounds(createScientistSounds());
              open(c);
              final s = ArchimedesStation.values
                  .where((s) => s.name == station)
                  .firstOrNull;
              if (s != null) c.setStation(s);
              return c;
            },
            child: const ArchimedesGameRoot(),
          ),
        },
      ),
    ),
  );
}
