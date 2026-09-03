import 'chess_piece.dart';

enum ChessMoveFlag {
  normal,
  doublePawnPush,
  enPassantCapture,
  castleKingside,
  castleQueenside,
  promotion,
}

/// Tek bir hamle adayı. Terfi durumunda aynı `from`/`to` çifti için 4 ayrı
/// [ChessMove] üretilir (bkz. `ChessBoard.pseudoLegalMovesFrom`) — her biri
/// farklı bir [promotionType] taşır; UI hangisinin oynanacağını bir seçim
/// penceresiyle belirler.
class ChessMove {
  const ChessMove({
    required this.from,
    required this.to,
    required this.movingPiece,
    this.capturedPiece,
    this.flag = ChessMoveFlag.normal,
    this.promotionType,
  });

  final int from;
  final int to;
  final ChessPiece movingPiece;
  final ChessPiece? capturedPiece;
  final ChessMoveFlag flag;
  final PieceType? promotionType;

  bool get isCapture =>
      capturedPiece != null || flag == ChessMoveFlag.enPassantCapture;

  @override
  bool operator ==(Object other) =>
      other is ChessMove &&
      other.from == from &&
      other.to == to &&
      other.promotionType == promotionType;

  @override
  int get hashCode => Object.hash(from, to, promotionType);
}
