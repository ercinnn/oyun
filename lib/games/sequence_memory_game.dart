import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/sequence_memory_controller.dart';
import '../models/sequence_memory_game_phase.dart';
import '../screens/sequence_memory_game_screen.dart';
import '../screens/sequence_memory_results_screen.dart';
import '../screens/sequence_memory_setup_screen.dart';
import '../screens/sequence_memory_turn_transition_screen.dart';

/// "Dizi Hafızası" (Simon tarzı sıra hafızası) oyununun platforma eklenen
/// route'u. Diğer oyunlar gibi kendi [SequenceMemoryController] örneğini
/// route'a her girişte taze kurar.
class SequenceMemoryGame extends StatelessWidget {
  const SequenceMemoryGame({super.key});

  static const routeName = '/games/dizi-hafizasi';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SequenceMemoryController(),
      child: const _SequenceMemoryRoot(),
    );
  }
}

class _SequenceMemoryRoot extends StatelessWidget {
  const _SequenceMemoryRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<SequenceMemoryController>().phase;
    switch (phase) {
      case SequenceMemoryGamePhase.setup:
        return const SequenceMemorySetupScreen();
      case SequenceMemoryGamePhase.playing:
        return const SequenceMemoryGameScreen();
      case SequenceMemoryGamePhase.turnTransition:
        return const SequenceMemoryTurnTransitionScreen();
      case SequenceMemoryGamePhase.finished:
        return const SequenceMemoryResultsScreen();
    }
  }
}
