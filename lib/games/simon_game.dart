import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/simon_controller.dart';
import '../models/simon_game_phase.dart';
import '../screens/simon_game_screen.dart';
import '../screens/simon_results_screen.dart';
import '../screens/simon_setup_screen.dart';
import '../screens/simon_turn_transition_screen.dart';

/// "Simon Diyor ki" (Simon Says tarzı dikkat/dürtü kontrolü) oyununun
/// platforma eklenen route'u. Diğer oyunlar gibi kendi [SimonController]
/// örneğini route'a her girişte taze kurar.
class SimonGame extends StatelessWidget {
  const SimonGame({super.key});

  static const routeName = '/games/simon-diyor-ki';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SimonController(),
      child: const _SimonRoot(),
    );
  }
}

class _SimonRoot extends StatelessWidget {
  const _SimonRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<SimonController>().phase;
    switch (phase) {
      case SimonGamePhase.setup:
        return const SimonSetupScreen();
      case SimonGamePhase.playing:
        return const SimonGameScreen();
      case SimonGamePhase.turnTransition:
        return const SimonTurnTransitionScreen();
      case SimonGamePhase.finished:
        return const SimonResultsScreen();
    }
  }
}
