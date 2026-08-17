import 'package:flutter/material.dart';

import '../models/memory_category.dart';

/// Kart eşleştirme oyununda sembol kategorisi seçici: Meyveler / Taşıtlar.
class MemoryCategorySelector extends StatelessWidget {
  const MemoryCategorySelector({
    super.key,
    required this.category,
    required this.onChanged,
  });

  final MemoryCategory category;
  final ValueChanged<MemoryCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MemoryCategory>(
      segments: const [
        ButtonSegment(
          value: MemoryCategory.fruits,
          label: Text('Meyveler'),
          icon: Text('🍎', style: TextStyle(fontSize: 16)),
        ),
        ButtonSegment(
          value: MemoryCategory.vehicles,
          label: Text('Taşıtlar'),
          icon: Text('🚗', style: TextStyle(fontSize: 16)),
        ),
      ],
      selected: {category},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
