import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/memory_match_controller.dart';
import '../models/memory_game_phase.dart';
import '../screens/memory_game_screen.dart';
import '../screens/memory_results_screen.dart';
import '../screens/memory_setup_screen.dart';
import '../services/speech_service.dart';

/// "Kart Eşleştirme" oyununun platforma eklenen route'u. Bombalı Sayılar'da
/// olduğu gibi, kendi [MemoryMatchController] örneğini route'a her girişte
/// taze kurar; bu oyunun state'i diğer oyunlarla karışmaz.
class MemoryMatchGame extends StatelessWidget {
  const MemoryMatchGame({super.key});

  static const routeName = '/games/memory-match';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MemoryMatchController(speechService: SpeechService()),
      child: const _MemoryMatchRoot(),
    );
  }
}

class _MemoryMatchRoot extends StatelessWidget {
  const _MemoryMatchRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<MemoryMatchController>().phase;
    switch (phase) {
      case MemoryGamePhase.setup:
        return const MemorySetupScreen();
      case MemoryGamePhase.playing:
        return const MemoryGameScreen();
      case MemoryGamePhase.finished:
        return const MemoryResultsScreen();
    }
  }
}
