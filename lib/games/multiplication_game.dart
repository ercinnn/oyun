import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/multiplication_controller.dart';
import '../models/multiplication_game_phase.dart';
import '../screens/multiplication_game_screen.dart';
import '../screens/multiplication_results_screen.dart';
import '../screens/multiplication_setup_screen.dart';
import '../screens/multiplication_turn_transition_screen.dart';

/// "Çarpım Bahçesi" (nesne ızgaralarıyla çarpmanın mantığını öğreten oyun)
/// oyununun platforma eklenen route'u. Diğer oyunlar gibi kendi
/// [MultiplicationController] örneğini route'a her girişte taze kurar.
class MultiplicationGame extends StatelessWidget {
  const MultiplicationGame({super.key});

  static const routeName = '/games/carpim-bahcesi';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MultiplicationController(),
      child: const _MultiplicationRoot(),
    );
  }
}

class _MultiplicationRoot extends StatelessWidget {
  const _MultiplicationRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<MultiplicationController>().phase;
    switch (phase) {
      case MultiplicationGamePhase.setup:
        return const MultiplicationSetupScreen();
      case MultiplicationGamePhase.playing:
        return const MultiplicationGameScreen();
      case MultiplicationGamePhase.turnTransition:
        return const MultiplicationTurnTransitionScreen();
      case MultiplicationGamePhase.finished:
        return const MultiplicationResultsScreen();
    }
  }
}
