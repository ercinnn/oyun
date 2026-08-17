import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/pattern_controller.dart';

class PatternGameScreen extends StatelessWidget {
  const PatternGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PatternController>();
    final player = controller.currentPlayer;
    final trial = controller.currentTrial;
    final feedback = controller.lastAnswerCorrect;

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} oynuyor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Doğru: ${player.correctCount} / $patternRoundsPerPlayer',
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Tur ${player.roundsPlayed + 1} / $patternRoundsPerPlayer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Örüntüyü bul, sırada geleni seç!',
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: switch (feedback) {
                      null => Colors.transparent,
                      true => Colors.green.withValues(alpha: 0.15),
                      false => Colors.red.withValues(alpha: 0.15),
                    },
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final term in trial.sequence)
                        _NumberChip(label: '$term'),
                      const _NumberChip(label: '?', accent: true),
                    ],
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final option in trial.options)
                  _OptionButton(
                    key: ValueKey(option),
                    value: option,
                    onTap: () => controller.answer(option),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Dizideki tek bir terimi (veya gizli terimi temsil eden "?"i) gösteren
/// etkileşimsiz kutu.
class _NumberChip extends StatelessWidget {
  const _NumberChip({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent ? Colors.blueGrey.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent ? Colors.blueGrey.shade400 : Colors.black26,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: accent ? Colors.blueGrey.shade700 : Colors.black87,
        ),
      ),
    );
  }
}

/// Cevap seçeneği butonu.
class _OptionButton extends StatelessWidget {
  const _OptionButton({super.key, required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black26, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
