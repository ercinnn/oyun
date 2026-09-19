import 'package:flutter/material.dart';

import '../models/plant_conditions.dart';

IconData plantFactorIcon(PlantFactor factor) => switch (factor) {
  PlantFactor.light => Icons.wb_sunny,
  PlantFactor.water => Icons.water_drop,
  PlantFactor.temperature => Icons.thermostat,
  PlantFactor.altitude => Icons.terrain,
};

/// Bir saksının üç etkenini seçtiren küçük form: her etken için üç
/// [ChoiceChip]. Şerit yerine [Wrap] kullanılır ki dar ekranda taşmasın.
/// Çip anahtarları `'{keyPrefix}_{etken}_{kademe}'` biçimindedir
/// (örn. `potB_light_0`).
class PlantConditionPicker extends StatelessWidget {
  const PlantConditionPicker({
    super.key,
    required this.title,
    required this.keyPrefix,
    required this.conditions,
    required this.onChanged,
  });

  final String title;
  final String keyPrefix;
  final PlantConditions conditions;
  final void Function(PlantFactor factor, int level) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final factor in PlantFactor.values) ...[
              Row(
                children: [
                  Icon(plantFactorIcon(factor), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    factor.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (var level = 0; level < plantLevelCount; level++)
                    ChoiceChip(
                      key: Key('${keyPrefix}_${factor.name}_$level'),
                      label: Text(factor.levelLabels[level]),
                      selected: conditions.levelOf(factor) == level,
                      onSelected: (_) => onChanged(factor, level),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
