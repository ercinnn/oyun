import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/stroop_controller.dart';
import '../models/stroop_game_phase.dart';
import '../screens/stroop_game_screen.dart';
import '../screens/stroop_results_screen.dart';
import '../screens/stroop_setup_screen.dart';
import '../screens/stroop_turn_transition_screen.dart';

/// "Renk mi Kelime mi?" (Stroop testi) oyununun platforma eklenen route'u.
/// Diğer oyunlar gibi kendi [StroopController] örneğini route'a her
/// girişte taze kurar.
class StroopGame extends StatelessWidget {
  const StroopGame({super.key});

  static const routeName = '/games/stroop';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StroopController(),
      child: const _StroopRoot(),
    );
  }
}

class _StroopRoot extends StatelessWidget {
  const _StroopRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<StroopController>().phase;
    switch (phase) {
      case StroopGamePhase.setup:
        return const StroopSetupScreen();
      case StroopGamePhase.playing:
        return const StroopGameScreen();
      case StroopGamePhase.turnTransition:
        return const StroopTurnTransitionScreen();
      case StroopGamePhase.finished:
        return const StroopResultsScreen();
    }
  }
}
