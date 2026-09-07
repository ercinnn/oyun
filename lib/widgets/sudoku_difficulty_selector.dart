import 'package:flutter/material.dart';

import '../models/sudoku_difficulty.dart';

/// Sudoku'da ipucu sayısını belirleyen seviye seçici: Kolay / Orta / Zor.
/// `widgets/pattern_difficulty_selector.dart` ile aynı şekil.
class SudokuDifficultySelector extends StatelessWidget {
  const SudokuDifficultySelector({
    super.key,
    required this.difficulty,
    required this.onChanged,
  });

  final SudokuDifficulty difficulty;
  final ValueChanged<SudokuDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SudokuDifficulty>(
      showSelectedIcon: false,
      segments: [
        for (final level in SudokuDifficulty.values)
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
