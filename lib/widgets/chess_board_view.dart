import 'package:flutter/material.dart';

import '../models/chess_piece.dart';
import '../models/chess_square.dart';
import 'chess_square_widget.dart';

/// Tahtayı saran koyu ahşap kasa: kareler bittiği yerde tahta bitmesin diye
/// ince bir çerçeve, yumuşak bir gölge ve yuvarlatılmış köşeler. Kırpma
/// [ClipRRect] ile yapılır, böylece köşedeki kareler çerçevenin dışına
/// taşmaz. Oyun ekranı ile ders ekranı aynı kasayı kullanır.
class ChessBoardFrame extends StatelessWidget {
  const ChessBoardFrame({super.key, required this.child});

  static const _frameColor = Color(0xFF4A3728);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: _frameColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: child,
      ),
    );
  }
}

/// 8x8 tahta çizimi. Denetleyiciden bağımsızdır: oyun ekranı
/// `ChessController`'ın, ders ekranı `ChessLessonController`'ın durumunu
/// buraya düz parametreler olarak verir.
///
/// Tahta döndürme ([flipped]) hangi kare index'inin hangi hücreye
/// çizileceğini değiştirerek yapılır (`displayOrder`); widget ağacını
/// döndürmek taşların glyph'lerini de ters çevirirdi.
class ChessBoardView extends StatelessWidget {
  const ChessBoardView({
    super.key,
    required this.squares,
    required this.flipped,
    required this.onSquareTap,
    this.selectedSquare,
    this.legalTargets = const {},
    this.lastMoveSquares = const {},
    this.checkedKingSquare,
    this.hintSquares = const {},
  });

  static const _fileLetters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  final List<ChessPiece?> squares;
  final bool flipped;
  final void Function(int square) onSquareTap;
  final int? selectedSquare;
  final Set<int> legalTargets;

  /// Son hamlenin kalkış ve varış kareleri (boşsa vurgu yok).
  final Set<int> lastMoveSquares;
  final int? checkedKingSquare;

  /// Ders ekranının anlatımda vurguladığı kareler.
  final Set<int> hintSquares;

  @override
  Widget build(BuildContext context) {
    final ranks = flipped
        ? List<int>.generate(8, (r) => r)
        : List<int>.generate(8, (r) => 7 - r);
    final files = flipped
        ? List<int>.generate(8, (f) => 7 - f)
        : List<int>.generate(8, (f) => f);
    final displayOrder = [
      for (final r in ranks)
        for (final f in files) squareIndex(f, r),
    ];

    return GridView.count(
      crossAxisCount: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < displayOrder.length; i++)
          ChessSquareWidget(
            key: ValueKey('sq_${displayOrder[i]}'),
            piece: squares[displayOrder[i]],
            // a1 (file 0, rank 0) koyu kare olmalı — gerçek satranç
            // diziliminin tersine dönmemesi için toplam tek olduğunda açık.
            isLight: (fileOf(displayOrder[i]) + rankOf(displayOrder[i])).isOdd,
            isSelected: selectedSquare == displayOrder[i],
            isLegalDestination: legalTargets.contains(displayOrder[i]),
            isLastMove: lastMoveSquares.contains(displayOrder[i]),
            isCheckedKing: checkedKingSquare == displayOrder[i],
            isHint: hintSquares.contains(displayOrder[i]),
            // Koordinatlar tahtanın kendi kenarlarına yazılır: sol sütuna
            // sıra numarası, alt satıra dosya harfi. Tahta döndüğünde
            // displayOrder da döndüğü için etiketler kendiliğinden doğru
            // kareye denk gelir.
            rankLabel: i % 8 == 0 ? '${rankOf(displayOrder[i]) + 1}' : null,
            fileLabel: i ~/ 8 == 7 ? _fileLetters[fileOf(displayOrder[i])] : null,
            onTap: () => onSquareTap(displayOrder[i]),
          ),
      ],
    );
  }
}
