import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/sequence_memory_game_phase.dart';
import '../models/sequence_memory_player_state.dart';
import '../models/sequence_tile_color.dart';

/// Kayıpsız ulaşılabilecek en uzun dizi; buraya ulaşmak turu "mükemmel"
/// skorla bitirir (sonsuz büyüyen bir dizi yerine).
const int maxSequenceLength = 20;

const Duration _preRoundDelay = Duration(milliseconds: 600);
const Duration _litDuration = Duration(milliseconds: 500);
const Duration _gapDuration = Duration(milliseconds: 200);
const Duration _correctExtendDelay = Duration(milliseconds: 400);
const Duration _wrongFlashDuration = Duration(milliseconds: 500);

class SequenceMemoryController extends ChangeNotifier {
  SequenceMemoryGamePhase phase = SequenceMemoryGamePhase.setup;
  List<SequenceMemoryPlayerState> players = [];
  int currentPlayerIndex = 0;

  /// Mevcut oyuncunun ezberlemesi gereken dizi; her doğru tekrarda bir
  /// kutu uzar.
  List<SequenceTileColor> sequence = [];

  /// Oyuncunun bu turda şu ana kadar doğru tıkladığı kutu sayısı.
  int playerInputIndex = 0;

  /// Dizi otomatik oynatılırken true; bu sırada dokunuşlar yok sayılır.
  bool showingSequence = false;

  /// Otomatik oynatım sırasında o an yanan kutu.
  SequenceTileColor? litTile;

  /// Yanlış tıklanan kutu; kısa bir kırmızı geri bildirim penceresi
  /// boyunca gösterilir.
  SequenceTileColor? wrongTile;

  bool _resolving = false;
  // startGame/restart her çağrıldığında artar; bekleyen bir gecikme
  // tamamlandığında hâlâ aynı oyunda olduğumuzu doğrulamak için kullanılır
  // (aksi halde yeniden başlatılmış bir oyunun state'ini bozabilir).
  int _generation = 0;
  final Random _rng = Random();

  SequenceMemoryPlayerState get currentPlayer => players[currentPlayerIndex];

  /// Dizi oynatılırken veya bir tur/tekrar sonucu çözülürken dokunuşların
  /// yok sayıldığını UI'ın bilmesi için (bkz. [tapTile]'ın aynı korumaları).
  bool get inputLocked => showingSequence || _resolving;

  List<SequenceMemoryPlayerState> get rankedByBestLength {
    final sorted = List<SequenceMemoryPlayerState>.from(players);
    sorted.sort((a, b) => b.bestLength.compareTo(a.bestLength));
    return sorted;
  }

  SequenceTileColor _randomTile() =>
      SequenceTileColor.values[_rng.nextInt(SequenceTileColor.values.length)];

  void startGame(List<String> names) {
    _generation++;
    players = names
        .map((name) => SequenceMemoryPlayerState(name: name))
        .toList();
    currentPlayerIndex = 0;
    phase = SequenceMemoryGamePhase.playing;
    _beginTurn();
  }

  void _beginTurn() {
    sequence = [_randomTile()];
    playerInputIndex = 0;
    litTile = null;
    wrongTile = null;
    notifyListeners();
    _playSequence();
  }

  Future<void> _playSequence() async {
    final generation = _generation;
    showingSequence = true;
    notifyListeners();

    await Future<void>.delayed(_preRoundDelay);
    if (generation != _generation) return;

    for (final tile in sequence) {
      litTile = tile;
      notifyListeners();
      await Future<void>.delayed(_litDuration);
      if (generation != _generation) return;

      litTile = null;
      notifyListeners();
      await Future<void>.delayed(_gapDuration);
      if (generation != _generation) return;
    }

    showingSequence = false;
    notifyListeners();
  }

  Future<void> tapTile(SequenceTileColor tile) async {
    if (phase != SequenceMemoryGamePhase.playing) return;
    if (showingSequence || _resolving) return;

    final correct = tile == sequence[playerInputIndex];
    if (!correct) {
      _resolving = true;
      final generation = _generation;
      wrongTile = tile;
      notifyListeners();

      await Future<void>.delayed(_wrongFlashDuration);
      if (generation != _generation) return;

      wrongTile = null;
      _endTurn(sequence.length - 1);
      return;
    }

    playerInputIndex++;
    if (playerInputIndex < sequence.length) {
      notifyListeners();
      return;
    }

    // Dizi eksiksiz tekrarlandı.
    if (sequence.length >= maxSequenceLength) {
      _endTurn(sequence.length);
      return;
    }

    _resolving = true;
    final generation = _generation;
    notifyListeners();

    await Future<void>.delayed(_correctExtendDelay);
    if (generation != _generation) return;

    sequence.add(_randomTile());
    playerInputIndex = 0;
    _resolving = false;
    await _playSequence();
  }

  void _endTurn(int achievedLength) {
    _resolving = false;
    currentPlayer.bestLength = achievedLength;
    currentPlayer.finished = true;

    final nextIndex = _findNextUnfinishedPlayerIndex();
    if (nextIndex == null) {
      phase = SequenceMemoryGamePhase.finished;
    } else {
      currentPlayerIndex = nextIndex;
      phase = SequenceMemoryGamePhase.turnTransition;
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
    phase = SequenceMemoryGamePhase.playing;
    _beginTurn();
  }

  void restart() {
    _generation++;
    players = [];
    currentPlayerIndex = 0;
    sequence = [];
    playerInputIndex = 0;
    showingSequence = false;
    litTile = null;
    wrongTile = null;
    _resolving = false;
    phase = SequenceMemoryGamePhase.setup;
    notifyListeners();
  }
}
