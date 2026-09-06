import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _spacing = 4;
const double _minCellSize = 14;
const double _maxCellSize = 44;

/// Birikimli toplam etiketleri için ızgaranın sağında ayrılan taban genişlik.
/// Birim varsa ("12 gün") bunun üzerine harf başına biraz daha eklenir.
const double _totalLabelWidth = 56;

/// Çarpım Bahçesi'nin görsel çekirdeği: [rows] sıra × [columns] sütun nesneden
/// oluşan bir dizi (array).
///
/// Oyunun üç yerinde de aynı widget kullanılır — okuma turunda soru olarak,
/// kurma turunda oyuncunun inşa ettiği ızgara olarak, açıklama panelinde de
/// dersin kendisi olarak — bu yüzden ekran dosyasında değil `lib/widgets/`
/// altında yaşıyor (bkz. `grid_cell.dart` / `memory_card_widget.dart`).
///
/// Hücre boyutu `widgets/number_grid.dart`'taki teknikle
/// [LayoutBuilder]'dan hesaplanır ve kırpılır: "Zor" seviyede 12 × 12'lik bir
/// ızgara da dar bir pencerede taşmadan sığsın diye. Sabit bir hücre boyutu
/// tek bir ekran genişliğinde doğru görünürdü.
///
/// [rowLeadingEmoji] ve [columnHeaderEmoji], aynı dikdörtgenin farklı gerçek
/// hayat sahnelerinde ne anlama geldiğini görünür kılan iki kenar şeridi:
/// eşit grup sahnelerinde her sıranın başına grubun kendisi (🚲 → 🛞 🛞),
/// kombinasyon sahnelerinde ayrıca sütunların üstüne ikinci küme (👕 × 👖)
/// çizilir. İkisi de yalnızca etikettir — sayıma dahil değildir.
class MultiplicationArrayView extends StatelessWidget {
  const MultiplicationArrayView({
    super.key,
    required this.rows,
    required this.columns,
    required this.emoji,
    this.maxRows,
    this.maxColumns,
    this.showRunningTotals = false,
    this.rowLeadingEmoji,
    this.columnHeaderEmoji,
    this.totalUnit = '',
  });

  /// Dolu (nesne çizilen) sıra ve sütun sayısı.
  final int rows;
  final int columns;

  final String emoji;

  /// Kurma turunda ızgaranın büyüyeceği en büyük boyut. Verildiğinde boş
  /// hücreler soluk yer tutucu olarak çizilir ve hücre boyutu bu tavana göre
  /// hesaplanır — böylece oyuncu sıra eklerken ızgara zıplamaz, sadece dolar.
  final int? maxRows;
  final int? maxColumns;

  /// Her sıranın sağına o sıraya kadarki birikimli toplamı yazar (4, 8, 12…)
  /// ve bunları sırayla belirtir. Açıklama panelinin "toplaya toplaya
  /// gidiyoruz" anlatımı bu.
  final bool showRunningTotals;

  /// Her sıranın soluna konan grup emojisi (eşit grup / kombinasyon
  /// sahnelerinde). `null` ise şerit hiç çizilmez.
  final String? rowLeadingEmoji;

  /// Sütunların üstüne konan ikinci küme emojisi (yalnız kombinasyon).
  final String? columnHeaderEmoji;

  /// Birikimli toplamların birimi (" TL", " gün", " m²").
  final String totalUnit;

