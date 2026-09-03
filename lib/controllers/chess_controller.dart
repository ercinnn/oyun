import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chess_board.dart';
import '../models/chess_game_phase.dart';
import '../models/chess_mode.dart';
import '../models/chess_move.dart';
import '../models/chess_outcome.dart';
import '../models/chess_piece.dart';
import '../services/chess_ai.dart';

class ChessController extends ChangeNotifier {
  ChessGamePhase phase = ChessGamePhase.setup;
  ChessBoard board = ChessBoard.initial();
  ChessMode mode = ChessMode.vsAi;

  /// Sadece [mode] `vsAi` iken dolu — insan oyuncunun oynadığı renk.
  PieceColor? humanColor;
  String whiteName = '';
  String blackName = '';

  int? selectedSquare;
  List<ChessMove> selectedSquareLegalMoves = [];

  /// Aynı `from`/`to` çiftini paylaşan 4 terfi hamlesi adayı (Vezir/Kale/
  /// Fil/At) — dolu olduğunda UI bir seçim penceresi göstermeli.
  List<ChessMove> pendingPromotionMoves = [];

  bool aiThinking = false;
  ChessOutcome? outcome;
  ChessOutcomeReason? outcomeReason;

  int _generation = 0;
  final ChessAI _ai = ChessAI();

  PieceColor get currentColor => board.sideToMove;
  bool get isCheck => board.isInCheck;

  /// 2 kişilik modda sırası gelen tarafa göre değişir (her hamlede
  /// dönüşü tetikler); bilgisayara karşı modda insan oyuncunun rengine
  /// sabitlenir (tek insan oyuncu var, tahtanın dönmesi anlamsız).
  PieceColor get viewpointColor =>
      mode == ChessMode.twoPlayer ? board.sideToMove : humanColor!;
  bool get boardFlipped => viewpointColor == PieceColor.black;

  bool get _isHumanTurn =>
      mode == ChessMode.twoPlayer || board.sideToMove == humanColor;

  void startGame({
    required ChessMode mode,
    required String whiteName,
    required String blackName,
    PieceColor humanColor = PieceColor.white,
  }) {
    _generation++;
    board = ChessBoard.initial();
    this.mode = mode;
    this.whiteName = whiteName;
    this.blackName = blackName;
    this.humanColor = mode == ChessMode.vsAi ? humanColor : null;
    selectedSquare = null;
    selectedSquareLegalMoves = [];
    pendingPromotionMoves = [];
    outcome = null;
    outcomeReason = null;
    aiThinking = false;
    phase = ChessGamePhase.playing;
    notifyListeners();

    if (mode == ChessMode.vsAi && humanColor == PieceColor.black) {
      unawaited(_makeAiMove());
    }
  }

  /// İki dokunuşlu seç/oyna modeli: ilk dokunuş kendi taşını seçer, ikinci
  /// dokunuş geçerli bir hedefse hamleyi uygular. Platformun her hücrenin
  /// tek argümanlı `onTap`'ine sahip olduğu deseniyle tutarlı (`moveTile`,
  /// `flipCard`, `tapTile`).
  void selectSquare(int square) {
    if (phase != ChessGamePhase.playing || aiThinking) return;
    if (!_isHumanTurn) return;
    final piece = board.squares[square];

    if (selectedSquare == null) {
      if (piece != null && piece.color == board.sideToMove) {
        selectedSquare = square;
        selectedSquareLegalMoves = board.legalMovesFrom(square);
        notifyListeners();
      }
      return;
    }

    if (square == selectedSquare) {
      selectedSquare = null;
      selectedSquareLegalMoves = [];
      notifyListeners();
      return;
    }

    final matches = selectedSquareLegalMoves
        .where((m) => m.to == square)
        .toList();
    if (matches.isEmpty) {
      if (piece != null && piece.color == board.sideToMove) {
        selectedSquare = square;
        selectedSquareLegalMoves = board.legalMovesFrom(square);
        notifyListeners();
      }
      return;
    }

    if (matches.length > 1) {
      pendingPromotionMoves = matches;
      notifyListeners();
      return;
    }

    _commitMove(matches.single);
  }

  void resolvePromotion(PieceType type) {
    final move = pendingPromotionMoves.firstWhere(
      (m) => m.promotionType == type,
    );
    pendingPromotionMoves = [];
    _commitMove(move);
  }

  void _commitMove(ChessMove move) {
    board = board.applyMove(move);
    selectedSquare = null;
    selectedSquareLegalMoves = [];
    _checkGameEnd();
    notifyListeners();

    if (phase == ChessGamePhase.playing &&
        mode == ChessMode.vsAi &&
        board.sideToMove != humanColor) {
      unawaited(_makeAiMove());
    }
  }

  Future<void> _makeAiMove() async {
    final generation = _generation;
    aiThinking = true;
    notifyListeners();

    // Senkron (bloklayan) arama çalışmadan önce "Bilgisayar düşünüyor..."
    // durumunun bir kare boyanabilmesi için kısa bir gecikme.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (generation != _generation) return;

    final move = _ai.findBestMove(board);
    if (generation != _generation) return;

    aiThinking = false;
    if (move == null) {
      notifyListeners();
      return;
    }
    board = board.applyMove(move);
    _checkGameEnd();
    notifyListeners();
  }

  void _checkGameEnd() {
    if (board.isCheckmate) {
      outcome = board.sideToMove == PieceColor.white
          ? ChessOutcome.blackWins
          : ChessOutcome.whiteWins;
      outcomeReason = ChessOutcomeReason.checkmate;
    } else if (board.isStalemate) {
      outcome = ChessOutcome.draw;
      outcomeReason = ChessOutcomeReason.stalemate;
    } else if (board.isDrawByFiftyMoveRule) {
      outcome = ChessOutcome.draw;
      outcomeReason = ChessOutcomeReason.fiftyMoveRule;
    } else if (board.isDrawByRepetition) {
      outcome = ChessOutcome.draw;
      outcomeReason = ChessOutcomeReason.repetition;
    } else if (board.isDrawByInsufficientMaterial) {
      outcome = ChessOutcome.draw;
      outcomeReason = ChessOutcomeReason.insufficientMaterial;
    } else {
      return;
    }
    phase = ChessGamePhase.finished;
  }

  void restart() {
    _generation++;
    phase = ChessGamePhase.setup;
    selectedSquare = null;
    selectedSquareLegalMoves = [];
    pendingPromotionMoves = [];
    aiThinking = false;
    outcome = null;
    outcomeReason = null;
    notifyListeners();
  }
}
