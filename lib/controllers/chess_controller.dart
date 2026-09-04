import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/chess_board.dart';
import '../models/chess_difficulty.dart';
import '../models/chess_game_phase.dart';
import '../models/chess_mode.dart';
import '../models/chess_move.dart';
import '../models/chess_notation.dart';
import '../models/chess_outcome.dart';
import '../models/chess_piece.dart';
import '../models/chess_time_control.dart';
import '../services/chess_ai.dart';

/// Saatin ne sıklıkla işlediği. Kalan süre bilerek `Stopwatch`/`DateTime`
/// farkıyla değil, her tıkta bu kadar **düşülerek** hesaplanıyor: widget
/// testlerinde `tester.pump(...)` yalnızca `Timer`'ları sanal zamanda
/// ilerletir, `Stopwatch`/`DateTime.now()` gerçek zamanda kalır (bkz.
/// CLAUDE.md'de Tepki Süresi'nin test edilebilirlik notu) — yani süre
/// bitiminin testi ancak tık-tabanlı sayaçla yazılabilir. Bunun bedeli,
/// tarayıcı sekmesi arka plandayken zamanlayıcı kısıldığında saatin yavaş
/// işlemesi; bu platform için kabul edilebilir bir sapma.
const Duration chessClockTick = Duration(seconds: 1);

class ChessController extends ChangeNotifier {
  ChessGamePhase phase = ChessGamePhase.setup;
  ChessBoard board = ChessBoard.initial();
  ChessMode mode = ChessMode.vsAi;

  /// Yalnızca [mode] `vsAi` iken anlamlı.
  ChessDifficulty difficulty = chessDefaultDifficulty;

  ChessTimeControl timeControl = ChessTimeControl.unlimited;
  Duration whiteRemaining = Duration.zero;
  Duration blackRemaining = Duration.zero;

  /// Beyaz açısından santipiyon cinsinden son değerlendirme; her hamleden
  /// sonra güncellenir. Değerlendirme çubuğu bunu okur.
  int evaluationCentipawns = 0;

  /// Oynanan hamlelerin cebirsel gösterimleri ("e4", "Axd5", "0-0"),
  /// oynandıkları sırada. `board.moveHistory` ham hamleleri tutar; gösterim
  /// ise hamle anındaki tahtayı gerektirdiği için (belirsizlik eki, şah/mat)
  /// burada, hamle oynanırken üretiliyor.
  List<String> moveNotations = [];

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
  Timer? _clockTimer;

  PieceColor get currentColor => board.sideToMove;
  bool get isCheck => board.isInCheck;

  bool get hasClock => timeControl.initialTime != null;

  /// Beyazın kazanma şansı (0.0-1.0). Satrançta standart olan lojistik
  /// dönüşüm: 400 santipiyonluk fark ≈ 10 kat kazanma oranı. Oyun bittiyse
  /// gerçek sonuç kullanılır — değerlendirme çubuğu mat olan tarafı yarı
  /// dolu göstermesin diye.
  double get whiteWinChance {
    switch (outcome) {
      case ChessOutcome.whiteWins:
        return 1.0;
      case ChessOutcome.blackWins:
        return 0.0;
      case ChessOutcome.draw:
        return 0.5;
      case null:
        break;
    }
    // Uçlarda çubuk tamamen dolup bilgi taşımaz hâle gelmesin diye
    // değerlendirme sınırlanıyor (±15 piyon fazlası zaten "kazanılmış").
    final cp = evaluationCentipawns.clamp(-1500, 1500);
    return 1 / (1 + pow(10, -cp / 400));
  }

  /// 2 kişilik modda sırası gelen tarafa göre değişir (her hamlede
  /// dönüşü tetikler); bilgisayara karşı modda insan oyuncunun rengine
  /// sabitlenir (tek insan oyuncu var, tahtanın dönmesi anlamsız).
  PieceColor get viewpointColor =>
      mode == ChessMode.twoPlayer ? board.sideToMove : humanColor!;
  bool get boardFlipped => viewpointColor == PieceColor.black;

