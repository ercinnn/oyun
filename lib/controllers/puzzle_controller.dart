import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/puzzle_game_phase.dart';
import '../models/puzzle_player_state.dart';

class PuzzleController extends ChangeNotifier {
  PuzzleGamePhase phase = PuzzleGamePhase.setup;
  List<PuzzlePlayerState> players = [];
  int currentPlayerIndex = 0;

  PuzzlePlayerState get currentPlayer => players[currentPlayerIndex];

  List<PuzzlePlayerState> get rankedByMoves {
    final sorted = List<PuzzlePlayerState>.from(players);
    sorted.sort((a, b) => a.moveCount.compareTo(b.moveCount));
    return sorted;
  }

  void startGame(List<String> names) {
    final rng = Random();
    players = names
        .map(
          (name) => PuzzlePlayerState(
            name: name,
            tiles: PuzzlePlayerState.generateShuffledTiles(rng),
          ),
        )
        .toList();
    currentPlayerIndex = 0;
    phase = PuzzleGamePhase.playing;
    notifyListeners();
  }

  /// [index]'teki kutuyu boş kareye kaydırmayı dener; [index] boş kareye
  /// komşu değilse hiçbir şey değişmez (no-op).
  void moveTile(int index) {
    if (phase != PuzzleGamePhase.playing) return;
    final player = currentPlayer;
    final emptyIndex = player.tiles.indexOf(0);
    if (!adjacentIndices(emptyIndex).contains(index)) return;

    player.tiles[emptyIndex] = player.tiles[index];
    player.tiles[index] = 0;
    player.moveCount++;

    if (!isPuzzleSolved(player.tiles)) {
      notifyListeners();
      return;
    }

    player.finished = true;
    final nextIndex = _findNextUnfinishedPlayerIndex();
    if (nextIndex == null) {
      phase = PuzzleGamePhase.finished;
    } else {
      currentPlayerIndex = nextIndex;
      phase = PuzzleGamePhase.turnTransition;
    }
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
    phase = PuzzleGamePhase.playing;
    notifyListeners();
  }

  void restart() {
    players = [];
    currentPlayerIndex = 0;
    phase = PuzzleGamePhase.setup;
    notifyListeners();
  }
}
