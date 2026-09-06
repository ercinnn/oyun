import 'package:flutter/material.dart';

import '../models/chess_material.dart';
import '../models/chess_piece.dart';
import 'chess_piece_glyph.dart';

/// Bir tarafın ele geçirdiği taşları küçük simgeler halinde (en değerliden
/// en değersize sıralı) gösterir; o taraf taş puanında öndeyse sonuna "+N"
/// rozeti eklenir.
///
/// Sabit yükseklikli bir şerit içinde yaşadığı için (bkz.
/// `screens/chess_game_screen.dart`'ın `_BoardArea`'sı) ve teorik olarak 15
/// taşa kadar sığması gerektiğinden `Wrap` değil, yatay bir
/// `SingleChildScrollView` kullanılır — taşan içerik ikinci satıra kayıp
/// şeridi patlatmak yerine zarifçe kaydırılır. Rozet bilerek kaydırılan
/// alanın dışında: kayınca "+N" gözden kaybolmasın diye.
class ChessCapturedPieces extends StatelessWidget {
  const ChessCapturedPieces({
    super.key,
    required this.pieces,
    required this.advantage,
  });

  static const _glyphSize = 20.0;
  static const _advantageColor = Color(0xFF2E7D32);

  final List<ChessPiece> pieces;

  /// Bu taraf taş puanında öndeyse pozitif fark; değilse `null` (rozet
  /// çizilmez).
  final int? advantage;

  @override
  Widget build(BuildContext context) {
    final sorted = [...pieces]..sort(
      (a, b) => chessStandardPieceValues[b.type]!.compareTo(
        chessStandardPieceValues[a.type]!,
      ),
    );

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final piece in sorted)
                  ChessPieceGlyph(piece: piece, size: _glyphSize),
              ],
            ),
          ),
        ),
        if (advantage != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '+$advantage',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _advantageColor,
              ),
            ),
          ),
      ],
    );
  }
}
