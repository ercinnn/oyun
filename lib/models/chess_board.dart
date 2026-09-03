import 'chess_move.dart';
import 'chess_piece.dart';
import 'chess_square.dart';

const List<(int, int)> _bishopDirs = [(1, 1), (1, -1), (-1, 1), (-1, -1)];
const List<(int, int)> _rookDirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
const List<(int, int)> _queenDirs = [..._bishopDirs, ..._rookDirs];
const List<(int, int)> _knightDeltas = [
  (1, 2), (2, 1), (2, -1), (1, -2),
  (-1, -2), (-2, -1), (-2, 1), (-1, 2),
];
const List<(int, int)> _kingDeltas = [
  (1, 0), (1, 1), (0, 1), (-1, 1),
  (-1, 0), (-1, -1), (0, -1), (1, -1),
];

/// Satrancın tüm kural motoru: pozisyon durumu (taşlar, sıra, rok hakları,
/// geçerken alma hedefi) ve hamle üretimi/geçerlilik/oyun-sonu tespiti
/// burada toplanıyor.
///
/// [applyMove] mevcut tahtayı DEĞİŞTİRMEZ, her zaman yeni bir [ChessBoard]
/// döndürür — elle yazılmış bir `undoMove()` yok. Bunun nedeni: rok
/// hakları/geçerken alma hedefi/yarım-hamle sayacı gibi durumları tam
/// tersine çeviren bir undo, satranç motorlarının en hataya açık kısmıdır;
/// tahta sadece 64 elemanlı olduğu için klonlamak (hem gerçek oyun hem AI
/// araması için) bu hata kategorisini tamamen ortadan kaldırır ve tek bir
/// kod yolu her ikisine de hizmet eder.
class ChessBoard {
  ChessBoard._({
    required this.squares,
    required this.sideToMove,
    required this.whiteKingsideRights,
    required this.whiteQueensideRights,
    required this.blackKingsideRights,
    required this.blackQueensideRights,
    required this.enPassantTargetSquare,
    required this.halfMoveClock,
    required this.moveHistory,
    required this.positionSignatures,
  });

  /// Uzunluk 64, `index = rank*8 + file`. Boş tahta ve serbestçe atanabilir
  /// olması (`ChessController.board = ...`) testlerin özel pozisyonlar
  /// kurup doğrudan mutatörleri çağırabilmesini sağlar — bkz. Kayan
  /// Yapboz'un `controller.currentPlayer.tiles` doğrudan set etme emsali.
  final List<ChessPiece?> squares;
  final PieceColor sideToMove;
  final bool whiteKingsideRights;
  final bool whiteQueensideRights;
  final bool blackKingsideRights;
  final bool blackQueensideRights;
  final int? enPassantTargetSquare;
  final int halfMoveClock;
  final List<ChessMove> moveHistory;
  final List<String> positionSignatures;

  /// Boş bir tahta — testlerin özel pozisyonlar kurması için.
  factory ChessBoard.empty() => ChessBoard.custom(
    squares: List<ChessPiece?>.filled(64, null),
  );

  /// Rok hakları/sıra/geçerken alma hedefi dahil isteğe bağlı her alanı
  /// doğrudan belirleyen genel amaçlı kurucu — testlerin rok, geçerken alma,
  /// mat/pat gibi özel pozisyonları tek adımda kurabilmesi için (diğer tüm
  /// alanlar `ChessBoard`'un kendisi kadar `final` olduğundan, `empty()` ile
  /// kurulup sonradan mutasyona uğratılamazlar — yalnızca `squares`
  /// listesinin elemanları değiştirilebilir).
  factory ChessBoard.custom({
    required List<ChessPiece?> squares,
    PieceColor sideToMove = PieceColor.white,
    bool whiteKingsideRights = false,
    bool whiteQueensideRights = false,
    bool blackKingsideRights = false,
    bool blackQueensideRights = false,
    int? enPassantTargetSquare,
    int halfMoveClock = 0,
  }) {
    return ChessBoard._(
      squares: List<ChessPiece?>.of(squares),
      sideToMove: sideToMove,
      whiteKingsideRights: whiteKingsideRights,
      whiteQueensideRights: whiteQueensideRights,
      blackKingsideRights: blackKingsideRights,
      blackQueensideRights: blackQueensideRights,
      enPassantTargetSquare: enPassantTargetSquare,
      halfMoveClock: halfMoveClock,
      moveHistory: const [],
      positionSignatures: const [],
    );
  }

