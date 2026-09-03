import '../models/chess_board.dart';
import '../models/chess_move.dart';
import '../models/chess_piece.dart';
import '../models/chess_square.dart';

/// Ply cinsinden arama derinliği. Kendine has, benzersiz üst düzey isim —
/// `test/widget_test.dart` tüm controller/model dosyalarını tek dosyada
/// import ediyor, isim çakışması derleme hatası olurdu (bkz. diğer
/// oyunların round-count sabitleri için CLAUDE.md'deki aynı kural).
///
/// 3 ply seçildi: dallanma faktörü ~35 iken ham arama ağacı 35³≈43k yaprak,
/// MVV-LVA sıralamalı alfa-beta budamasıyla pratikte çok daha azına iner.
/// Web'de `dart:isolate`/`compute()` güvenilir olmadığından arama tamamen
/// senkron çalışır — bkz. `ChessController._makeAiMove`'daki `_generation`
/// korumalı gecikme, aramanın önce bir frame'in boyanmasına izin vermesi
/// için.
const int chessAiSearchDepth = 3;

const int _infinity = 1 << 30;
const int _mateScore = 1000000;

const Map<PieceType, int> _materialValue = {
  PieceType.pawn: 100,
  PieceType.knight: 320,
  PieceType.bishop: 330,
  PieceType.rook: 500,
  PieceType.queen: 900,
  PieceType.king: 0,
};

// Michniewski'nin bilinen "simplified evaluation" piece-square tabloları.
// Satır 0 = 8. sıra (üst), satır 7 = 1. sıra (alt), sütun 0..7 = a..h.
// Beyaz için `table[7 - rank][file]`, siyah için dikey ayna: `table[rank][file]`.
const List<List<int>> _pawnTable = [
  [0, 0, 0, 0, 0, 0, 0, 0],
  [50, 50, 50, 50, 50, 50, 50, 50],
  [10, 10, 20, 30, 30, 20, 10, 10],
  [5, 5, 10, 25, 25, 10, 5, 5],
  [0, 0, 0, 20, 20, 0, 0, 0],
  [5, -5, -10, 0, 0, -10, -5, 5],
  [5, 10, 10, -20, -20, 10, 10, 5],
  [0, 0, 0, 0, 0, 0, 0, 0],
];

const List<List<int>> _knightTable = [
  [-50, -40, -30, -30, -30, -30, -40, -50],
  [-40, -20, 0, 0, 0, 0, -20, -40],
  [-30, 0, 10, 15, 15, 10, 0, -30],
  [-30, 5, 15, 20, 20, 15, 5, -30],
  [-30, 0, 15, 20, 20, 15, 0, -30],
  [-30, 5, 10, 15, 15, 10, 5, -30],
  [-40, -20, 0, 5, 5, 0, -20, -40],
  [-50, -40, -30, -30, -30, -30, -40, -50],
];

const List<List<int>> _bishopTable = [
  [-20, -10, -10, -10, -10, -10, -10, -20],
  [-10, 0, 0, 0, 0, 0, 0, -10],
  [-10, 0, 5, 10, 10, 5, 0, -10],
  [-10, 5, 5, 10, 10, 5, 5, -10],
  [-10, 0, 10, 10, 10, 10, 0, -10],
  [-10, 10, 10, 10, 10, 10, 10, -10],
  [-10, 5, 0, 0, 0, 0, 5, -10],
  [-20, -10, -10, -10, -10, -10, -10, -20],
];