  @override
  Widget build(BuildContext context) {
    final layoutRows = math.max(rows, maxRows ?? rows);
    final layoutColumns = math.max(columns, maxColumns ?? columns);
    final leading = rowLeadingEmoji;
    final header = columnHeaderEmoji;

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = showRunningTotals
            ? _totalLabelWidth + totalUnit.length * 8
            : 0.0;
        // Kenar şeritleri de birer hücre genişliği/yüksekliği kadar yer
        // kapladığı için hücre boyutu hesabına sanal bir sütun/sıra olarak
        // girer; yoksa şerit eklenince ızgara taşardı.
        final gridColumns = layoutColumns + (leading != null ? 1 : 0);
        final gridRows = layoutRows + (header != null ? 1 : 0);

        final cellFromWidth =
            (constraints.maxWidth - labelWidth - (gridColumns - 1) * _spacing) /
            gridColumns;
        final cellFromHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - (gridRows - 1) * _spacing) / gridRows
            : _maxCellSize;
        final cellSize = math
            .min(cellFromWidth, cellFromHeight)
            .clamp(_minCellSize, _maxCellSize)
            .toDouble();

        return Center(
          // Son çare emniyet ağı: hücre boyutu [_minCellSize]'a kırpıldığında
          // (çok dar bir ekranda 12 × 12) ızgara yine de sığmayabilir; taşma
          // debug'da sert hata olduğu için küçültmeyi tercih ediyoruz.
          // Normal boyutlarda scaleDown hiç devreye girmez.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: TweenAnimationBuilder<double>(
              // Tur değiştiğinde animasyon baştan başlasın diye turu tanımlayan
              // bir anahtar veriyoruz.
              key: ValueKey('$rows-$columns-$emoji-$showRunningTotals'),
              tween: Tween(begin: 0, end: rows.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, revealed, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (header != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: _spacing),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leading != null)
                              Padding(
                                padding: const EdgeInsets.only(right: _spacing),
                                child: SizedBox.square(dimension: cellSize),
                              ),
                            for (var col = 0; col < layoutColumns; col++)
                              Padding(
                                padding: EdgeInsets.only(
                                  right: col == layoutColumns - 1
                                      ? 0
                                      : _spacing,
                                ),
                                child: _LabelCell(
                                  size: cellSize,
                                  emoji: col < columns ? header : null,
                                ),
                              ),
                            if (showRunningTotals) SizedBox(width: labelWidth),
                          ],
                        ),
                      ),
                    for (var row = 0; row < layoutRows; row++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: row == layoutRows - 1 ? 0 : _spacing,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leading != null)
                              Padding(
                                padding: const EdgeInsets.only(right: _spacing),
                                child: _LabelCell(
                                  size: cellSize,
                                  emoji: row < rows ? leading : null,
                                ),
                              ),
                            for (var col = 0; col < layoutColumns; col++)
                              Padding(
                                padding: EdgeInsets.only(
                                  right: col == layoutColumns - 1
                                      ? 0
                                      : _spacing,
                                ),
                                child: _ArrayCell(
                                  size: cellSize,
                                  emoji: row < rows && col < columns
                                      ? emoji
                                      : null,
                                ),
                              ),
                            if (showRunningTotals)
                              SizedBox(
                                width: labelWidth,
                                child: Opacity(
                                  opacity: (revealed - row).clamp(0.0, 1.0),
                                  child: Text(
                                    row < rows
                                        ? '= ${(row + 1) * columns}$totalUnit'
                                        : '',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: math.min(cellSize * 0.6, 16),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Tek bir ızgara hücresi: dolu ise nesne, boş ise soluk yer tutucu.
class _ArrayCell extends StatelessWidget {
  const _ArrayCell({required this.size, required this.emoji});

  final double size;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final filled = emoji != null;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? Colors.green.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: filled ? Colors.green.shade300 : Colors.black12,
          width: 1,
        ),
      ),
      child: filled
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.6))
          : null,
    );
  }
}

/// Kenar şeridi hücresi: sıranın grubunu ya da sütunun kümesini gösteren
/// etiket. Bilerek çerçevesizdir — sayılan nesnelerle karışmaması, "bu da bir
/// tane daha" diye sayılmaması gerekiyor.
class _LabelCell extends StatelessWidget {
  const _LabelCell({required this.size, required this.emoji});

  final double size;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: emoji == null
          ? null
          : Center(
              child: Text(emoji!, style: TextStyle(fontSize: size * 0.7)),
            ),
    );
  }
}
