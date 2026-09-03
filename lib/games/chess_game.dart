import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chess_controller.dart';
import '../models/chess_game_phase.dart';
import '../screens/chess_game_screen.dart';
import '../screens/chess_results_screen.dart';
import '../screens/chess_setup_screen.dart';

class ChessGame extends StatelessWidget {
  const ChessGame({super.key});

  static const routeName = '/games/satranc';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChessController(),
      child: const _ChessRoot(),
    );
  }
}

class _ChessRoot extends StatelessWidget {
  const _ChessRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<ChessController>().phase;
    switch (phase) {
      case ChessGamePhase.setup:
        return const ChessSetupScreen();
      case ChessGamePhase.playing:
        return const ChessGameScreen();
      case ChessGamePhase.finished:
        return const ChessResultsScreen();
    }
  }
}
