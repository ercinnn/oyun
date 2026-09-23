import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';
import '../models/town/town_phase.dart';
import '../screens/town_arcade_screen.dart';
import '../screens/town_mini_game_screen.dart';
import '../screens/town_results_screen.dart';
import '../screens/town_room_screen.dart';
import '../screens/town_setup_screen.dart';
import '../screens/town_market_screen.dart';
import '../screens/town_turn_transition_screen.dart';
import '../screens/town_wardrobe_screen.dart';
import '../screens/town_world_screen.dart';
import '../services/town_progress_repository.dart';
import '../services/town_sounds.dart';

/// "Renkli Kasaba" (izometrik 2.5D dünya: gez, avatarını giydir, odanı döşe,
/// mini oyun oyna) route'u. Diğer oyunlar gibi kendi [TownController] örneğini
/// route'a her girişte taze kurar; ilerleme cihazda saklanır ve açılışta
/// yüklenir.
class TownGame extends StatelessWidget {
  const TownGame({super.key});

  static const routeName = '/games/renkli-kasaba';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TownController(
        repository: SharedPrefsTownProgressRepository(),
        sounds: createTownSounds(),
      )..load(),
      child: const TownRoot(),
    );
  }
}

/// Faza göre ekranı seçen kök (önizleme/test için açık).
class TownRoot extends StatelessWidget {
  const TownRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<TownController>().phase;
    switch (phase) {
      case TownPhase.setup:
        return const TownSetupScreen();
      case TownPhase.town:
        return const TownWorldScreen();
      case TownPhase.wardrobe:
        return const TownWardrobeScreen();
      case TownPhase.market:
        return const TownMarketScreen();
      case TownPhase.home:
        return const TownRoomScreen();
      case TownPhase.arcade:
        return const TownArcadeScreen();
      case TownPhase.miniGame:
        return const TownMiniGameScreen();
      case TownPhase.turnTransition:
        return const TownTurnTransitionScreen();
      case TownPhase.finished:
        return const TownResultsScreen();
    }
  }
}
