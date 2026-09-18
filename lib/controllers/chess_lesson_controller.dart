import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chess_board.dart';
import '../models/chess_lesson.dart';
import '../models/chess_move.dart';
import '../models/chess_piece.dart';
import '../models/chess_square.dart';

/// Ders listesi ilerlemesi (tamamlanan ders kimlikleri): `shared_preferences`
/// ile cihaz-yerel saklanır, `ProfileController` ile aynı desen. Okuma/yazma
/// hataları oyunu bozmaz (boş küme ile devam edilir).
class ChessLessonProgress extends ChangeNotifier {
  static const _key = 'chess_completed_lessons';

  final Set<String> completed = {};

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      completed
        ..clear()
        ..addAll(prefs.getStringList(_key) ?? const []);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markCompleted(String lessonId) async {
    if (!completed.add(lessonId)) return;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, completed.toList());
    } catch (_) {}
  }
}

/// Tek bir dersin oynatıcısı: adım indeksi, tahta, seçim ve geri bildirim.
/// Tamamen senkron — `Future.delayed` yok, dolayısıyla `_generation` koruması
/// gerekmez (PuzzleController ile aynı durum).
class ChessLessonController extends ChangeNotifier {
  ChessLessonController(this.lesson) {
    _enterStep();
  }

  final ChessLesson lesson;

  int stepIndex = 0;
  late ChessBoard board;
  int? selectedSquare;
  List<ChessMove> selectedLegalMoves = const [];
  Set<int> markedSquares = {};
  Set<int> hintSquares = {};
  ChessMove? lastMove;

  /// Adım çözüldü mü ("Devam" bunu bekler; anlatım adımları baştan çözülü).
  bool solved = false;

  /// Son geri bildirim metni ve olumlu mu olumsuz mu olduğu.
  String? feedback;
  bool feedbackPositive = false;

  /// Quiz'de son seçilen yanlış seçenek (vurgulamak için).
  int? wrongOption;

  ChessLessonStep get step => lesson.steps[stepIndex];
  bool get isLastStep => stepIndex == lesson.steps.length - 1;
  bool get finished => solved && isLastStep;

  /// Adımın tahta pozisyonu (quiz/anlatımda `fen` olmayabilir).
  String? get _stepFen => switch (step) {
    LessonInfoStep s => s.fen,
    LessonMoveStep s => s.fen,
    LessonMarkStep s => s.fen,
    LessonQuizStep s => s.fen,
  };

  bool get hasBoard => _stepFen != null;

  /// Sıra siyahtaysa tahta siyah altta olacak şekilde çizilir.
  bool get flipped => (_stepFen ?? '').contains(' b ');

  void _enterStep() {
    final fen = _stepFen;
    board = ChessBoard.fromFen(fen ?? '8/8/8/8/8/8/8/8 w - - 0 1');
    selectedSquare = null;
    selectedLegalMoves = const [];
    markedSquares = {};
    lastMove = null;
    feedback = null;
    feedbackPositive = false;
    wrongOption = null;
    final s = step;
    solved = s is LessonInfoStep;
    hintSquares = switch (s) {
      LessonInfoStep s => {for (final h in s.highlights) squareFromName(h)},
      LessonMoveStep s => {for (final h in s.highlights) squareFromName(h)},
      _ => {},
    };
  }

  void next() {
    if (!solved || isLastStep) return;
    stepIndex++;
    _enterStep();
    notifyListeners();
  }

  void _resetPosition() {
    board = ChessBoard.fromFen((step as LessonMoveStep).fen);
    selectedSquare = null;
    selectedLegalMoves = const [];
    lastMove = null;
  }

  /// Tahta dokunuşu: adım türüne göre hamle seçimi ya da kare işaretleme.
  void tapSquare(int square) {
    final s = step;
    if (solved) return;
    if (s is LessonMoveStep) {
      _tapForMove(s, square);
    } else if (s is LessonMarkStep) {
      _tapForMark(s, square);
    }
  }

  void _tapForMove(LessonMoveStep s, int square) {
    if (selectedSquare != null) {
      final matches = selectedLegalMoves.where((m) => m.to == square).toList();
      if (matches.isNotEmpty) {
        // Terfi: aynı from/to için 4 hamle üretilir; derslerde vezir seçilir.
        final move = matches.firstWhere(
          (m) => m.promotionType == null || m.promotionType == PieceType.queen,
          orElse: () => matches.first,
        );
        _playMove(s, move);
        return;
      }
    }
    final piece = board.squares[square];
    if (piece != null && piece.color == board.sideToMove) {
      selectedSquare = square;
      selectedLegalMoves = board.legalMovesFrom(square);
    } else {
      selectedSquare = null;
      selectedLegalMoves = const [];
    }
    notifyListeners();
  }

  bool _isAccepted(LessonMoveStep s, ChessMove move) {
    final key = '${algebraic(move.from)}${algebraic(move.to)}';
    if (s.accepted.contains(key)) return true;
    return s.anyMate && board.applyMove(move).isCheckmate;
  }

  void _playMove(LessonMoveStep s, ChessMove move) {
    if (_isAccepted(s, move)) {
      board = board.applyMove(move);
      lastMove = move;
      selectedSquare = null;
      selectedLegalMoves = const [];
      solved = true;
      feedback = s.success;
      feedbackPositive = true;
    } else {
      _resetPosition();
      feedback = s.wrong;
      feedbackPositive = false;
    }
    notifyListeners();
  }

  /// İpucu: hamlenin kalkış karesini vurgular.
  void showHint() {
    final s = step;
    if (s is! LessonMoveStep || solved) return;
    final froms = s.accepted.isNotEmpty
        ? s.accepted.map((m) => squareFromName(m.substring(0, 2)))
        : [
            for (final m in board.legalMoves(board.sideToMove))
              if (board.applyMove(m).isCheckmate) m.from,
          ];
    hintSquares = {...froms};
    notifyListeners();
  }

  Set<int> _markTargets(LessonMarkStep s) => {
    for (final m in board.legalMovesFrom(squareFromName(s.pieceSquare))) m.to,
  };

  void _tapForMark(LessonMarkStep s, int square) {
    if (square == squareFromName(s.pieceSquare)) return;
    if (!markedSquares.remove(square)) markedSquares.add(square);
    feedback = null;
    notifyListeners();
  }

  /// "Kontrol et" düğmesi (işaretleme adımı).
  void checkMarks() {
    final s = step;
    if (s is! LessonMarkStep || solved) return;
    final targets = _markTargets(s);
    if (setEquals(markedSquares, targets)) {
      solved = true;
      feedback = s.success;
      feedbackPositive = true;
    } else {
      final missing = targets.difference(markedSquares).length;
      final extra = markedSquares.difference(targets).length;
      feedbackPositive = false;
      feedback = [
        if (extra > 0) 'Yanlış işaretlediğin $extra kare var.',
        if (missing > 0) 'Eksik kaldığın $missing kare var.',
        'Tekrar dene.',
      ].join(' ');
    }
    notifyListeners();
  }

  void answerQuiz(int index) {
    final s = step;
    if (s is! LessonQuizStep || solved) return;
    if (index == s.correctIndex) {
      solved = true;
      wrongOption = null;
      feedback = s.explanation;
      feedbackPositive = true;
    } else {
      wrongOption = index;
      feedback = 'Olmadı, tekrar dene.';
      feedbackPositive = false;
    }
    notifyListeners();
  }
}
