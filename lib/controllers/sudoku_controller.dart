import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/sudoku_board.dart';
import '../models/sudoku_difficulty.dart';
import '../models/sudoku_game_phase.dart';
import '../models/sudoku_player_state.dart';

/// Bir oyuncunun turunu bitiren yanlış giriş sayısı — kendi adıyla,
/// `test/widget_test.dart` her controller'ı tek dosyada import ettiğinden
/// diğer oyunların round-count sabitleriyle aynı "ambiguous import" riskini
/// taşımaması için (bkz. Diziler/Tepki Süresi/Simon'ın kendi sabitleri).
const int sudokuMaxMistakes = 3;

class SudokuController extends ChangeNotifier {
  SudokuController({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  SudokuGamePhase phase = SudokuGamePhase.setup;
  List<SudokuPlayerState> players = [];
  int currentPlayerIndex = 0;
  SudokuDifficulty difficulty = SudokuDifficulty.orta;
  int? selectedIndex;

  SudokuPlayerState get currentPlayer => players[currentPlayerIndex];

  List<SudokuPlayerState> get rankedByMistakes {
    final sorted = List<SudokuPlayerState>.from(players);
    sorted.sort((a, b) => a.mistakeCount.compareTo(b.mistakeCount));
    return sorted;
  }

  void startGame(List<String> names, {required SudokuDifficulty difficulty}) {
    this.difficulty = difficulty;
    players = [for (final name in names) _newPlayer(name, difficulty)];
    currentPlayerIndex = 0;
    selectedIndex = null;
    phase = SudokuGamePhase.playing;
    notifyListeners();
  }

  SudokuPlayerState _newPlayer(String name, SudokuDifficulty difficulty) {
    final puzzle = generateSudokuPuzzle(difficulty, _rng);
    return SudokuPlayerState(
      name: name,
      solution: puzzle.solution,
      given: puzzle.given,
    );
  }

  /// [index]'teki hücreyi seçer; hücre ipucu (given) ise no-op.
  void selectCell(int index) {
    if (phase != SudokuGamePhase.playing) return;
    if (currentPlayer.given[index]) return;
    selectedIndex = index;
    notifyListeners();
  }

  /// Seçili hücreye [digit] (1-9) yazar. Seçili hücre yoksa ya da ipucuysa
  /// no-op. Yanlış rakam [sudokuMaxMistakes] kez girilirse ya da tahta
  /// tamamen doğru doldurulursa oyuncunun turu biter ve sıra devredilir.
  void enterDigit(int digit) {
    if (phase != SudokuGamePhase.playing) return;
    final index = selectedIndex;
    if (index == null) return;
    final player = currentPlayer;
    if (player.given[index]) return;

    player.values[index] = digit;
    if (digit != player.solution[index]) {
      player.mistakeCount++;
    }

    final solved = player.isSolved;
    final outOfChances = player.mistakeCount >= sudokuMaxMistakes;
    if (!solved && !outOfChances) {
      notifyListeners();
      return;
    }

    player.finished = true;
    selectedIndex = null;
    final nextIndex = _findNextUnfinishedPlayerIndex();
    if (nextIndex == null) {
      phase = SudokuGamePhase.finished;
    } else {
      currentPlayerIndex = nextIndex;
      phase = SudokuGamePhase.turnTransition;
    }
    notifyListeners();
  }

  /// Seçili, ipucu olmayan hücreyi boşaltır. Hata sayısına dokunmaz.
  void clearSelectedCell() {
    if (phase != SudokuGamePhase.playing) return;
    final index = selectedIndex;
    if (index == null) return;
    final player = currentPlayer;
    if (player.given[index]) return;
    player.values[index] = 0;
    notifyListeners();
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (currentPlayerIndex + offset) % players.length;
      if (!players[index].finished) return index;
    }
    return null;
  }

  void acknowledgeTurnTransition() {
    selectedIndex = null;
    phase = SudokuGamePhase.playing;
    notifyListeners();
  }

  void restart() {
    players = [];
    currentPlayerIndex = 0;
    selectedIndex = null;
    phase = SudokuGamePhase.setup;
    notifyListeners();
  }
}
