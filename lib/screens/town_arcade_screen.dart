import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';
import '../models/town/mini_game_session.dart';
import '../widgets/town_hud.dart';

/// Oyun Salonu: serbest modda bir mini oyun seç (puansız; puanın beşte biri
/// kadar altın kazanırsın).
class TownArcadeScreen extends StatelessWidget {
  const TownArcadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TownController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyun Salonu'),
        leading: BackButton(onPressed: controller.backToTown),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CoinChip(coins: controller.profile.coins),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final kind in MiniGameKind.values)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(kind.emoji, style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                kind.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(kind.description),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: Key('arcadeStart_${kind.name}'),
                          onPressed: () => controller.startFreeMiniGame(kind),
                          child: const Text('Oyna'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
