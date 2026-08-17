import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/sequence_memory_controller.dart';
import '../models/sequence_tile_color.dart';
import '../widgets/sequence_tile_widget.dart';

class SequenceMemoryGameScreen extends StatelessWidget {
  const SequenceMemoryGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SequenceMemoryController>();
    final player = controller.currentPlayer;
    final statusText = controller.showingSequence
        ? 'İzle...'
        : 'Şimdi sırayla tıkla!';

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} oynuyor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text('Uzunluk: ${controller.sequence.length}'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              statusText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${controller.playerInputIndex} / ${controller.sequence.length} '
              'doğru',
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _tile(controller, SequenceTileColor.red),
                        const SizedBox(width: 12),
                        _tile(controller, SequenceTileColor.blue),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _tile(controller, SequenceTileColor.green),
                        const SizedBox(width: 12),
                        _tile(controller, SequenceTileColor.yellow),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(SequenceMemoryController controller, SequenceTileColor color) {
    return SequenceTileWidget(
      key: ValueKey(color),
      color: color,
      isLit: controller.litTile == color,
      isWrong: controller.wrongTile == color,
      enabled: !controller.inputLocked,
      onTap: () => controller.tapTile(color),
    );
  }
}
