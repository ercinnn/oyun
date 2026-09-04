import 'package:flutter/material.dart';

import '../models/chess_piece.dart';
import 'chess_piece_glyph.dart';

/// Klasik ahşap tahta paleti. Tahtanın çerçevesi
/// `screens/chess_game_screen.dart`'ta bu renklerle uyumlu koyu bir kasa
/// olarak çizilir.
const Color _lightSquareColor = Color(0xFFF0D9B5);
const Color _darkSquareColor = Color(0xFFB58863);
const Color _lightSquareLabel = Color(0xFF9C7A52);
const Color _darkSquareLabel = Color(0xFFF3E4CD);

/// Tahtadaki tek bir kare: taş, koordinat harfi/rakamı, seçim + son hamle +
/// şah vurguları ve geçerli hedef işareti. 64 kez kullanıldığı ve görsel
/// olarak yalın olmadığı için `grid_cell.dart`/`memory_card_widget.dart`
/// emsaline uygun ayrı bir widget'a çıkarıldı. Kare renkleri temaya bağlı
/// değil, sabit — "istenmeden `AppThemeController` genişletme" kuralı (Kart
/// Eşleştirme'nin sabit kart arkası renginin gerekçesiyle aynı).
class ChessSquareWidget extends StatelessWidget {
  const ChessSquareWidget({
    super.key,
    required this.piece,
    required this.isLight,
    this.isSelected = false,
    this.isLegalDestination = false,
    this.isLastMove = false,
    this.isCheckedKing = false,
    this.fileLabel,
    this.rankLabel,
    this.onTap,
  });

  /// Taşın sığdırıldığı kutunun, karenin kenar uzunluğuna oranı.
  ///
  /// 1'den büyük olması kasıtlı: [ChessPieceGlyph] kutusunun içinde
  /// kırpılmaya karşı bilerek pay bırakıyor (bkz. `_lineHeight`), dolayısıyla
  /// taşın görünen mürekkebi kutudan belirgin biçimde küçük. Bu oranla taş
  /// karenin ~%72'sini kaplıyor — gerçek satranç arayüzlerindeki orana yakın,
  /// eski sabit `fontSize: 30` çiziminin yaklaşık iki katı. Kutu kareyi
  /// taşsa da mürekkep taşmadığı için komşu kareye görsel sızma olmaz.
  static const _pieceScale = 1.12;

  final ChessPiece? piece;
  final bool isLight;
  final bool isSelected;
  final bool isLegalDestination;

  /// Son oynanan hamlenin kalkış/varış karesi — gerçek satranç arayüzlerinde
  /// standart olan bu vurgu, özellikle bilgisayarın hamlesini kaçırmamak için
  /// var.
  final bool isLastMove;

  /// Şah çekilmiş kral bu karede duruyorsa kırmızı hâle çizilir.
  final bool isCheckedKing;

  /// Yalnızca tahtanın alt sırasında (a-h) ve sol sütununda (1-8) dolu olur.
  final String? fileLabel;
  final String? rankLabel;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final baseColor = isLight ? _lightSquareColor : _darkSquareColor;
    final labelColor = isLight ? _lightSquareLabel : _darkSquareLabel;

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide;
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: baseColor),
              if (isCheckedKing)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE53935).withValues(alpha: 0.85),
                        const Color(0xFFE53935).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              if (isLastMove)
                ColoredBox(
                  color: const Color(0xFFF7D26B).withValues(alpha: 0.45),
                ),
              if (isSelected)
                ColoredBox(
                  color: const Color(0xFFF7C948).withValues(alpha: 0.55),
                ),
              if (rankLabel != null)
                Positioned(
                  top: size * 0.04,
                  left: size * 0.06,
                  child: Text(
                    rankLabel!,
                    style: TextStyle(
                      fontSize: size * 0.17,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ),
              if (fileLabel != null)
                Positioned(
                  bottom: size * 0.03,
                  right: size * 0.06,
                  child: Text(
                    fileLabel!,
                    style: TextStyle(
                      fontSize: size * 0.17,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ),
              if (piece != null)
                Center(
                  child: ChessPieceGlyph(
                    piece: piece!,
                    size: size * _pieceScale,
                  ),
                ),
              if (isLegalDestination)
                Center(
                  child: piece == null
                      ? Container(
                          width: size * 0.28,
                          height: size * 0.28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.22),
                          ),
                        )
                      : Container(
                          width: size * 0.94,
                          height: size * 0.94,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.28),
                              width: size * 0.07,
                            ),
                          ),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}
