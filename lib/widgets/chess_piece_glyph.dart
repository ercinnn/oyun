import 'package:flutter/material.dart';

import '../models/chess_piece.dart';

/// Tek bir satranç taşının çizimi: [ChessPiece.solidGlyph] iki kez üst üste
/// çizilir — altta kontur (`Paint.stroke`), üstte dolgu. Böylece beyaz taşlar
/// gerçekten **beyaz dolgulu** olur; Unicode'un içi boş beyaz sembollerinde
/// olduğu gibi kare rengi taşın içinden görünmez.
///
/// **Neden sabit bir `fontSize` + [FittedBox]?** Satranç sembollerinin
/// mürekkebi, içinde bulunduğu metin kutusundan taşar (kullanılan yazı tipi
/// platforma göre değişir: web'de tarayıcının, masaüstünde işletim sisteminin
/// sembol fontu). `fontSize`'ı doğrudan karenin boyutuna eşitlemek bu yüzden
/// taşın altını kareye/tahta çerçevesine kırptırıyordu. Bunun yerine taş
/// bilerek bol satır yüksekliğiyle ([_lineHeight]) sabit bir ölçekte çizilip
/// [FittedBox] ile [size]'a sığdırılıyor: hangi yazı tipi gelirse gelsin
/// mürekkep kutunun içinde kalır, kırpılma olmaz.
class ChessPieceGlyph extends StatelessWidget {
  const ChessPieceGlyph({super.key, required this.piece, required this.size});

  /// Testlerin taşı sembol metnine bakmadan bulabilmesi için public
  /// (bkz. test/widget_test.dart, `find.byWidgetPredicate`).
  final ChessPiece piece;

  /// Taşın sığdırılacağı kare kutunun kenar uzunluğu.
  final double size;

  /// Sabit çizim ölçeği; ekrandaki gerçek boyutu [FittedBox] belirler.
  static const _renderFontSize = 100.0;

  /// Mürekkebin metin kutusundan taşmasına karşı pay. 1.0 kırpar, 1.32 her
  /// denenen platformda taşmayı tamamen içeri alıyor.
  static const _lineHeight = 1.32;

  static const _whiteFill = Color(0xFFFCFCFA);
  static const _blackFill = Color(0xFF2A2E36);
  static const _whiteOutline = Color(0xFF23272E);
  static const _blackOutline = Color(0xFF0A0C10);

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == PieceColor.white;
    const baseStyle = TextStyle(
      fontSize: _renderFontSize,
      height: _lineHeight,
      leadingDistribution: TextLeadingDistribution.even,
    );
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              piece.solidGlyph,
              style: baseStyle.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = _renderFontSize * 0.05
                  ..strokeJoin = StrokeJoin.round
                  ..color = isWhite ? _whiteOutline : _blackOutline,
              ),
            ),
            Text(
              piece.solidGlyph,
              style: baseStyle.copyWith(
                color: isWhite ? _whiteFill : _blackFill,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: _renderFontSize * 0.05,
                    offset: const Offset(0, _renderFontSize * 0.03),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
