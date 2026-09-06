import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/multiplication_controller.dart';
import '../models/multiplication_context.dart';
import '../models/multiplication_trial.dart';
import '../widgets/multiplication_array_view.dart';

class MultiplicationGameScreen extends StatelessWidget {
  const MultiplicationGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MultiplicationController>();
    final player = controller.currentPlayer;
    final trial = controller.currentTrial;

    // Cevap verildiğinde roundsPlayed hemen artıyor, ama açıklama paneli hâlâ
    // az önce oynanan turu anlatıyor — o yüzden panel açıkken bir geri sayarız.
    final displayRound = controller.showingExplanation
        ? player.roundsPlayed
        : player.roundsPlayed + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} oynuyor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Doğru: ${player.correctCount} / '
                '$multiplicationRoundsPerPlayer',
              ),
            ),
          ),
        ],
      ),
      // Geniş ekranda içerik bir okuma sütununda kalsın: ızgara zaten kendini
      // ölçekliyor, ama açıklama paneli ve sayaçlar kenardan kenara yayılınca
      // okunaksızlaşıyordu.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Tur $displayRound / $multiplicationRoundsPerPlayer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: controller.showingExplanation
                      ? _ExplanationPanel(controller: controller)
                      : (trial.kind == MultiplicationTrialKind.array
                            ? _ArrayQuestion(controller: controller)
                            : _BuildQuestion(controller: controller)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Okuma turu: hazır ızgara + 4 seçenek.
class _ArrayQuestion extends StatelessWidget {
  const _ArrayQuestion({required this.controller});

  final MultiplicationController controller;

  @override
  Widget build(BuildContext context) {
    final trial = controller.currentTrial;

    return Column(
      children: [
        _SceneChip(scene: trial.context),
        const SizedBox(height: 8),
        Text(
          trial.sceneQuestion,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          trial.groupingText,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: MultiplicationArrayView(
              rows: trial.rows,
              columns: trial.columns,
              emoji: trial.emoji,
              rowLeadingEmoji: trial.context.groupEmoji,
              columnHeaderEmoji: trial.context.columnHeaderEmoji,
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
                onTap: () => controller.answerArray(option),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Kurma turu: hedef çarpma verilir, oyuncu ızgarayı kendisi büyütür.
class _BuildQuestion extends StatelessWidget {
  const _BuildQuestion({required this.controller});

  final MultiplicationController controller;

  @override
  Widget build(BuildContext context) {
    final trial = controller.currentTrial;
    final maxFactor = controller.difficulty.buildMaxFactor;

    return Column(
      children: [
        _SceneChip(scene: trial.context),
        const SizedBox(height: 8),
        Text(
          // Kurmaya uygun olmayan bir sahne buraya normalde hiç düşmez (bkz.
          // MultiplicationController._pickContext); yedek metin güvenlik ağı.
          trial.buildPrompt ?? '${trial.rows} × ${trial.columns} kur!',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${trial.rows} × ${trial.columns} kur',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: MultiplicationArrayView(
              rows: controller.buildRows,
              columns: controller.buildColumns,
              emoji: trial.emoji,
              maxRows: maxFactor,
              maxColumns: maxFactor,
              rowLeadingEmoji: trial.context.groupEmoji,
              columnHeaderEmoji: trial.context.columnHeaderEmoji,
            ),
          ),
        ),
        _StepperRow(
          label: 'Sıra',
          value: controller.buildRows,
          minusKey: const Key('multiplicationRowsMinus'),
          plusKey: const Key('multiplicationRowsPlus'),
          onChanged: controller.adjustBuildRows,
        ),
        _StepperRow(
          label: 'Sütun',
          value: controller.buildColumns,
          minusKey: const Key('multiplicationColumnsMinus'),
          plusKey: const Key('multiplicationColumnsPlus'),
          onChanged: controller.adjustBuildColumns,
        ),
        const SizedBox(height: 8),
        Text(
          'Şu an: ${controller.buildRows} × ${controller.buildColumns} = '
          '${controller.buildValue}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('multiplicationConfirm'),
          onPressed: controller.submitBuild,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text('Onayla'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Oyunun asıl öğretici parçası: cevaptan sonra ızgarayı sıra sıra toplayarak
/// çarpmanın ne demek olduğunu tekrar gösteren panel.
///
/// Kendi kendine kapanmaz — oyuncu "Devam"a basana kadar ekranda kalır (bkz.
/// [MultiplicationController] sınıf yorumu).
class _ExplanationPanel extends StatelessWidget {
  const _ExplanationPanel({required this.controller});

  final MultiplicationController controller;

  @override
  Widget build(BuildContext context) {
    final trial = controller.currentTrial;
    final correct = controller.lastAnswerCorrect;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Center dış çerçeveyi gevşek kısıtla besliyor, böylece kısa içerikte
        // panel dikeyde ortalanır; uzun içerikte kaydırma devreye girer.
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: correct
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.10),
                ),
                child: Column(
                  children: [
                    Icon(
                      correct ? Icons.check_circle : Icons.lightbulb,
                      size: 40,
                      color: correct
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      correct ? 'Doğru!' : 'Birlikte bakalım',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (!correct) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sen ${controller.lastGivenValue} dedin.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    MultiplicationArrayView(
                      rows: trial.rows,
                      columns: trial.columns,
                      emoji: trial.emoji,
                      showRunningTotals: true,
                      rowLeadingEmoji: trial.context.groupEmoji,
                      columnHeaderEmoji: trial.context.columnHeaderEmoji,
                      totalUnit: trial.unit,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      trial.groupingText,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trial.repeatedAdditionText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Sayıyı sahneye geri bağlayan cümle. Panelin sonunda
                    // durması bilinçli: çocuk önce dikdörtgeni toplayarak
                    // sayıyı buluyor, sonra o sayının gerçek hayatta neye
                    // karşılık geldiğini okuyor.
                    Text(
                      trial.sceneConclusion,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (trial.context.kind ==
                        MultiplicationContextKind.kombinasyon) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Bir sıra, bir '
                        '${trial.context.groupEmoji} demek: o sıra boyunca '
                        'bütün ${trial.context.columnHeaderEmoji} '
                        'seçenekleriyle birer kez eşleştirdik.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (controller.lastAnswerCommuted) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${controller.buildRows} × ${controller.buildColumns} '
                        'ile ${trial.rows} × ${trial.columns} aynı sonucu '
                        'verir: ${trial.answer}. Çarpmada sıranın değişmesi '
                        'sonucu değiştirmez!',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('multiplicationContinue'),
          onPressed: controller.continueAfterExplanation,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text('Devam'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Turun geçtiği gerçek hayat sahnesini adıyla duyuran küçük başlık.
///
/// Sahne adı soru cümlesinin *içinde* de geçiyor; buradaki tekrar bilinçli:
/// çocuk aynı 3 × 4 dikdörtgenini bir turda yumurta kolisi, bir sonrakinde
/// bisiklet tekerleği olarak görünce sahnenin değiştiğini ama matematiğin
/// değişmediğini fark etsin diye sahne adı hep aynı yerde duruyor.
class _SceneChip extends StatelessWidget {
  const _SceneChip({required this.scene});

  final MultiplicationContext scene;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${scene.groupEmoji ?? scene.emoji}  ${scene.title}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

/// Kurma turundaki "Sıra"/"Sütun" sayacı.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.minusKey,
    required this.plusKey,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Key minusKey;
  final Key plusKey;

  /// Değişim miktarını (-1 / +1) alır; sınırlara kırpma kontrolcünün işi.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        IconButton(
          key: minusKey,
          onPressed: () => onChanged(-1),
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 32,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          key: plusKey,
          onPressed: () => onChanged(1),
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 32,
        ),
      ],
    );
  }
}

/// Okuma turundaki cevap seçeneği butonu.
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
