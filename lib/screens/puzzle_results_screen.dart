import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/puzzle_controller.dart';

class PuzzleResultsScreen extends StatelessWidget {
  const PuzzleResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PuzzleController>();
    final ranked = controller.rankedByMoves;
    final winner = ranked.first;
    final isTie =
        ranked.length > 1 && ranked[1].moveCount == winner.moveCount;
    final String headline = ranked.length == 1
        ? 'Tebrikler, ${winner.name}!'
        : (isTie ? 'Berabere!' : '${winner.name} kazandı!');

    return Scaffold(
      appBar: AppBar(title: const Text('Sonuçlar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 12),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                for (final player in ranked)
                  Card(
                    child: ListTile(
                      title: Text(player.name),
                      trailing: Text('${player.moveCount} hamle'),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: controller.restart,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Text('Tekrar Oyna'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
