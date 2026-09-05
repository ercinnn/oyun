import 'package:flutter/material.dart';

import '../models/multiplication_difficulty.dart';

/// Çarpım Bahçesi'nde çarpan büyüklüğünü belirleyen seviye seçici:
/// Kolay / Orta / Zor. `widgets/memory_category_selector.dart` ile aynı şekil.
class MultiplicationDifficultySelector extends StatelessWidget {
  const MultiplicationDifficultySelector({
    super.key,
    required this.difficulty,
    required this.onChanged,
  });

  final MultiplicationDifficulty difficulty;
  final ValueChanged<MultiplicationDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MultiplicationDifficulty>(
      showSelectedIcon: false,
      segments: [
        for (final level in MultiplicationDifficulty.values)
          ButtonSegment(
            value: level,
            label: Text(level.label),
            tooltip: level.hint,
          ),
      ],
      selected: {difficulty},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
