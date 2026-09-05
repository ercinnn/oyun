import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _spacing = 4;
const double _minCellSize = 14;
const double _maxCellSize = 44;

/// Birikimli toplam etiketleri için ızgaranın sağında ayrılan sabit genişlik.
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
class MultiplicationArrayView extends StatelessWidget {
  const MultiplicationArrayView({
    super.key,
    required this.rows,
    required this.columns,
    required this.emoji,
    this.maxRows,
    this.maxColumns,
    this.showRunningTotals = false,
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

  @override
  Widget build(BuildContext context) {
    final layoutRows = math.max(rows, maxRows ?? rows);
    final layoutColumns = math.max(columns, maxColumns ?? columns);

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = showRunningTotals ? _totalLabelWidth : 0.0;
        final cellFromWidth =
            (constraints.maxWidth -
                labelWidth -
                (layoutColumns - 1) * _spacing) /
            layoutColumns;
        final cellFromHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - (layoutRows - 1) * _spacing) / layoutRows
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
                    for (var row = 0; row < layoutRows; row++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: row == layoutRows - 1 ? 0 : _spacing,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                                width: _totalLabelWidth,
                                child: Opacity(
                                  opacity: (revealed - row).clamp(0.0, 1.0),
                                  child: Text(
                                    row < rows
                                        ? '= ${(row + 1) * columns}'
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
