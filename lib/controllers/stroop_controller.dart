import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/stroop_color.dart';
import '../models/stroop_game_phase.dart';
import '../models/stroop_player_state.dart';
import '../models/stroop_trial.dart';

/// Her oyuncunun oynadığı tur sayısı.
const int roundsPerPlayer = 10;

class StroopController extends ChangeNotifier {
  StroopGamePhase phase = StroopGamePhase.setup;
  List<StroopPlayerState> players = [];
  int currentPlayerIndex = 0;
  late StroopTrial currentTrial;

  /// Son cevabın doğru/yanlış olduğunu kısa bir geri bildirim penceresi
  /// boyunca tutar; hiçbir geri bildirim gösterilmeyecekse null'dır.
  bool? lastAnswerCorrect;

  bool _resolving = false;
  // startGame/restart her çağrıldığında artar; bekleyen bir geri bildirim
  // gecikmesi tamamlandığında hâlâ aynı oyunda olduğumuzu doğrulamak için
  // kullanılır (aksi halde yeniden başlatılmış bir oyunun state'ini bozabilir).
  int _generation = 0;
  final Random _rng = Random();

  StroopPlayerState get currentPlayer => players[currentPlayerIndex];

  List<StroopPlayerState> get rankedByCorrect {
    final sorted = List<StroopPlayerState>.from(players);
    sorted.sort((a, b) => b.correctCount.compareTo(a.correctCount));
    return sorted;
  }

  StroopTrial _generateTrial() {
    final colors = StroopColor.values;
    return StroopTrial(
      word: colors[_rng.nextInt(colors.length)],
      ink: colors[_rng.nextInt(colors.length)],
      options: colors.toList()..shuffle(_rng),
    );
  }

  void startGame(List<String> names) {
    _generation++;
    players = names.map((name) => StroopPlayerState(name: name)).toList();
    currentPlayerIndex = 0;
    currentTrial = _generateTrial();
    lastAnswerCorrect = null;
    _resolving = false;
    phase = StroopGamePhase.playing;
    notifyListeners();
  }

  Future<void> answer(StroopColor selected) async {
    if (phase != StroopGamePhase.playing) return;
    if (_resolving) return;
    _resolving = true;
    final generation = _generation;

    final correct = selected == currentTrial.ink;
    lastAnswerCorrect = correct;
    if (correct) currentPlayer.correctCount++;
    currentPlayer.roundsPlayed++;
    notifyListeners();

    // Oyuncunun doğru/yanlış geri bildirimini görebilmesi için kısa bir
    // duraklama, ardından bir sonraki tura geçilir.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (generation != _generation) return;

    lastAnswerCorrect = null;

    if (currentPlayer.roundsPlayed >= roundsPerPlayer) {
      final nextIndex = _findNextUnfinishedPlayerIndex();
      if (nextIndex == null) {
        phase = StroopGamePhase.finished;
      } else {
        currentPlayerIndex = nextIndex;
        currentTrial = _generateTrial();
        phase = StroopGamePhase.turnTransition;
      }
    } else {
      currentTrial = _generateTrial();
    }
    _resolving = false;
    notifyListeners();
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (currentPlayerIndex + offset) % players.length;
      if (players[index].roundsPlayed < roundsPerPlayer) return index;
    }
    return null;
  }

  void acknowledgeTurnTransition() {
    phase = StroopGamePhase.playing;
    notifyListeners();
  }

  void restart() {
    _generation++;
    players = [];
    currentPlayerIndex = 0;
    lastAnswerCorrect = null;
    _resolving = false;
    phase = StroopGamePhase.setup;
    notifyListeners();
  }
}
