import 'package:flutter/material.dart';

import '../models/chess_piece.dart';

const Color _lightSquareColor = Color(0xFFEEEED2);
const Color _darkSquareColor = Color(0xFF769656);

/// Tahtadaki tek bir kare: taş glyph'i, geçerli hedef noktası ve seçili
/// vurgusu. 64 kez kullanıldığı ve görsel olarak yalın olmadığı için
/// `grid_cell.dart`/`memory_card_widget.dart` emsaline uygun ayrı bir
/// widget'a çıkarıldı. Açık/koyu kare renkleri temaya bağlı değil, sabit —
/// "istenmeden `AppThemeController` genişletme" kuralı (Kart Eşleştirme'nin
/// sabit kart arkası renginin gerekçesiyle aynı).
class ChessSquareWidget extends StatelessWidget {
  const ChessSquareWidget({
    super.key,
    required this.piece,
    required this.isLight,
    this.isSelected = false,
    this.isLegalDestination = false,
    this.onTap,
  });

  final ChessPiece? piece;
  final bool isLight;
  final bool isSelected;
  final bool isLegalDestination;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final baseColor = isLight ? _lightSquareColor : _darkSquareColor;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: baseColor),
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 3),
              ),
            ),
          if (piece != null)
            Center(
              child: Text(
                piece!.glyph,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          if (isLegalDestination)
            Center(
              child: Container(
                width: piece == null ? 14 : 34,
                height: piece == null ? 14 : 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: piece == null
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.transparent,
                  border: piece == null
                      ? null
                      : Border.all(
                          color: Colors.black.withValues(alpha: 0.35),
                          width: 3,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
