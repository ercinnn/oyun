enum PieceType { pawn, knight, bishop, rook, queen, king }

enum PieceColor {
  white,
  black;

  PieceColor get opposite =>
      this == PieceColor.white ? PieceColor.black : PieceColor.white;
}

/// Tek bir satranç taşı: türü, rengi ve UI'da gösterilecek Unicode sembolü.
/// Değişmez (immutable) — bir kareden diğerine taşınırken aynı [ChessPiece]
/// örneği yeniden kullanılır, yeni bir örnek oluşturmaya gerek yoktur.
class ChessPiece {
  const ChessPiece(this.type, this.color);

  final PieceType type;
  final PieceColor color;

  static const Map<PieceType, String> _whiteGlyphs = {
    PieceType.king: '♔',
    PieceType.queen: '♕',
    PieceType.rook: '♖',
    PieceType.bishop: '♗',
    PieceType.knight: '♘',
    PieceType.pawn: '♙',
  };

  static const Map<PieceType, String> _blackGlyphs = {
    PieceType.king: '♚',
    PieceType.queen: '♛',
    PieceType.rook: '♜',
    PieceType.bishop: '♝',
    PieceType.knight: '♞',
    PieceType.pawn: '♟',
  };

  String get glyph => color == PieceColor.white
      ? _whiteGlyphs[type]!
      : _blackGlyphs[type]!;

  /// Taşın **içi dolu** sembolü — rengi ne olursa olsun "siyah" glyph seti.
  ///
  /// Unicode'un beyaz taş sembolleri (♔♕♖…) içi boş konturlardır: doğrudan
  /// çizildiklerinde taşın içinden kare rengi görünür ve tahtada "şeffaf" bir
  /// izlenim bırakır. Bunun yerine `widgets/chess_piece_glyph.dart` her iki
  /// renk için de bu dolu sembolü kullanır ve taşı beyaz/siyah dolgu +
  /// kontur olarak boyar. [glyph] hâlâ gerçek renk sembolünü döndürür (metin
  /// olarak taş göstermek gerekirse diye) — çizim yolu artık burasıdır.
  String get solidGlyph => _blackGlyphs[type]!;

  @override
  bool operator ==(Object other) =>
      other is ChessPiece && other.type == type && other.color == color;

  @override
  int get hashCode => Object.hash(type, color);
}
