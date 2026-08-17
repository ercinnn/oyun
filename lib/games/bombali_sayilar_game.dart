import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../controllers/theme_controller.dart';
import '../data/in_memory_game_result_repository.dart';
import '../models/game_phase.dart';
import '../services/sound_service.dart';
import '../screens/game_screen.dart';
import '../screens/results_screen.dart';
import '../screens/setup_screen.dart';
import '../screens/turn_transition_screen.dart';

/// "Bombalı Sayılar" oyununun platforma eklenen route'u. Kendi
/// [GameController]/[AppThemeController] örneklerini burada, route'a her
/// girişte taze olacak şekilde kurar — böylece bir oyundan çıkıp tekrar
/// girmek her zaman temiz bir oturumla başlar ve diğer oyunların state'iyle
/// karışmaz.
class BombaliSayilarGame extends StatelessWidget {
  const BombaliSayilarGame({super.key});

  static const routeName = '/games/bombali-sayilar';

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameController(
            resultRepository: InMemoryGameResultRepository(),
            soundService: SoundService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => AppThemeController()),
      ],
      child: Consumer<AppThemeController>(
        builder: (context, themeController, _) {
          // Oyuna özel renk seçimi yalnızca bu route'un Material temasını
          // etkiler; platform ana menüsü kendi nötr temasında kalır.
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeController.current.boxColor,
              ),
            ),
            child: const _BombaliSayilarRoot(),
          );
        },
      ),
    );
  }
}

class _BombaliSayilarRoot extends StatelessWidget {
  const _BombaliSayilarRoot();

  @override
  Widget build(BuildContext context) {
    final phase = context.watch<GameController>().phase;
    switch (phase) {
      case GamePhase.setup:
        return const SetupScreen();
      case GamePhase.playing:
        return const GameScreen();
      case GamePhase.turnTransition:
        return const TurnTransitionScreen();
      case GamePhase.finished:
        return const ResultsScreen();
    }
  }
}
