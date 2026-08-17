import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/simon_controller.dart';
import '../models/simon_tile_id.dart';

class SimonGameScreen extends StatelessWidget {
  const SimonGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimonController>();
    final player = controller.currentPlayer;
    final trial = controller.currentTrial;
    final feedback = controller.lastAnswerCorrect;

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} oynuyor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text('Doğru: ${player.correctCount} / $simonRoundsPerPlayer'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Tur ${player.roundsPlayed + 1} / $simonRoundsPerPlayer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: switch (feedback) {
                  null => Colors.grey.shade100,
                  true => Colors.green.withValues(alpha: 0.15),
                  false => Colors.red.withValues(alpha: 0.15),
                },
              ),
              child: Text(
                trial.instructionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _tile(controller, trial.boardOrder[0]),
                        const SizedBox(width: 12),
                        _tile(controller, trial.boardOrder[1]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _tile(controller, trial.boardOrder[2]),
                        const SizedBox(width: 12),
                        _tile(controller, trial.boardOrder[3]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            FilledButton.tonal(
              key: const Key('simonPassButton'),
              onPressed: () => controller.respond(null),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Text('Pas Geç'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(SimonController controller, SimonTileId tileId) {
    return GestureDetector(
      key: ValueKey(tileId),
      onTap: () => controller.respond(tileId),
      child: Container(
        width: 110,
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black26, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(tileId.icon, color: tileId.color, size: 56),
      ),
    );
  }
}