const List<List<int>> _rookTable = [
  [0, 0, 0, 0, 0, 0, 0, 0],
  [5, 10, 10, 10, 10, 10, 10, 5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [0, 0, 0, 5, 5, 0, 0, 0],
];

const List<List<int>> _queenTable = [
  [-20, -10, -10, -5, -5, -10, -10, -20],
  [-10, 0, 0, 0, 0, 0, 0, -10],
  [-10, 0, 5, 5, 5, 5, 0, -10],
  [-5, 0, 5, 5, 5, 5, 0, -5],
  [0, 0, 5, 5, 5, 5, 0, -5],
  [-10, 5, 5, 5, 5, 5, 0, -10],
  [-10, 0, 5, 0, 0, 0, 0, -10],
  [-20, -10, -10, -5, -5, -10, -10, -20],
];

// Yalnızca orta oyun tablosu — oyun fazına göre kralı merkeze çeken ayrı bir
// endgame tablosu bilerek eklenmedi (bkz. CLAUDE.md: gerçek ama kabul
// edilebilir bir basitleştirme, gündelik bir platform rakibi için yeterli).
const List<List<int>> _kingTable = [
  [-30, -40, -40, -50, -50, -40, -40, -30],
  [-30, -40, -40, -50, -50, -40, -40, -30],
  [-30, -40, -40, -50, -50, -40, -40, -30],
  [-30, -40, -40, -50, -50, -40, -40, -30],
  [-20, -30, -30, -40, -40, -30, -30, -20],
  [-10, -20, -20, -20, -20, -20, -20, -10],
  [20, 20, 0, 0, 0, 0, 20, 20],
  [20, 30, 10, 0, 0, 10, 30, 20],
];

const Map<PieceType, List<List<int>>> _pieceSquareTables = {
  PieceType.pawn: _pawnTable,
  PieceType.knight: _knightTable,
  PieceType.bishop: _bishopTable,
  PieceType.rook: _rookTable,
  PieceType.queen: _queenTable,
  PieceType.king: _kingTable,
};

/// Saf Dart satranç motoru: negamax + alfa-beta budama (minimax'ın
/// standart tek-fonksiyonlu hâli). Flutter bağımlılığı yok, `ChessBoard`
/// üzerinde çalışır.
class ChessAI {
  ChessMove? findBestMove(ChessBoard board, {int depth = chessAiSearchDepth}) {
    final moves = board.legalMoves(board.sideToMove);
    if (moves.isEmpty) return null;
    _orderMoves(moves);

    ChessMove? best;
    var bestScore = -_infinity;
    var alpha = -_infinity;
    const beta = _infinity;

    for (final move in moves) {
      final child = board.applyMove(move);
      final score = -_negamax(child, depth - 1, -beta, -alpha);
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
      if (score > alpha) alpha = score;
    }
    return best;
  }

  int _negamax(ChessBoard board, int depth, int alpha, int beta) {
    final moves = board.legalMoves(board.sideToMove);
    if (moves.isEmpty) {
      // Daha hızlı matlar tercih edilsin diye skor kalan derinliğe göre
      // ayarlanıyor: `depth` ne kadar büyükse (mat kökten o kadar yakın
      // bulunmuşsa) skor o kadar keskin.
      return board.isInCheck ? -(_mateScore + depth) : 0;
    }
    if (depth == 0) {
      return _evaluate(board, board.sideToMove);
    }
    _orderMoves(moves);
    var best = -_infinity;
    for (final move in moves) {
      final child = board.applyMove(move);
      final score = -_negamax(child, depth - 1, -beta, -alpha);
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  void _orderMoves(List<ChessMove> moves) {
    moves.sort((a, b) => _moveOrderScore(b).compareTo(_moveOrderScore(a)));
  }

  int _moveOrderScore(ChessMove move) {
    var score = 0;
    if (move.isCapture) {
      final capturedValue = move.capturedPiece != null
          ? _materialValue[move.capturedPiece!.type]!
          : _materialValue[PieceType.pawn]!; // geçerken alma her zaman piyon
      final attackerValue = _materialValue[move.movingPiece.type]!;
      score += 10 * capturedValue - attackerValue;
    }
    if (move.flag == ChessMoveFlag.promotion &&
        move.promotionType == PieceType.queen) {
      score += 800;
    }
    return score;
  }

  int _evaluate(ChessBoard board, PieceColor perspective) {
    var score = 0;
    for (var i = 0; i < 64; i++) {
      final piece = board.squares[i];
      if (piece == null) continue;
      final value = _materialValue[piece.type]! + _pstValue(piece, i);
      score += piece.color == PieceColor.white ? value : -value;
    }
    return perspective == PieceColor.white ? score : -score;
  }

  int _pstValue(ChessPiece piece, int square) {
    final table = _pieceSquareTables[piece.type]!;
    final file = fileOf(square);
    final rank = rankOf(square);
    final row = piece.color == PieceColor.white ? 7 - rank : rank;
    return table[row][file];
  }
}
