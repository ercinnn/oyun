import 'package:flutter/material.dart';

import '../models/game_catalog_entry.dart';
import 'star_rating.dart';

/// Bir oyunun [GameSkillRatings]'ini dört satırlık (Zeka/İngilizce/IQ/Hafıza)
/// bir tabloya döker. Tüm kartlarda aynı tablo şekli görünsün diye 0 puanlı
/// satırlar da (boş yıldızlarla) gösterilir, gizlenmez.
class SkillRatingsTable extends StatelessWidget {
  const SkillRatingsTable({super.key, required this.ratings});

  final GameSkillRatings ratings;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _row('Zeka', ratings.zeka, labelStyle),
        _row('İngilizce', ratings.ingilizce, labelStyle),
        _row('IQ', ratings.iq, labelStyle),
        _row('Hafıza', ratings.hafiza, labelStyle),
      ],
    );
  }

  TableRow _row(String label, int rating, TextStyle? labelStyle) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 2),
          child: Text(label, style: labelStyle),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: StarRating(rating: rating),
        ),
      ],
    );
  }
}
