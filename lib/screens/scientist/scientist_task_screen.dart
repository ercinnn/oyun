import 'package:flutter/material.dart';

import '../../controllers/scientist_game_controller.dart';
import '../../widgets/science_lab/lab_split_layout.dart';
import '../../widgets/science_lab/scientist_sound_toggle.dart';

/// Görev turu: deney sahnesi + soru ya da sonuç paneli. Sahne widget'ı
/// turlar boyunca aynı yerde kalır ki 3B görünüm her turda baştan kurulmasın.
class ScientistTaskScreen extends StatelessWidget {
  const ScientistTaskScreen({
    super.key,
    required this.controller,
    required this.scene,
  });

  final ScientistGameController controller;
  final Widget scene;

  @override
  Widget build(BuildContext context) {
    final player = controller.currentPlayer;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.players.length == 1
              ? '${player.name} oynuyor'
              : 'Sıra: ${player.name}',
        ),
        actions: [ScientistSoundToggle(controller: controller)],
      ),
      body: LabSplitLayout(
        scene: KeyedSubtree(key: const Key('scientistScene'), child: scene),
        panel: _TaskPanel(controller: controller),
      ),
    );
  }
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({required this.controller});

  final ScientistGameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = controller.currentTask;
    final player = controller.currentPlayer;
    final round =
        controller.showingResult ? player.roundsPlayed : player.roundsPlayed + 1;
    final hint = task.hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Görev $round / ${controller.roundsPerPlayer} · '
          'Doğru: ${player.correctCount}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(task.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(task.prompt, style: theme.textTheme.bodyLarge),
                if (hint != null) ...[
                  const SizedBox(height: 6),
                  Text(hint, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (controller.showingResult)
          _ResultCard(controller: controller)
        else
          for (var i = 0; i < task.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.tonal(
                key: Key('scientistOption_$i'),
                onPressed: () => controller.answer(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(task.options[i], textAlign: TextAlign.center),
                ),
              ),
            ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.controller});

  final ScientistGameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = controller.currentTask;
    final correct = controller.lastAnswerCorrect;
    final color = correct ? Colors.green : Colors.deepOrange;
    return Card(
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.lightbulb,
                  color: color.shade700,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    correct
                        ? 'Doğru!'
                        : 'Doğru cevap: ${task.options[task.correctIndex]}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.explanation(controller.lastAnswerIndex!),
              key: const Key('scientistExplanation'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('scientistContinue'),
              onPressed: controller.continueAfterResult,
              child: const Text('Devam'),
            ),
          ],
        ),
      ),
    );
  }
}
