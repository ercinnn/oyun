import 'chess_board.dart';
import 'chess_move.dart';
import 'chess_piece.dart';
import 'chess_square.dart';

/// Taş harfleri **Türkçe**: Şah, Vezir, Kale, Fil, At. Uygulamanın tamamı
/// Türkçe olduğu için uluslararası K/Q/R/B/N yerine bunlar kullanılıyor;
/// piyonun harfi yok (standart cebirsel gösterimde olduğu gibi).
const Map<PieceType, String> chessPieceLetters = {
  PieceType.king: 'Ş',
  PieceType.queen: 'V',
  PieceType.rook: 'K',
  PieceType.bishop: 'F',
  PieceType.knight: 'A',
  PieceType.pawn: '',
};

/// Bir hamlenin cebirsel gösterimi ("e4", "Axd5", "0-0", "e8=V+", "Kad1").
///
/// [before] hamleden **önceki**, [after] hamleden **sonraki** tahta olmalı:
/// ilki aynı kareye gidebilen ikinci bir taş olup olmadığını (belirsizlik
/// eki) bilmek, ikincisi şah/mat ekini koymak için gerekli. Gösterim bu
/// yüzden hamle oynandığı anda üretilip saklanıyor
/// (`ChessController.moveNotations`); sonradan üretmek tüm oyunu baştan
/// oynatmayı gerektirirdi.
String chessMoveNotation({
  required ChessBoard before,
  required ChessMove move,
  required ChessBoard after,
}) {
  final suffix = after.isCheckmate
      ? '#'
      : after.isInCheck
      ? '+'
      : '';

  if (move.flag == ChessMoveFlag.castleKingside) return '0-0$suffix';
  if (move.flag == ChessMoveFlag.castleQueenside) return '0-0-0$suffix';

  final target = algebraic(move.to);
  final buffer = StringBuffer();

  if (move.movingPiece.type == PieceType.pawn) {
    // Piyon almalarında kalkış dosyası yazılır: "exd5".
    if (move.isCapture) buffer.write(algebraic(move.from)[0]);
  } else {
    buffer.write(chessPieceLetters[move.movingPiece.type]);
    buffer.write(_disambiguation(before, move));
  }

  if (move.isCapture) buffer.write('x');
  buffer.write(target);

  if (move.promotionType != null) {
    buffer.write('=${chessPieceLetters[move.promotionType!]}');
  }
  buffer.write(suffix);
  return buffer.toString();
}

/// Aynı türden başka bir taş da bu kareye gidebiliyorsa kalkış karesinden
/// ayırt edici kısmı döndürür: önce dosya ("Kad1"), dosya da yetmiyorsa sıra
/// ("K1d2"), o da yetmiyorsa tam kare ("Ka1d1").
String _disambiguation(ChessBoard before, ChessMove move) {
  final rivals = before
      .legalMoves(move.movingPiece.color)
      .where(
        (m) =>
            m.to == move.to &&
            m.from != move.from &&
            m.movingPiece.type == move.movingPiece.type,
      )
      .toList();
  if (rivals.isEmpty) return '';

  final from = algebraic(move.from);
  final sameFile = rivals.any((m) => fileOf(m.from) == fileOf(move.from));
  final sameRank = rivals.any((m) => rankOf(m.from) == rankOf(move.from));
  if (!sameFile) return from[0];
  if (!sameRank) return from[1];
  return from;
}
