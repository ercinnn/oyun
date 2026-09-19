import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/plant_lab_controller.dart';
import '../models/plant_conditions.dart';
import '../models/plant_growth.dart';
import '../models/plant_lab_trial.dart';
import '../models/plant_species.dart';
import '../widgets/plant_comparison_panel.dart';
import '../widgets/plant_condition_picker.dart';
import '../widgets/plant_view.dart';

class PlantLabGameScreen extends StatelessWidget {
  const PlantLabGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantLabController>();
    final trial = controller.currentTrial;
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
                  'Tur $roundNumber / $plantLabRoundsPerPlayer · '
                  'Doğru: ${player.correctCount}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _SpeciesHeader(species: trial.species),
                const SizedBox(height: 12),
                if (controller.showingResult)
                  _ResultSection(controller: controller)
                else if (trial.kind == PlantLabTrialKind.experiment)
                  _ExperimentQuestion(trial: trial)
                else
                  _DoctorQuestion(trial: trial),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeciesHeader extends StatelessWidget {
  const _SpeciesHeader({required this.species});

  final PlantSpecies species;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(species.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    species.funFact,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deney turu: iki saksıyı göster, tahmini iste.
class _ExperimentQuestion extends StatelessWidget {
  const _ExperimentQuestion({required this.trial});

  final PlantLabTrial trial;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PlantLabController>();
    final factor = trial.factor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${factor.label} bitkinin büyümesini etkiler mi?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PotCard(
                label: 'A saksısı',
                species: trial.species,
                conditions: trial.potA,
                highlight: factor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PotCard(
                label: 'B saksısı',
                species: trial.species,
                conditions: trial.potB,
                highlight: factor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Adil deney: iki saksıda yalnızca ${factor.lowerLabel} farklı. '
          'Diğer her şey aynı.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Sence $plantExperimentDays gün sonra hangisi daha çok büyür?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('plantPredictA'),
          onPressed: () => controller.answerPrediction(PlantPrediction.a),
          child: const Text('A daha çok büyür'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('plantPredictB'),
          onPressed: () => controller.answerPrediction(PlantPrediction.b),
          child: const Text('B daha çok büyür'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('plantPredictSame'),
          onPressed: () => controller.answerPrediction(PlantPrediction.same),
          child: const Text('Fark olmaz'),
        ),
      ],
    );
  }
}

/// Bir saksının başlangıç görüntüsü ve koşulları; test edilen etken
/// vurgulanır ki çocuk neyin farklı olduğunu görsün.
class _PotCard extends StatelessWidget {
  const _PotCard({
    required this.label,
    required this.species,
    required this.conditions,
    required this.highlight,
  });

  final String label;
  final PlantSpecies species;
  final PlantConditions conditions;
  final PlantFactor highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(label, style: textTheme.titleSmall),
            PlantView(
              species: species,
              snapshot: simulatePlant(species, conditions, 0),
              height: 110,
            ),
            const SizedBox(height: 4),
            for (final factor in PlantFactor.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      plantFactorIcon(factor),
                      size: 14,
                      color: factor == highlight ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        factor.levelLabels[conditions.levelOf(factor)],
                        style: factor == highlight
                            ? textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                              )
                            : textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Doktor turu: hasta bitkiyi ve belirtisini göster, hangi koşulun
/// düzeltileceğini sor.
class _DoctorQuestion extends StatelessWidget {
  const _DoctorQuestion({required this.trial});

  final PlantLabTrial trial;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PlantLabController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bitki doktoru: bu bitki hasta!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        PlantView(
          species: trial.species,
          snapshot: simulatePlant(
            trial.species,
            trial.potA,
            plantExperimentDays.toDouble(),
          ),
          height: 190,
        ),
        const SizedBox(height: 8),
        Text(
          trial.symptom,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Hangi koşulu düzeltmeliyiz?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final factor in PlantFactor.values) ...[
          FilledButton.icon(
            key: Key('plantDoctor_${factor.name}'),
            onPressed: () => controller.answerDoctor(factor),
            icon: Icon(plantFactorIcon(factor)),
            label: Text(factor.label),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Cevaptan sonra: doğru/yanlış başlığı, zaman atlamalı karşılaştırma ve
/// açıklama. Oyuncu "Devam"a basana kadar ekranda kalır.
class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.controller});

  final PlantLabController controller;

  @override
  Widget build(BuildContext context) {
    final trial = controller.currentTrial;
    final correct = controller.lastAnswerCorrect;
    final isDoctor = trial.kind == PlantLabTrialKind.doctor;

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
                    correct
                        ? (isDoctor ? 'Doğru teşhis!' : 'Doğru tahmin!')
                        : 'Bu sefer olmadı, birlikte bakalım.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        PlantComparisonPanel(
          key: ValueKey('result_${controller.currentPlayer.roundsPlayed}_'
              '${controller.currentPlayerIndex}'),
          species: trial.species,
          potA: trial.potA,
          potB: trial.potB,
          labelA: isDoctor ? 'Hasta bitki' : 'A',
          labelB: isDoctor ? 'İyileşmiş bitki' : 'B',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              trial.explanation,
              key: const Key('plantExplanation'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('plantLabContinue'),
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
