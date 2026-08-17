import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/puzzle_controller.dart';
import '../models/puzzle_player_state.dart';

class PuzzleGameScreen extends StatelessWidget {
  const PuzzleGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PuzzleController>();
    final player = controller.currentPlayer;

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} oynuyor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('Hamle: ${player.moveCount}')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Boş kareye komşu bir sayıya dokunarak kaydır!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    crossAxisCount: puzzleGridSize,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (var index = 0; index < player.tiles.length; index++)
                        _tile(controller, player.tiles[index], index),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(PuzzleController controller, int value, int index) {
    if (value == 0) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      key: ValueKey(value),
      onTap: () => controller.moveTile(index),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.cyan.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyan.shade700, width: 1.5),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.cyan.shade900,
          ),
        ),
      ),
    );
  }
}
