import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/electricity_controller.dart';
import '../widgets/wire_puzzle_board.dart';

/// Kablo yolu seviyeleri: 12 seviye, hamle sayacı ve ideal hamle karşılaştırması.
/// Puan yok; ilerleme yalnızca oturum içinde tutulur.
class ElectricityWireLevelsScreen extends StatelessWidget {
  const ElectricityWireLevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ElectricityController>();
    final puzzle = controller.levelPuzzle;
    final solved = puzzle.solved;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kablo Yolu Seviyeleri'),
        // Geri oku oyundan çıkmak yerine kurulum ekranına döner.
        leading: BackButton(onPressed: controller.restart),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (var level = 1; level <= wireLevelCount; level++)
                      ChoiceChip(
                        key: Key('wireLevel_$level'),
                        label: Text(
                          controller.solvedLevels.contains(level)
                              ? '$level ✓'
                              : '$level',
                        ),
                        selected: controller.wireLevel == level,
                        onSelected: (_) => controller.selectWireLevel(level),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Seviye ${controller.wireLevel}: pilden ampule kesintisiz bir yol kur.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                WirePuzzleBoard(
                  puzzle: puzzle,
                  onTap: controller.rotateLevelTile,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hamle: ${puzzle.moves} · İdeal: ${puzzle.parMoves}',
                  key: const Key('levelMoves'),
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall,
                ),
                if (solved) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.green.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade800),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Ampul yandı! Seviyeyi ${puzzle.moves} hamlede tamamladın.',
                              key: const Key('levelSolved'),
                              style: textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (controller.wireLevel < wireLevelCount)
                    FilledButton(
                      key: const Key('nextWireLevel'),
                      onPressed: controller.nextWireLevel,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Sonraki Seviye'),
                      ),
                    ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('resetWireLevel'),
                  onPressed: () => controller.selectWireLevel(controller.wireLevel),
                  child: const Text('Seviyeyi Baştan Başlat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
