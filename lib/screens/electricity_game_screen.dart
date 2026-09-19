import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/electricity_controller.dart';
import '../models/circuit_simulation.dart';
import '../models/electric_task.dart';
import '../widgets/circuit_diagram.dart';
import '../widgets/wire_puzzle_board.dart';

class ElectricityGameScreen extends StatelessWidget {
  const ElectricityGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ElectricityController>();
    final task = controller.currentTask;
    final player = controller.currentPlayer;
    final roundNumber = controller.showingResult
        ? player.roundsPlayed
        : player.roundsPlayed + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.players.length == 1
              ? '${player.name} oynuyor'
              : 'Sıra: ${player.name}',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tur $roundNumber / $electricRoundsPerPlayer · '
                  'Doğru: ${player.correctCount}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.kind.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (controller.showingResult)
                  _ResultSection(controller: controller, task: task)
                else
                  switch (task) {
                    ChoiceTask() => _ChoiceQuestion(task: task),
                    WireTask() => _WireQuestion(task: task),
                  },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sorulan konuyu (malzeme, sahne, hava durumu…) gösteren kutu.
class _Subject extends StatelessWidget {
  const _Subject({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _CircuitCard extends StatelessWidget {
  const _CircuitCard({super.key, required this.circuit, this.animated = false});

  final LabeledCircuit circuit;

  /// true ise sonuç gösterilir (ampuller ışır); false ise soru aşamasıdır.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final result = animated ? simulateCircuit(circuit.spec) : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(circuit.label, style: Theme.of(context).textTheme.titleSmall),
            if (animated)
              AnimatedCircuitDiagram(spec: circuit.spec, result: result!)
            else
              CircuitDiagram(spec: circuit.spec),
            if (result != null) LampStateList(result: result),
          ],
        ),
      ),
    );
  }
}

class _ChoiceQuestion extends StatelessWidget {
  const _ChoiceQuestion({required this.task});

  final ChoiceTask task;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ElectricityController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (task.subject != null) ...[
          _Subject(text: task.subject!),
          const SizedBox(height: 8),
        ],
        for (final circuit in task.circuits) _CircuitCard(circuit: circuit),
        const SizedBox(height: 8),
        Text(
          task.prompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < task.options.length; i++) ...[
          FilledButton(
            key: Key('electricOption_$i'),
            onPressed: () => controller.answerChoice(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(task.options[i], textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _WireQuestion extends StatelessWidget {
  const _WireQuestion({required this.task});

  final WireTask task;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ElectricityController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Karelere dokunarak kabloları çevir. Pilden ampule kesintisiz bir yol kur!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        WirePuzzleBoard(
          puzzle: task.puzzle,
          onTap: controller.rotateWireTile,
        ),
        const SizedBox(height: 8),
        Text(
          'Hamle: ${task.puzzle.moves} · İdeal: ${task.puzzle.parMoves}',
          key: const Key('wireMoves'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Cevaptan sonra: doğru/yanlış başlığı, ışıyan devre(ler) ve açıklama.
/// Oyuncu "Devam"a basana kadar ekranda kalır.
class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.controller, required this.task});

  final ElectricityController controller;
  final ElectricTask task;

  @override
  Widget build(BuildContext context) {
    final correct = controller.lastAnswerCorrect;
    final currentTask = task;
    final explanation = switch (currentTask) {
      ChoiceTask() => currentTask.explanation,
      WireTask() => currentTask.explanation,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: correct ? Colors.green.shade100 : Colors.orange.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.info,
                  color: correct ? Colors.green.shade800 : Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    correct ? 'Doğru!' : 'Bu sefer olmadı, birlikte bakalım.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (currentTask is ChoiceTask) ...[
          if (currentTask.subject != null) ...[
            _Subject(text: currentTask.subject!),
            const SizedBox(height: 8),
          ],
          for (var i = 0; i < currentTask.circuits.length; i++)
            _CircuitCard(
              key: ValueKey(
                'result_${controller.currentPlayerIndex}_'
                '${controller.currentPlayer.roundsPlayed}_$i',
              ),
              circuit: currentTask.circuits[i],
              animated: true,
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Doğru cevap: ${currentTask.options[currentTask.correctIndex]}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
        ] else if (currentTask is WireTask) ...[
          WirePuzzleBoard(
            puzzle: currentTask.puzzle,
            onTap: (_) {},
            enabled: false,
          ),
        ],
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(explanation, key: const Key('electricExplanation')),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('electricContinue'),
          onPressed: controller.continueAfterResult,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Devam'),
          ),
        ),
      ],
    );
  }
}
