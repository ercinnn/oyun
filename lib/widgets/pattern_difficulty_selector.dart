import 'package:flutter/material.dart';

import '../models/pattern_difficulty.dart';

/// Diziler'de kural tipini belirleyen seviye seçici: Kolay / Orta / Zor.
/// `widgets/multiplication_difficulty_selector.dart` ile aynı şekil.
class PatternDifficultySelector extends StatelessWidget {
  const PatternDifficultySelector({
    super.key,
    required this.difficulty,
    required this.onChanged,
  });

  final PatternDifficulty difficulty;
  final ValueChanged<PatternDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PatternDifficulty>(
      showSelectedIcon: false,
      segments: [
        for (final level in PatternDifficulty.values)
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
