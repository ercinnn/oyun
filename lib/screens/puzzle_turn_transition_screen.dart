import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/puzzle_controller.dart';

class PuzzleTurnTransitionScreen extends StatelessWidget {
  const PuzzleTurnTransitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PuzzleController>();
    final nextPlayer = controller.currentPlayer;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, size: 64),
              const SizedBox(height: 16),
              Text(
                'Sıra ${nextPlayer.name}\'de!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cihazı sıradaki oyuncuya ver.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: controller.acknowledgeTurnTransition,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text('Hazırım'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
