import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/simon_attribute_type.dart';
import '../models/simon_game_phase.dart';
import '../models/simon_player_state.dart';
import '../models/simon_tile_id.dart';
import '../models/simon_trial.dart';

/// Her oyuncunun oynadığı tur sayısı. Diğer oyunların round-sayaç
/// sabitleriyle (`roundsPerPlayer`, `patternRoundsPerPlayer`,
/// `reflexRoundsPerPlayer`, `maxSequenceLength`) çakışmasın diye ayrı
/// adlandırıldı — hepsi test/widget_test.dart içinde birlikte import
/// ediliyor.
const int simonRoundsPerPlayer = 10;

/// Bir turun "Simon dedi ki" ile başlama ihtimali.
const double _obeyProbability = 0.7;

class SimonController extends ChangeNotifier {
  SimonGamePhase phase = SimonGamePhase.setup;
  List<SimonPlayerState> players = [];
  int currentPlayerIndex = 0;
  late SimonTrial currentTrial;

  /// Son cevabın doğru/yanlış olduğunu kısa bir geri bildirim penceresi
  /// boyunca tutar; hiçbir geri bildirim gösterilmeyecekse null'dır.
  bool? lastAnswerCorrect;

  bool _resolving = false;
  // startGame/restart her çağrıldığında artar; bekleyen bir geri bildirim
  // gecikmesi tamamlandığında hâlâ aynı oyunda olduğumuzu doğrulamak için
  // kullanılır (aksi halde yeniden başlatılmış bir oyunun state'ini bozabilir).
  int _generation = 0;
  final Random _rng = Random();

  SimonPlayerState get currentPlayer => players[currentPlayerIndex];

  List<SimonPlayerState> get rankedByCorrect {
    final sorted = List<SimonPlayerState>.from(players);
    sorted.sort((a, b) => b.correctCount.compareTo(a.correctCount));
    return sorted;
  }

  SimonTrial _generateTrial() {
    final obey = _rng.nextDouble() < _obeyProbability;
    final attributeType = _rng.nextBool()
        ? SimonAttributeType.color
        : SimonAttributeType.shape;
    final target =
        SimonTileId.values[_rng.nextInt(SimonTileId.values.length)];
    final boardOrder = SimonTileId.values.toList()..shuffle(_rng);
    return SimonTrial(
      obey: obey,
      attributeType: attributeType,
      target: target,
      boardOrder: boardOrder,
    );
  }

  void startGame(List<String> names) {
    _generation++;
    players = names.map((name) => SimonPlayerState(name: name)).toList();
    currentPlayerIndex = 0;
    currentTrial = _generateTrial();
    lastAnswerCorrect = null;
    _resolving = false;
    phase = SimonGamePhase.playing;
    notifyListeners();
  }

  /// [tapped] `null` ise "Pas Geç" butonuna basıldığını ifade eder.
  Future<void> respond(SimonTileId? tapped) async {
    if (phase != SimonGamePhase.playing) return;
    if (_resolving) return;
    _resolving = true;
    final generation = _generation;

    final correct = currentTrial.obey
        ? tapped == currentTrial.target
        : tapped == null;
    lastAnswerCorrect = correct;
    if (correct) currentPlayer.correctCount++;
    currentPlayer.roundsPlayed++;
    notifyListeners();

    // Oyuncunun doğru/yanlış geri bildirimini görebilmesi için kısa bir
    // duraklama, ardından bir sonraki tura geçilir.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (generation != _generation) return;

    lastAnswerCorrect = null;

    if (currentPlayer.roundsPlayed >= simonRoundsPerPlayer) {
      final nextIndex = _findNextUnfinishedPlayerIndex();
      if (nextIndex == null) {
        phase = SimonGamePhase.finished;
      } else {
        currentPlayerIndex = nextIndex;
        currentTrial = _generateTrial();
        phase = SimonGamePhase.turnTransition;
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
      if (players[index].roundsPlayed < simonRoundsPerPlayer) return index;
    }
    return null;
  }

  void acknowledgeTurnTransition() {
    phase = SimonGamePhase.playing;
    notifyListeners();
  }

  void restart() {
    _generation++;
    players = [];
    currentPlayerIndex = 0;
    lastAnswerCorrect = null;
    _resolving = false;
    phase = SimonGamePhase.setup;
    notifyListeners();
  }
}
