import 'package:flutter/material.dart';

/// İki seçenekli "kaç kişi oynayacak" seçicisi: 1 Kişi / 2 Kişi. Platformdaki
/// her oyunun kurulum ekranı bunu kullanır, böylece tek/çift oyunculu seçim
/// deneyimi tüm oyunlarda tutarlı olur (bkz. CLAUDE.md — yeni oyun ekleme).
class PlayerCountSelector extends StatelessWidget {
  const PlayerCountSelector({
    super.key,
    required this.playerCount,
    required this.onChanged,
  });

  final int playerCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 1,
          label: Text('1 Kişi'),
          icon: Icon(Icons.person),
        ),
        ButtonSegment(
          value: 2,
          label: Text('2 Kişi'),
          icon: Icon(Icons.people),
        ),
      ],
      selected: {playerCount},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
