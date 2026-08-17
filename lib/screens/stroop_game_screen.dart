import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/stroop_controller.dart';
import '../models/stroop_color.dart';

class StroopGameScreen extends StatelessWidget {
  const StroopGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StroopController>();
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
              child: Text('Doğru: ${player.correctCount} / $roundsPerPlayer'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Tur ${player.roundsPlayed + 1} / $roundsPerPlayer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Kelimeyi değil, YAZININ RENGİNİ seç!',
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
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
                  child: Text(
                    trial.word.label,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: trial.ink.inkColor,
                    ),
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
                  _ColorNameButton(
                    key: ValueKey(option),
                    label: option.label,
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

/// Cevap butonu: bilerek rengin kendisiyle değil, nötr (siyah) yazılmış
/// Türkçe adıyla gösterilir. Renkli bir daire olsaydı oyuncu kelimeyi hiç
/// okumadan sadece tonu görsel olarak eşleştirip doğru cevabı verebilirdi;
/// kelime butonu, gördüğü mürekkep rengini gerçekten adlandırmaya zorlar.
class _ColorNameButton extends StatelessWidget {
  const _ColorNameButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
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
          label,
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
