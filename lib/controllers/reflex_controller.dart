import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/reflex_game_phase.dart';
import '../models/reflex_player_state.dart';
import '../models/reflex_round_state.dart';

/// Her oyuncunun oynadığı tur sayısı. Diğer oyunların round-sayaç
/// sabitleriyle (`roundsPerPlayer`, `patternRoundsPerPlayer`,
/// `maxSequenceLength`) çakışmasın diye ayrı adlandırıldı — hepsi
/// test/widget_test.dart içinde birlikte import ediliyor.
const int reflexRoundsPerPlayer = 5;

/// Sinyalden önce dokunmanın (erken başlama) cezası; gerçekçi bir tepki
/// süresinden (~150-400ms) kasıtlı olarak çok daha kötü.
const int falseStartPenaltyMs = 1000;

const Duration _minSignalDelay = Duration(milliseconds: 1200);
const Duration _maxSignalDelay = Duration(milliseconds: 3500);
const Duration _feedbackDelay = Duration(milliseconds: 900);

class ReflexController extends ChangeNotifier {
  ReflexGamePhase phase = ReflexGamePhase.setup;
  List<ReflexPlayerState> players = [];
  int currentPlayerIndex = 0;
  ReflexRoundState roundState = ReflexRoundState.waiting;

  /// Son turun tepki süresi (ms); sadece [ReflexRoundState.result] sırasında
  /// gösterim için doludur.
  int? lastReactionMs;

  // Süre ölçümü için: DateTime.now() yerine Stopwatch kullanılıyor çünkü
  // monotoniktir (saat kayması/NTP senkronizasyonu bir süre ölçümünü
  // etkileyemez) — Dart'ta bir aralık ölçmenin idiomatik yolu budur.
  final Stopwatch _stopwatch = Stopwatch();

  bool _resolving = false;
  // startGame/restart her çağrıldığında artar; bekleyen bir gecikme
  // tamamlandığında hâlâ aynı oyunda olduğumuzu doğrulamak için kullanılır.
  int _generation = 0;
  final Random _rng = Random();

  ReflexPlayerState get currentPlayer => players[currentPlayerIndex];

  List<ReflexPlayerState> get rankedByAverage {
    final sorted = List<ReflexPlayerState>.from(players);
    sorted.sort((a, b) => a.averageMs.compareTo(b.averageMs));
    return sorted;
  }

  void startGame(List<String> names) {
    _generation++;
    players = names.map((name) => ReflexPlayerState(name: name)).toList();
    currentPlayerIndex = 0;
    phase = ReflexGamePhase.playing;
    _beginRound();
  }

  Future<void> _beginRound() async {
    roundState = ReflexRoundState.waiting;
    lastReactionMs = null;
    _resolving = false;
    notifyListeners();

    final generation = _generation;
    final rangeMs =
        _maxSignalDelay.inMilliseconds - _minSignalDelay.inMilliseconds;
    final delayMs = _minSignalDelay.inMilliseconds + _rng.nextInt(rangeMs);
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    // Sadece _generation yetmez: oyuncu bu turda zaten erken bastıysa
    // (aynı generation içinde), bu bekleyen zamanlayıcı tooEarly durumunu
    // geri ready'ye çevirmemeli.
    if (generation != _generation || roundState != ReflexRoundState.waiting) {
      return;
    }

    roundState = ReflexRoundState.ready;
    _stopwatch
      ..reset()
      ..start();
    notifyListeners();
  }

  Future<void> tap() async {
    if (phase != ReflexGamePhase.playing) return;
    if (_resolving) return;

    _resolving = true;
    final generation = _generation;
    final int recordedMs;
    if (roundState == ReflexRoundState.waiting) {
      roundState = ReflexRoundState.tooEarly;
      recordedMs = falseStartPenaltyMs;
    } else {
      _stopwatch.stop();
      recordedMs = _stopwatch.elapsedMilliseconds;
      lastReactionMs = recordedMs;
      roundState = ReflexRoundState.result;
    }
    currentPlayer.reactionTimes.add(recordedMs);
    currentPlayer.roundsPlayed++;
    notifyListeners();

    // Oyuncunun tepki süresini/"çok erken" uyarısını görebilmesi için kısa
    // bir duraklama, ardından bir sonraki tura geçilir.
    await Future<void>.delayed(_feedbackDelay);
    if (generation != _generation) return;

    if (currentPlayer.roundsPlayed >= reflexRoundsPerPlayer) {
      final nextIndex = _findNextUnfinishedPlayerIndex();
      if (nextIndex == null) {
        phase = ReflexGamePhase.finished;
      } else {
        currentPlayerIndex = nextIndex;
        phase = ReflexGamePhase.turnTransition;
      }
      notifyListeners();
    } else {
      _beginRound();
    }
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (currentPlayerIndex + offset) % players.length;
      if (players[index].roundsPlayed < reflexRoundsPerPlayer) return index;
    }
    return null;
  }

  void acknowledgeTurnTransition() {
    phase = ReflexGamePhase.playing;
    _beginRound();
  }

  void restart() {
    _generation++;
    players = [];
    currentPlayerIndex = 0;
    roundState = ReflexRoundState.waiting;
    lastReactionMs = null;
    _resolving = false;
    _stopwatch.stop();
    phase = ReflexGamePhase.setup;
    notifyListeners();
  }
}
