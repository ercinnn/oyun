import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/pattern_controller.dart';
import '../models/pattern_game_phase.dart';
import '../screens/pattern_game_screen.dart';
import '../screens/pattern_results_screen.dart';
import '../screens/pattern_setup_screen.dart';
import '../screens/pattern_turn_transition_screen.dart';

/// "Diziler" (IQ testi tarzı sayı dizisi tamamlama) oyununun platforma
/// eklenen route'u. Diğer oyunlar gibi kendi [PatternController] örneğini
/// route'a her girişte taze kurar.
class PatternGame extends StatelessWidget {
  const PatternGame({super.key});

  static const routeName = '/games/diziler';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatternController(),
      child: const _PatternRoot(),
    );
  }
}

class _PatternRoot extends StatelessWidget {
  const _PatternRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<PatternController>().phase;
    switch (phase) {
      case PatternGamePhase.setup:
        return const PatternSetupScreen();
      case PatternGamePhase.playing:
        return const PatternGameScreen();
      case PatternGamePhase.turnTransition:
        return const PatternTurnTransitionScreen();
      case PatternGamePhase.finished:
        return const PatternResultsScreen();
    }
  }
}
