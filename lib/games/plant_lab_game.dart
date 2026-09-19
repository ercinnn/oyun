import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/plant_lab_controller.dart';
import '../models/plant_lab_game_phase.dart';
import '../screens/plant_lab_free_screen.dart';
import '../screens/plant_lab_game_screen.dart';
import '../screens/plant_lab_results_screen.dart';
import '../screens/plant_lab_setup_screen.dart';
import '../screens/plant_lab_turn_transition_screen.dart';

/// "Bitki Laboratuvarı" (bitkileri farklı ışık/su/sıcaklıkta deneyip büyümeyi
/// karşılaştıran bilim oyunu) route'u. Diğer oyunlar gibi kendi
/// [PlantLabController] örneğini route'a her girişte taze kurar.
class PlantLabGame extends StatelessWidget {
  const PlantLabGame({super.key});

  static const routeName = '/games/bitki-laboratuvari';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlantLabController(),
      child: const _PlantLabRoot(),
    );
  }
}

class _PlantLabRoot extends StatelessWidget {
  const _PlantLabRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<PlantLabController>().phase;
    switch (phase) {
      case PlantLabPhase.setup:
        return const PlantLabSetupScreen();
      case PlantLabPhase.playing:
        return const PlantLabGameScreen();
      case PlantLabPhase.turnTransition:
        return const PlantLabTurnTransitionScreen();
      case PlantLabPhase.finished:
        return const PlantLabResultsScreen();
      case PlantLabPhase.freeLab:
        return const PlantLabFreeScreen();
    }
  }
}
