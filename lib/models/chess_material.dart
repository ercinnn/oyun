import 'chess_piece.dart';

/// Standart taş değerleri (piyon 1, at/fil 3, kale 5, vezir 9) — ekranda
/// "+N" gibi insan-okur bir taş puanı farkı göstermek için.
///
/// `services/chess_ai.dart`'ın `_materialValue` tablosuyla (piyon 100, at
/// 320, fil 330, kale 500, vezir 900 — centipawn ölçeğinde, motor arama/
/// değerlendirme ayarı) KASITLI olarak ayrı ve farklı bir ölçekte: o tablo
/// motoru besliyor (320/330 gibi ince ayarlı piyon-üstü değerler, arama
/// derinliğinde anlamlı), bu tablo ise oyuncuya gösterilen "kaç taş
/// öndesin" sezgisini besliyor. İkisini birbirine bölerek (320/100=3.2 gibi)
/// türetmeye çalışmak yerine ayrı, sabit bir tablo tutmak daha basit ve
/// niyeti daha açık.
const Map<PieceType, int> chessStandardPieceValues = {
  PieceType.pawn: 1,
  PieceType.knight: 3,
  PieceType.bishop: 3,
  PieceType.rook: 5,
  PieceType.queen: 9,
  PieceType.king: 0,
};

/// Bir taş listesinin toplam standart değeri (bkz. [chessStandardPieceValues]).
int totalPieceValue(List<ChessPiece> pieces) => pieces.fold(
  0,
  (sum, piece) => sum + chessStandardPieceValues[piece.type]!,
);
