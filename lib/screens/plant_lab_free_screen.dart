import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/plant_lab_controller.dart';
import '../data/plant_catalog.dart';
import '../models/plant_conditions.dart';
import '../widgets/plant_comparison_panel.dart';
import '../widgets/plant_condition_picker.dart';

/// Serbest laboratuvar: bitkiyi seç, A ve B saksısının koşullarını kendin
/// ayarla, deneyi başlat. Puan yok; amaç merak edip denemek.
class PlantLabFreeScreen extends StatelessWidget {
  const PlantLabFreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantLabController>();
    final species = controller.freeSpecies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serbest Laboratuvar'),
        // Geri oku oyundan çıkmak yerine kurulum ekranına döner.
        leading: BackButton(onPressed: controller.restart),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bir bitki seç',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final option in plantCatalog)
                      ChoiceChip(
                        key: Key('freeSpecies_${option.id}'),
                        label: Text('${option.emoji} ${option.name}'),
                        selected: option.id == species.id,
                        onSelected: (_) => controller.setFreeSpecies(option),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  species.funFact,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                PlantConditionPicker(
                  title: 'A saksısı',
                  keyPrefix: 'potA',
                  conditions: controller.freePotA,
                  onChanged: (factor, level) => controller.setFreeCondition(
                    potA: true,
                    factor: factor,
                    level: level,
                  ),
                ),
                PlantConditionPicker(
                  title: 'B saksısı',
                  keyPrefix: 'potB',
                  conditions: controller.freePotB,
                  onChanged: (factor, level) => controller.setFreeCondition(
                    potA: false,
                    factor: factor,
                    level: level,
                  ),
                ),
                const SizedBox(height: 8),
                _FairTestHint(differing: controller.freeDifferingFactors),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('plantFreeStart'),
                  onPressed: controller.runFreeExperiment,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Deneyi Başlat'),
                  ),
                ),
                if (controller.freeStarted) ...[
                  const SizedBox(height: 16),
                  PlantComparisonPanel(
                    key: ValueKey('free_${controller.freeRunCount}'),
                    species: species,
                    potA: controller.freePotA,
                    potB: controller.freePotB,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Adil deney ipucu: bilim insanı bir seferde yalnızca bir şeyi değiştirir,
/// yoksa farkın nedenini bilemez. Serbest modda hiçbir şey engellenmez; yalnızca
/// yumuşak bir uyarı gösterilir.
class _FairTestHint extends StatelessWidget {
  const _FairTestHint({required this.differing});

  final List<PlantFactor> differing;

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData icon;
    if (differing.isEmpty) {
      text = 'İki saksı tamamen aynı. Karşılaştırmak için B saksısında bir şeyi değiştir.';
      icon = Icons.lightbulb;
    } else if (differing.length == 1) {
      text = 'Adil deney! İki saksıda yalnızca '
          '${differing.first.lowerLabel} farklı; sonuçtaki farkın nedeni de o.';
      icon = Icons.check_circle;
    } else {
      text = 'Birden çok şeyi değiştirdin. Bilim insanı bir seferde tek şeyi '
          'değiştirir; yoksa farkın hangisinden geldiğini bilemezsin.';
      icon = Icons.warning_amber;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
