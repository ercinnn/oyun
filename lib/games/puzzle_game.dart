import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/puzzle_controller.dart';
import '../models/puzzle_game_phase.dart';
import '../screens/puzzle_game_screen.dart';
import '../screens/puzzle_results_screen.dart';
import '../screens/puzzle_setup_screen.dart';
import '../screens/puzzle_turn_transition_screen.dart';

/// "Kayan Yapboz" (klasik 15'lik kayan sayı bulmacası) oyununun platforma
/// eklenen route'u. Diğer oyunlar gibi kendi [PuzzleController] örneğini
/// route'a her girişte taze kurar.
class PuzzleGame extends StatelessWidget {
  const PuzzleGame({super.key});

  static const routeName = '/games/kayan-yapboz';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PuzzleController(),
      child: const _PuzzleRoot(),
    );
  }
}

class _PuzzleRoot extends StatelessWidget {
  const _PuzzleRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<PuzzleController>().phase;
    switch (phase) {
      case PuzzleGamePhase.setup:
        return const PuzzleSetupScreen();
      case PuzzleGamePhase.playing:
        return const PuzzleGameScreen();
      case PuzzleGamePhase.turnTransition:
        return const PuzzleTurnTransitionScreen();
      case PuzzleGamePhase.finished:
        return const PuzzleResultsScreen();
    }
  }
}
