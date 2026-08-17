import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/reflex_controller.dart';
import '../models/reflex_game_phase.dart';
import '../screens/reflex_game_screen.dart';
import '../screens/reflex_results_screen.dart';
import '../screens/reflex_setup_screen.dart';
import '../screens/reflex_turn_transition_screen.dart';

/// "Tepki Süresi" (reaksiyon testi) oyununun platforma eklenen route'u.
/// Diğer oyunlar gibi kendi [ReflexController] örneğini route'a her girişte
/// taze kurar.
class ReflexGame extends StatelessWidget {
  const ReflexGame({super.key});

  static const routeName = '/games/tepki-suresi';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReflexController(),
      child: const _ReflexRoot(),
    );
  }
}

class _ReflexRoot extends StatelessWidget {
  const _ReflexRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<ReflexController>().phase;
    switch (phase) {
      case ReflexGamePhase.setup:
        return const ReflexSetupScreen();
      case ReflexGamePhase.playing:
        return const ReflexGameScreen();
      case ReflexGamePhase.turnTransition:
        return const ReflexTurnTransitionScreen();
      case ReflexGamePhase.finished:
        return const ReflexResultsScreen();
    }
  }
}
