import 'package:flutter/material.dart';

import 'games/bombali_sayilar_game.dart';
import 'games/memory_match_game.dart';
import 'games/pattern_game.dart';
import 'games/puzzle_game.dart';
import 'games/reflex_game.dart';
import 'games/sequence_memory_game.dart';
import 'games/simon_game.dart';
import 'games/stroop_game.dart';
import 'screens/game_catalog_screen.dart';

void main() {
  runApp(const GamePlatformApp());
}

/// Platformun kök widget'ı: ana menüyü ve platforma kayıtlı her oyunun
/// route'unu barındırır. Her oyun kendi state'ini ([Provider] ağacı dahil)
/// kendi route widget'ında kurar; burası yalnızca hangi ekranın açık
/// olduğunu yönetir.
class GamePlatformApp extends StatelessWidget {
  const GamePlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oyun Platformu',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      initialRoute: GameCatalogScreen.routeName,
      onGenerateRoute: (settings) {
        final builder = switch (settings.name) {
          BombaliSayilarGame.routeName => (BuildContext _) =>
              const BombaliSayilarGame(),
          MemoryMatchGame.routeName => (BuildContext _) =>
              const MemoryMatchGame(),
          StroopGame.routeName => (BuildContext _) => const StroopGame(),
          SequenceMemoryGame.routeName => (BuildContext _) =>
              const SequenceMemoryGame(),
          PatternGame.routeName => (BuildContext _) => const PatternGame(),
          ReflexGame.routeName => (BuildContext _) => const ReflexGame(),
          SimonGame.routeName => (BuildContext _) => const SimonGame(),
          PuzzleGame.routeName => (BuildContext _) => const PuzzleGame(),
          _ => (BuildContext _) => const GameCatalogScreen(),
        };
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}
