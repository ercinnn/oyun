import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/memory_match_controller.dart';
import '../widgets/memory_card_widget.dart';

class MemoryGameScreen extends StatelessWidget {
  const MemoryGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MemoryMatchController>();
    final current = controller.currentPlayer;
    final bool isSolo = controller.players.length == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSolo ? '${current.name} oynuyor' : 'Sıra: ${current.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                isSolo
                    ? '${current.matchedPairs} / $pairCount çift'
                    : controller.players
                          .map((p) => '${p.name}: ${p.matchedPairs}')
                          .join('   '),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridColumns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: controller.cards.length,
              itemBuilder: (context, index) {
                final card = controller.cards[index];
                return MemoryCardWidget(
                  card: card,
                  onTap: () => card.isMatched
                      ? controller.pronounce(index)
                      : controller.flipCard(index),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
