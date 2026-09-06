import 'package:flutter/material.dart';

import '../models/game_catalog_entry.dart';
import '../theme/home_palette.dart';
import 'star_rating.dart';

/// Bir oyunun [GameSkillRatings]'ini beş hücreli (Zeka/IQ üstte,
/// Hafıza/Dikkat ortada, İngilizce tek başına altta) kompakt bir künyeye
/// döker. Tüm kartlarda aynı tablo şekli görünsün diye 0 puanlı satırlar da
/// (boş yıldızlarla) gösterilir, gizlenmez.
///
/// İki sütun tek sütun yerine bilinçli bir tercih: ana menü kartları sabit
/// yükseklikli bir ızgarada duruyor (bkz. `widgets/game_card.dart`), beş
/// satırlık dikey tablo o yüksekliğin çoğunu yiyordu. İngilizce üçüncü satırda
/// tek başına kalıyor çünkü beş, ikişerli eşleşmeyen tek sayı — İngilizce
/// seçildi çünkü platformdaki 10 oyunun 9'unda hâlâ 0 (bkz. Kart Eşleştirme
/// istisnası), yani "tek başına kalan" satır olarak en az göze batan bu.
class SkillRatingsTable extends StatelessWidget {
  const SkillRatingsTable({super.key, required this.ratings});

  static const _labelWidth = 62.0;

  final GameSkillRatings ratings;

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [_cell('Zeka', ratings.zeka), _cell('IQ', ratings.iq)],
        ),
        TableRow(
          children: [
            _cell('Hafıza', ratings.hafiza),
            _cell('Dikkat', ratings.dikkat),
          ],
        ),
        TableRow(
          children: [_cell('İngilizce', ratings.ingilizce), const SizedBox()],
        ),
      ],
    );
  }

  Widget _cell(String label, int rating) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: HomePalette.textMuted,
                letterSpacing: 0.2,
              ),
            ),
          ),
          StarRating(rating: rating, size: 12),
        ],
      ),
    );
  }
}