  bool get _isHumanTurn =>
      mode == ChessMode.twoPlayer || board.sideToMove == humanColor;

  /// [timeControl] varsayılanı bilerek [ChessTimeControl.unlimited]: süreli
  /// bir oyun periyodik bir `Timer` kurar, bu da `pumpAndSettle()` kullanan
  /// mevcut widget testlerini asla "settle" edemez hâle getirirdi. Kurulum
  /// ekranı da aynı varsayılanı gösterir (bkz. `ChessSetupScreen`).
  void startGame({
    required ChessMode mode,
    required String whiteName,
    required String blackName,
    PieceColor humanColor = PieceColor.white,
    ChessDifficulty difficulty = chessDefaultDifficulty,
    ChessTimeControl timeControl = ChessTimeControl.unlimited,
  }) {
    _generation++;
    board = ChessBoard.initial();
    this.mode = mode;
    this.whiteName = whiteName;
    this.blackName = blackName;
    this.humanColor = mode == ChessMode.vsAi ? humanColor : null;
    this.difficulty = difficulty;
    this.timeControl = timeControl;
    final initialTime = timeControl.initialTime ?? Duration.zero;
    whiteRemaining = initialTime;
    blackRemaining = initialTime;
    evaluationCentipawns = 0;
    moveNotations = [];
    selectedSquare = null;
    selectedSquareLegalMoves = [];
    pendingPromotionMoves = [];
    outcome = null;
    outcomeReason = null;
    aiThinking = false;
    phase = ChessGamePhase.playing;
    _startClock();
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

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
    if (!hasClock) return;
    _clockTimer = Timer.periodic(chessClockTick, (_) => _onClockTick());
  }

  void _onClockTick() {
    if (phase != ChessGamePhase.playing) return;
    final whiteToMove = board.sideToMove == PieceColor.white;
    final remaining =
        (whiteToMove ? whiteRemaining : blackRemaining) - chessClockTick;
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    if (whiteToMove) {
      whiteRemaining = clamped;
    } else {
      blackRemaining = clamped;
    }
    if (clamped == Duration.zero) {
      // Süresi biten taraf kaybeder. Kalan taşlarla mat edilemeyecek olması
      // (gerçek turnuva kuralındaki beraberlik istisnası) bilerek göz ardı
      // edildi — bu platformda gereksiz bir karmaşıklık.
      outcome = whiteToMove ? ChessOutcome.blackWins : ChessOutcome.whiteWins;
      outcomeReason = ChessOutcomeReason.timeout;
      phase = ChessGamePhase.finished;
      _stopClock();
    }
    notifyListeners();
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void _updateEvaluation() {
    evaluationCentipawns = _ai.evaluateForWhite(board);
  }

  void _commitMove(ChessMove move) {
    _applyAndRecord(move);
    selectedSquare = null;
    selectedSquareLegalMoves = [];
    _updateEvaluation();
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

    final move = _ai.findBestMove(board, difficulty: difficulty);
    if (generation != _generation) return;

    aiThinking = false;
    if (move == null) {
      notifyListeners();
      return;
    }
    _applyAndRecord(move);
    _updateEvaluation();
    _checkGameEnd();
    notifyListeners();
  }

  /// Hamleyi uygular ve gösterimini kaydeder. Gösterim, hamleden önceki ve
  /// sonraki tahtanın ikisini de gerektirdiği için hamlenin uygulandığı tek
  /// nokta burası.
  void _applyAndRecord(ChessMove move) {
    final before = board;
    board = board.applyMove(move);
    moveNotations = [
      ...moveNotations,
      chessMoveNotation(before: before, move: move, after: board),
    ];
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
    _stopClock();
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
    _stopClock();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopClock();
    super.dispose();
  }
}
