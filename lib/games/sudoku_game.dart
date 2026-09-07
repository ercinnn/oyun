import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/sudoku_controller.dart';
import '../models/sudoku_game_phase.dart';
import '../screens/sudoku_game_screen.dart';
import '../screens/sudoku_results_screen.dart';
import '../screens/sudoku_setup_screen.dart';
import '../screens/sudoku_turn_transition_screen.dart';

/// "Sudoku" (klasik 9×9 sayı bulmacası) oyununun platforma eklenen route'u.
/// Diğer oyunlar gibi kendi [SudokuController] örneğini route'a her girişte
/// taze kurar.
class SudokuGame extends StatelessWidget {
  const SudokuGame({super.key});

  static const routeName = '/games/sudoku';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SudokuController(),
      child: const _SudokuRoot(),
    );
  }
}

class _SudokuRoot extends StatelessWidget {
  const _SudokuRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<SudokuController>().phase;
    switch (phase) {
      case SudokuGamePhase.setup:
        return const SudokuSetupScreen();
      case SudokuGamePhase.playing:
        return const SudokuGameScreen();
      case SudokuGamePhase.turnTransition:
        return const SudokuTurnTransitionScreen();
      case SudokuGamePhase.finished:
        return const SudokuResultsScreen();
    }
  }
}