  /// Standart satranç başlangıç dizilimi.
  factory ChessBoard.initial() {
    final squares = List<ChessPiece?>.filled(64, null);
    const backRank = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook,
    ];
    for (var file = 0; file < 8; file++) {
      squares[squareIndex(file, 0)] = ChessPiece(
        backRank[file],
        PieceColor.white,
      );
      squares[squareIndex(file, 1)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.white,
      );
      squares[squareIndex(file, 6)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.black,
      );
      squares[squareIndex(file, 7)] = ChessPiece(
        backRank[file],
        PieceColor.black,
      );
    }
    return ChessBoard._(
      squares: squares,
      sideToMove: PieceColor.white,
      whiteKingsideRights: true,
      whiteQueensideRights: true,
      blackKingsideRights: true,
      blackQueensideRights: true,
      enPassantTargetSquare: null,
      halfMoveClock: 0,
      moveHistory: const [],
      positionSignatures: const [],
    );
  }

  int? kingSquare(PieceColor color) {
    for (var i = 0; i < 64; i++) {
      final piece = squares[i];
      if (piece != null && piece.type == PieceType.king && piece.color == color) {
        return i;
      }
    }
    return null;
  }

  bool get isInCheck {
    final kingSq = kingSquare(sideToMove);
    if (kingSq == null) return false;
    return isSquareAttacked(kingSq, sideToMove.opposite);
  }

  bool get isCheckmate => isInCheck && legalMoves(sideToMove).isEmpty;

  bool get isStalemate => !isInCheck && legalMoves(sideToMove).isEmpty;

  bool get isDrawByFiftyMoveRule => halfMoveClock >= 100;

  bool get isDrawByRepetition {
    if (positionSignatures.isEmpty) return false;
    final current = positionSignatures.last;
    return positionSignatures.where((s) => s == current).length >= 3;
  }

  /// K-vs-K ve K+tek hafif taş-vs-K'yı kapsar; aynı renkli fil-vs-fil gibi
  /// nadir kenar durumları bilerek atlanıyor — yanlış yönde güvenli bir
  /// basitleştirme (oyun gereksiz yere devam eder, erken berabere ilan
  /// etmez).
  bool get isDrawByInsufficientMaterial {
    final nonKings = squares
        .whereType<ChessPiece>()
        .where((p) => p.type != PieceType.king)
        .toList();
    if (nonKings.isEmpty) return true;
    if (nonKings.length == 1 &&
        (nonKings.single.type == PieceType.knight ||
            nonKings.single.type == PieceType.bishop)) {
      return true;
    }
    return false;
  }

  List<ChessMove> pseudoLegalMovesFrom(int square) {
    final piece = squares[square];
    if (piece == null) return const [];
    switch (piece.type) {
      case PieceType.pawn:
        return _pawnMoves(square, piece);
      case PieceType.knight:
        return _steppingMoves(square, piece, _knightDeltas);
      case PieceType.bishop:
        return _slidingMoves(square, piece, _bishopDirs);
      case PieceType.rook:
        return _slidingMoves(square, piece, _rookDirs);
      case PieceType.queen:
        return _slidingMoves(square, piece, _queenDirs);
      case PieceType.king:
        return _kingMoves(square, piece);
    }
  }

  List<ChessMove> pseudoLegalMoves(PieceColor color) {
    final moves = <ChessMove>[];
    for (var i = 0; i < 64; i++) {
      final piece = squares[i];
      if (piece != null && piece.color == color) {
        moves.addAll(pseudoLegalMovesFrom(i));
      }
    }
    return moves;
  }

  List<ChessMove> legalMovesFrom(int square) {
    final piece = squares[square];
    if (piece == null) return const [];
    return pseudoLegalMovesFrom(
      square,
    ).where((m) => _isSafeAfter(m, piece.color)).toList();
  }

  List<ChessMove> legalMoves(PieceColor color) {
    final moves = <ChessMove>[];
    for (var i = 0; i < 64; i++) {
      final piece = squares[i];
      if (piece != null && piece.color == color) {
        moves.addAll(legalMovesFrom(i));
      }
    }
    return moves;
  }

  bool _isSafeAfter(ChessMove move, PieceColor color) {
    final result = applyMove(move);
    final kingSq = result.kingSquare(color);
    if (kingSq == null) return true;
    return !result.isSquareAttacked(kingSq, color.opposite);
  }

  bool isSquareAttacked(int square, PieceColor byColor) {
    for (var i = 0; i < 64; i++) {
      final piece = squares[i];
      if (piece == null || piece.color != byColor) continue;
      if (_attacks(i, piece, square)) return true;
    }
    return false;
  }

  bool _attacks(int from, ChessPiece piece, int target) {
    final f0 = fileOf(from);
    final r0 = rankOf(from);
    final ft = fileOf(target);
    final rt = rankOf(target);
    switch (piece.type) {
      case PieceType.pawn:
        final dir = piece.color == PieceColor.white ? 1 : -1;
        return rt == r0 + dir && (ft == f0 - 1 || ft == f0 + 1);
      case PieceType.knight:
        final df = (ft - f0).abs();
        final dr = (rt - r0).abs();
        return (df == 1 && dr == 2) || (df == 2 && dr == 1);
      case PieceType.king:
        final df = (ft - f0).abs();
        final dr = (rt - r0).abs();
        return df <= 1 && dr <= 1 && (df != 0 || dr != 0);
      case PieceType.bishop:
        return _slidingAttacks(from, target, _bishopDirs);
      case PieceType.rook:
        return _slidingAttacks(from, target, _rookDirs);
      case PieceType.queen:
        return _slidingAttacks(from, target, _queenDirs);
    }
  }

  bool _slidingAttacks(int from, int target, List<(int, int)> dirs) {
    final f0 = fileOf(from);
    final r0 = rankOf(from);
    for (final dir in dirs) {
      var f = f0 + dir.$1;
      var r = r0 + dir.$2;
      while (isOnBoard(f, r)) {
        final sq = squareIndex(f, r);
        if (sq == target) return true;
        if (squares[sq] != null) break;
        f += dir.$1;
        r += dir.$2;
      }
    }
    return false;
  }

  List<ChessMove> _slidingMoves(
    int square,
    ChessPiece piece,
    List<(int, int)> dirs,
  ) {
    final moves = <ChessMove>[];
    final f0 = fileOf(square);
    final r0 = rankOf(square);
    for (final dir in dirs) {
      var f = f0 + dir.$1;
      var r = r0 + dir.$2;
      while (isOnBoard(f, r)) {
        final to = squareIndex(f, r);
        final occupant = squares[to];
        if (occupant == null) {
          moves.add(ChessMove(from: square, to: to, movingPiece: piece));
        } else {
          if (occupant.color != piece.color) {
            moves.add(
              ChessMove(
                from: square,
                to: to,
                movingPiece: piece,
                capturedPiece: occupant,
              ),
            );
          }
          break;
        }
        f += dir.$1;
        r += dir.$2;
      }
    }
    return moves;
  }

  List<ChessMove> _steppingMoves(
    int square,
    ChessPiece piece,
    List<(int, int)> deltas,
  ) {
    final moves = <ChessMove>[];
    final f0 = fileOf(square);
    final r0 = rankOf(square);
    for (final d in deltas) {
      final f = f0 + d.$1;
      final r = r0 + d.$2;
      if (!isOnBoard(f, r)) continue;
      final to = squareIndex(f, r);
      final occupant = squares[to];
      if (occupant == null) {
        moves.add(ChessMove(from: square, to: to, movingPiece: piece));
      } else if (occupant.color != piece.color) {
        moves.add(
          ChessMove(
            from: square,
            to: to,
            movingPiece: piece,
            capturedPiece: occupant,
          ),
        );
      }
    }
    return moves;
  }

  List<ChessMove> _kingMoves(int square, ChessPiece piece) {
    final moves = _steppingMoves(square, piece, _kingDeltas);
    if (_canCastleKingside(piece.color)) {
      final rank = piece.color == PieceColor.white ? 0 : 7;
      moves.add(
        ChessMove(
          from: square,
          to: squareIndex(6, rank),
          movingPiece: piece,
          flag: ChessMoveFlag.castleKingside,
        ),
      );
    }
    if (_canCastleQueenside(piece.color)) {
      final rank = piece.color == PieceColor.white ? 0 : 7;
      moves.add(
        ChessMove(
          from: square,
          to: squareIndex(2, rank),
          movingPiece: piece,
          flag: ChessMoveFlag.castleQueenside,
        ),
      );
    }
    return moves;
  }

  bool _canCastleKingside(PieceColor color) {
    final right = color == PieceColor.white
        ? whiteKingsideRights
        : blackKingsideRights;
    if (!right) return false;
    final rank = color == PieceColor.white ? 0 : 7;
    final rookSq = squareIndex(7, rank);
    if (squares[rookSq]?.type != PieceType.rook ||
        squares[rookSq]?.color != color) {
      return false;
    }
    final kingSq = squareIndex(4, rank);
    final fSq = squareIndex(5, rank);
    final gSq = squareIndex(6, rank);
    if (squares[fSq] != null || squares[gSq] != null) return false;
    final opp = color.opposite;
    return !isSquareAttacked(kingSq, opp) &&
        !isSquareAttacked(fSq, opp) &&
        !isSquareAttacked(gSq, opp);
  }

  bool _canCastleQueenside(PieceColor color) {
    final right = color == PieceColor.white
        ? whiteQueensideRights
        : blackQueensideRights;
    if (!right) return false;
    final rank = color == PieceColor.white ? 0 : 7;
    final rookSq = squareIndex(0, rank);
    if (squares[rookSq]?.type != PieceType.rook ||
        squares[rookSq]?.color != color) {
      return false;
    }
    final kingSq = squareIndex(4, rank);
    final dSq = squareIndex(3, rank);
    final cSq = squareIndex(2, rank);
    final bSq = squareIndex(1, rank);
    if (squares[dSq] != null || squares[cSq] != null || squares[bSq] != null) {
      return false;
    }
    final opp = color.opposite;
    return !isSquareAttacked(kingSq, opp) &&
        !isSquareAttacked(dSq, opp) &&
        !isSquareAttacked(cSq, opp);
  }

  static const List<PieceType> _promotionTypes = [
    PieceType.queen,
    PieceType.rook,
    PieceType.bishop,
    PieceType.knight,
  ];

  List<ChessMove> _pawnMoves(int square, ChessPiece piece) {
    final moves = <ChessMove>[];
    final f0 = fileOf(square);
    final r0 = rankOf(square);
    final dir = piece.color == PieceColor.white ? 1 : -1;
    final startRank = piece.color == PieceColor.white ? 1 : 6;
    final promotionRank = piece.color == PieceColor.white ? 7 : 0;

    void addForward(int to) {
      if (rankOf(to) == promotionRank) {
        for (final t in _promotionTypes) {
          moves.add(
            ChessMove(
              from: square,
              to: to,
              movingPiece: piece,
              flag: ChessMoveFlag.promotion,
              promotionType: t,
            ),
          );
        }
      } else {
        moves.add(ChessMove(from: square, to: to, movingPiece: piece));
      }
    }

    void addCapture(int to, ChessPiece captured) {
      if (rankOf(to) == promotionRank) {
        for (final t in _promotionTypes) {
          moves.add(
            ChessMove(
              from: square,
              to: to,
              movingPiece: piece,
              capturedPiece: captured,
              flag: ChessMoveFlag.promotion,
              promotionType: t,
            ),
          );
        }
      } else {
        moves.add(
          ChessMove(
            from: square,
            to: to,
            movingPiece: piece,
            capturedPiece: captured,
          ),
        );
      }
    }

    final oneRank = r0 + dir;
    if (isOnBoard(f0, oneRank)) {
      final oneSq = squareIndex(f0, oneRank);
      if (squares[oneSq] == null) {
        addForward(oneSq);
        if (r0 == startRank) {
          final twoRank = r0 + dir * 2;
          final twoSq = squareIndex(f0, twoRank);
          if (squares[twoSq] == null) {
            moves.add(
              ChessMove(
                from: square,
                to: twoSq,
                movingPiece: piece,
                flag: ChessMoveFlag.doublePawnPush,
              ),
            );
          }
        }
      }
    }

    for (final df in [-1, 1]) {
      final cf = f0 + df;
      final cr = r0 + dir;
      if (!isOnBoard(cf, cr)) continue;
      final captureSq = squareIndex(cf, cr);
      final occupant = squares[captureSq];
      if (occupant != null && occupant.color != piece.color) {
        addCapture(captureSq, occupant);
      } else if (occupant == null && captureSq == enPassantTargetSquare) {
        final capturedPawnSq = squareIndex(cf, r0);
        moves.add(
          ChessMove(
            from: square,
            to: captureSq,
            movingPiece: piece,
            capturedPiece: squares[capturedPawnSq],
            flag: ChessMoveFlag.enPassantCapture,
          ),
        );
      }
    }
    return moves;
  }

  /// Verilen [move]'u uygulanmış YENİ bir [ChessBoard] döndürür; `this`
  /// değişmez. Bkz. sınıf yorumundaki "neden undoMove yok" açıklaması.
  ChessBoard applyMove(ChessMove move) {
    final newSquares = List<ChessPiece?>.of(squares);
    final piece = move.movingPiece;

    newSquares[move.from] = null;
    if (move.flag == ChessMoveFlag.enPassantCapture) {
      newSquares[squareIndex(fileOf(move.to), rankOf(move.from))] = null;
    }
    newSquares[move.to] = move.flag == ChessMoveFlag.promotion
        ? ChessPiece(move.promotionType!, piece.color)
        : piece;

    if (move.flag == ChessMoveFlag.castleKingside) {
      final rank = piece.color == PieceColor.white ? 0 : 7;
      newSquares[squareIndex(7, rank)] = null;
      newSquares[squareIndex(5, rank)] = ChessPiece(
        PieceType.rook,
        piece.color,
      );
    } else if (move.flag == ChessMoveFlag.castleQueenside) {
      final rank = piece.color == PieceColor.white ? 0 : 7;
      newSquares[squareIndex(0, rank)] = null;
      newSquares[squareIndex(3, rank)] = ChessPiece(
        PieceType.rook,
        piece.color,
      );
    }

    var newWhiteKingside = whiteKingsideRights;
    var newWhiteQueenside = whiteQueensideRights;
    var newBlackKingside = blackKingsideRights;
    var newBlackQueenside = blackQueensideRights;

    if (piece.type == PieceType.king) {
      if (piece.color == PieceColor.white) {
        newWhiteKingside = false;
        newWhiteQueenside = false;
      } else {
        newBlackKingside = false;
        newBlackQueenside = false;
      }
    }
    // Bir kale ya hareket ederek ya da hiç hareket etmemişken o köşede
    // yakalanarak rok hakkını düşürebilir — bu yüzden köşe kareleri hem
    // `from` hem `to` için kontrol ediliyor, sadece kale hareketlerinde
    // değil.
    if (move.from == squareIndex(0, 0) || move.to == squareIndex(0, 0)) {
      newWhiteQueenside = false;
    }
    if (move.from == squareIndex(7, 0) || move.to == squareIndex(7, 0)) {
      newWhiteKingside = false;
    }
    if (move.from == squareIndex(0, 7) || move.to == squareIndex(0, 7)) {
      newBlackQueenside = false;
    }
    if (move.from == squareIndex(7, 7) || move.to == squareIndex(7, 7)) {
      newBlackKingside = false;
    }

    final newEnPassant = move.flag == ChessMoveFlag.doublePawnPush
        ? squareIndex(
            fileOf(move.from),
            (rankOf(move.from) + rankOf(move.to)) ~/ 2,
          )
        : null;

    final newHalfMoveClock = (piece.type == PieceType.pawn || move.isCapture)
        ? 0
        : halfMoveClock + 1;

    final newSideToMove = sideToMove.opposite;

    final signature = _computeSignature(
      squares: newSquares,
      sideToMove: newSideToMove,
      whiteKingsideRights: newWhiteKingside,
      whiteQueensideRights: newWhiteQueenside,
      blackKingsideRights: newBlackKingside,
      blackQueensideRights: newBlackQueenside,
      enPassantTargetSquare: newEnPassant,
    );

    return ChessBoard._(
      squares: newSquares,
      sideToMove: newSideToMove,
      whiteKingsideRights: newWhiteKingside,
      whiteQueensideRights: newWhiteQueenside,
      blackKingsideRights: newBlackKingside,
      blackQueensideRights: newBlackQueenside,
      enPassantTargetSquare: newEnPassant,
      halfMoveClock: newHalfMoveClock,
      moveHistory: [...moveHistory, move],
      positionSignatures: [...positionSignatures, signature],
    );
  }

  static String _computeSignature({
    required List<ChessPiece?> squares,
    required PieceColor sideToMove,
    required bool whiteKingsideRights,
    required bool whiteQueensideRights,
    required bool blackKingsideRights,
    required bool blackQueensideRights,
    required int? enPassantTargetSquare,
  }) {
    final buffer = StringBuffer();
    for (final piece in squares) {
      if (piece == null) {
        buffer.write('.');
        continue;
      }
      final ch = switch (piece.type) {
        PieceType.pawn => 'p',
        PieceType.knight => 'n',
        PieceType.bishop => 'b',
        PieceType.rook => 'r',
        PieceType.queen => 'q',
        PieceType.king => 'k',
      };
      buffer.write(piece.color == PieceColor.white ? ch.toUpperCase() : ch);
    }
    buffer.write(
      '|${sideToMove.name}|$whiteKingsideRights$whiteQueensideRights'
      '$blackKingsideRights$blackQueensideRights|'
      '${enPassantTargetSquare ?? -1}',
    );
    return buffer.toString();
  }
}
