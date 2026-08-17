import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/game_result_repository.dart';
import '../models/game_phase.dart';
import '../models/game_result.dart';
import '../models/player_state.dart';
import '../services/sound_service.dart';

enum CellSelectionResult { bomb, safeContinue, playerFinished }

class GameController extends ChangeNotifier {
  GameController({
    required GameResultRepository resultRepository,
    required SoundService soundService,
  }) : _resultRepository = resultRepository,
       _soundService = soundService;

  final GameResultRepository _resultRepository;
  final SoundService _soundService;

  GamePhase phase = GamePhase.setup;
  List<PlayerState> players = [];
  int currentPlayerIndex = 0;

  PlayerState get currentPlayer => players[currentPlayerIndex];

  List<PlayerState> get rankedByAttempts {
    final sorted = List<PlayerState>.from(players);
    sorted.sort((a, b) => a.attempts.compareTo(b.attempts));
    return sorted;
  }

  void startGame(List<String> names) {
    final rng = Random();
    players = names
        .map(
          (name) => PlayerState(
            name: name,
            bombLayout: PlayerState.generateBombLayout(rng),
          ),
        )
        .toList();
    currentPlayerIndex = 0;
    phase = GamePhase.playing;
    notifyListeners();
  }

  CellSelectionResult selectCell(int col) {
    final player = currentPlayer;
    if (player.isBomb(player.currentRow, col)) {
      player.registerBombHit();
      _soundService.playBomb();
      notifyListeners();
      return CellSelectionResult.bomb;
    }

    final justFinished = player.registerSafeCell(col);
    if (!justFinished) {
      notifyListeners();
      return CellSelectionResult.safeContinue;
    }

    final nextIndex = _findNextUnfinishedPlayerIndex();
    if (nextIndex == null) {
      phase = GamePhase.finished;
      _soundService.playWin();
      _persistResults();
    } else {
      currentPlayerIndex = nextIndex;
      phase = GamePhase.turnTransition;
    }
    notifyListeners();
    return CellSelectionResult.playerFinished;
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (currentPlayerIndex + offset) % players.length;
      if (!players[index].finished) return index;
    }
    return null;
  }

  void _persistResults() {
    final now = DateTime.now();
    for (final player in players) {
      unawaited(
        _resultRepository.saveResult(
          GameResult(
            playerName: player.name,
            attempts: player.attempts,
            finishedAt: now,
          ),
        ),
      );
    }
  }

  void acknowledgeTurnTransition() {
    phase = GamePhase.playing;
    notifyListeners();
  }

  void restart() {
    players = [];
    currentPlayerIndex = 0;
    phase = GamePhase.setup;
    notifyListeners();
  }
}
