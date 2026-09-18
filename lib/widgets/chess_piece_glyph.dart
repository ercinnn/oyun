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
    if (piece.type == PieceType.pawn) {
      // ♟ (U+265F) Android'de emoji fontuyla çizilir: boyamayı yok sayıp iki
      // renk için de aynı 3B görünümü verir. Piyon bu yüzden vektör çizilir.
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _PawnPainter(
            fill: isWhite ? _whiteFill : _blackFill,
            outline: isWhite ? _whiteOutline : _blackOutline,
          ),
        ),
      );
    }
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
                  ..strokeWidth = _renderFontSize * 0.005
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

/// Piyonun 2B siluetini 100×100'lük birim kutuda çizer; tek bir birleşik
/// yol olduğu için konturda parçaların iç kenarları görünmez.
class _PawnPainter extends CustomPainter {
  const _PawnPainter({required this.fill, required this.outline});

  final Color fill;
  final Color outline;

  static Path _shape() {
    final head = Path()
      ..addOval(Rect.fromCircle(center: const Offset(50, 27), radius: 13));
    final collar = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTRB(35, 39, 65, 48), const Radius.circular(4.5)));
    final body = Path()
      ..moveTo(42, 46)
      ..lineTo(58, 46)
      ..cubicTo(58, 62, 68, 68, 70, 80)
      ..lineTo(30, 80)
      ..cubicTo(32, 68, 42, 62, 42, 46)
      ..close();
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTRB(24, 78, 76, 90), const Radius.circular(5)));
    var result = head;
    for (final part in [collar, body, base]) {
      result = Path.combine(PathOperation.union, result, part);
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final path = _shape();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.5), 1.5, false);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..strokeJoin = StrokeJoin.round
        ..color = outline,
    );
  }

  @override
  bool shouldRepaint(_PawnPainter old) =>
      old.fill != fill || old.outline != outline;
}
