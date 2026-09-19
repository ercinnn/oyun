import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/electricity_controller.dart';
import '../models/electricity_phase.dart';
import '../screens/electricity_free_circuit_screen.dart';
import '../screens/electricity_game_screen.dart';
import '../screens/electricity_results_screen.dart';
import '../screens/electricity_setup_screen.dart';
import '../screens/electricity_turn_transition_screen.dart';
import '../screens/electricity_wire_levels_screen.dart';

/// "Elektrik Atölyesi" (devre, iletken/yalıtkan, kablo yolu, enerji şehri ve
/// güvenlik görevleri) route'u. Diğer oyunlar gibi kendi
/// [ElectricityController] örneğini route'a her girişte taze kurar.
class ElectricityGame extends StatelessWidget {
  const ElectricityGame({super.key});

  static const routeName = '/games/elektrik-atolyesi';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ElectricityController(),
      child: const _ElectricityRoot(),
    );
  }
}

class _ElectricityRoot extends StatelessWidget {
  const _ElectricityRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<ElectricityController>().phase;
    switch (phase) {
      case ElectricityPhase.setup:
        return const ElectricitySetupScreen();
      case ElectricityPhase.playing:
        return const ElectricityGameScreen();
      case ElectricityPhase.turnTransition:
        return const ElectricityTurnTransitionScreen();
      case ElectricityPhase.finished:
        return const ElectricityResultsScreen();
      case ElectricityPhase.freeCircuit:
        return const ElectricityFreeCircuitScreen();
      case ElectricityPhase.wireLevels:
        return const ElectricityWireLevelsScreen();
    }
  }
}
