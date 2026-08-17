import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/reflex_controller.dart';
import '../models/reflex_round_state.dart';

class ReflexGameScreen extends StatelessWidget {
  const ReflexGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReflexController>();
    final player = controller.currentPlayer;

    final Color background;
    final String message;
    switch (controller.roundState) {
      case ReflexRoundState.waiting:
        background = Colors.red.shade400;
        message = 'Bekle...';
        break;
      case ReflexRoundState.ready:
        background = Colors.green.shade500;
        message = 'ŞİMDİ! Dokun!';
        break;
      case ReflexRoundState.tooEarly:
        background = Colors.orange.shade700;
        message = 'Çok erken!';
        break;
      case ReflexRoundState.result:
        background = Colors.blue.shade400;
        message = '${controller.lastReactionMs} ms!';
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text('${player.name} oynuyor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Tur ${player.roundsPlayed + 1} / $reflexRoundsPerPlayer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Ekran yeşile dönünce olabildiğince hızlı dokun!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                key: const Key('reflexTapArea'),
                onTap: () => controller.tap(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
