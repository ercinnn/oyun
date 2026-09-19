import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/circuit_spec.dart';
import '../models/electric_task.dart';
import '../models/electric_task_factory.dart';
import '../models/electricity_phase.dart';
import '../models/electricity_player_state.dart';
import '../models/wire_puzzle.dart';

/// Her oyuncunun oynadığı tur sayısı. Diğer tur tabanlı oyunların sabitleriyle
/// aynı adı kullanmıyoruz (test/widget_test.dart hepsini birlikte import eder;
/// aynı ad "ambiguous import" hatası verir). 10 = 5 tür × 2.
const int electricRoundsPerPlayer = 10;

/// Kablo yolu seviyelerinin sayısı.
const int wireLevelCount = 12;

/// Elektrik Atölyesi'nin durum makinesi.
///
/// Bitki Laboratuvarı ve Çarpım Bahçesi gibi **tamamen senkron**: hiç
/// `Future.delayed` yok, bu yüzden `_generation`/`_resolving` korumasına gerek
/// yok. Cevaptan sonra tur kendi kendine ilerlemez; [showingResult] true olur
/// ve oyuncu "Devam"a ([continueAfterResult]) basana kadar açıklama panelini
/// okuyabilir. Ampul ışıması gibi animasyonlar tamamen sunum katmanındadır.
///
/// Üç mod: puanlı **görevler** ([startGame]), puansız **serbest devre
/// atölyesi** ([startFreeCircuit]) ve puansız **kablo yolu seviyeleri**
/// ([startWireLevels]).
class ElectricityController extends ChangeNotifier {
  ElectricityController({Random? random}) : _rng = random ?? Random();

  ElectricityPhase phase = ElectricityPhase.setup;
  List<ElectricityPlayerState> players = [];
  int currentPlayerIndex = 0;
  late ElectricTask currentTask;

  /// Cevap verildikten sonra açıklama paneli gösterilirken true.
  bool showingResult = false;
  bool lastAnswerCorrect = false;
  int? lastChoice;

  // Serbest devre atölyesi.
  CircuitSpec freeSpec = const CircuitSpec();

  // Kablo yolu seviyeleri.
  int wireLevel = 1;
  late WirePuzzle levelPuzzle;
  final Set<int> solvedLevels = {};

  final Random _rng;

  ElectricityPlayerState get currentPlayer => players[currentPlayerIndex];

  List<ElectricityPlayerState> get rankedByCorrect {
    final sorted = List<ElectricityPlayerState>.from(players);
    sorted.sort((a, b) => b.correctCount.compareTo(a.correctCount));
    return sorted;
  }

  // ─────────────────────────── Görevler ───────────────────────────

  void startGame(List<String> names) {
    players = names.map((name) => ElectricityPlayerState(name: name)).toList();
    currentPlayerIndex = 0;
    _clearResult();
    currentTask = _generateTask();
    phase = ElectricityPhase.playing;
    notifyListeners();
  }

  /// Çoktan seçmeli görevde bir seçenek seçildi.
  void answerChoice(int index) {
    if (phase != ElectricityPhase.playing || showingResult) return;
    final task = currentTask;
    if (task is! ChoiceTask) return;

    lastChoice = index;
    _recordAnswer(correct: index == task.correctIndex);
  }

  /// Kablo yolu görevinde bir karoya dokunuldu.
  void rotateWireTile(int index) {
    if (phase != ElectricityPhase.playing || showingResult) return;
    final task = currentTask;
    if (task is! WireTask) return;

    if (!task.puzzle.rotate(index)) return;
    if (task.puzzle.solved) {
      _recordAnswer(correct: task.solvedWell);
    } else {
      notifyListeners();
    }
  }

  /// Açıklama panelindeki "Devam"a basıldı: sıradaki tura, sıra devrine ya da
  /// sonuç ekranına geçilir.
  void continueAfterResult() {
    if (!showingResult) return;
    _clearResult();

    if (currentPlayer.roundsPlayed >= electricRoundsPerPlayer) {
      final nextIndex = _findNextUnfinishedPlayerIndex();
      if (nextIndex == null) {
        phase = ElectricityPhase.finished;
        notifyListeners();
        return;
      }
      currentPlayerIndex = nextIndex;
      phase = ElectricityPhase.turnTransition;
    }

    currentTask = _generateTask();
    notifyListeners();
  }

  void acknowledgeTurnTransition() {
    phase = ElectricityPhase.playing;
    notifyListeners();
  }

  void restart() {
    players = [];
    currentPlayerIndex = 0;
    _clearResult();
    phase = ElectricityPhase.setup;
    notifyListeners();
  }

  // ─────────────────────── Serbest devre atölyesi ───────────────────────

  void startFreeCircuit() {
    freeSpec = const CircuitSpec();
    phase = ElectricityPhase.freeCircuit;
    notifyListeners();
  }

  void setFreeSpec(CircuitSpec spec) {
    freeSpec = spec;
    notifyListeners();
  }

  // ─────────────────────── Kablo yolu seviyeleri ───────────────────────

  void startWireLevels() {
    phase = ElectricityPhase.wireLevels;
    selectWireLevel(1);
  }

  /// [level] (1-[wireLevelCount]) seviyesini kurar. Aynı seviye her zaman aynı
  /// bulmacayı verir (tohum seviye numarasından gelir).
  void selectWireLevel(int level) {
    wireLevel = level.clamp(1, wireLevelCount);
    levelPuzzle = WirePuzzle.generate(
      _sizeForLevel(wireLevel),
      Random(wireLevel * 7919),
    );
    notifyListeners();
  }

  /// Seviye 1-4: 3×3, 5-8: 4×4, 9-12: 5×5.
  static int _sizeForLevel(int level) => 3 + (level - 1) ~/ 4;

  void rotateLevelTile(int index) {
    if (!levelPuzzle.rotate(index)) return;
    if (levelPuzzle.solved) solvedLevels.add(wireLevel);
    notifyListeners();
  }

  void nextWireLevel() {
    if (wireLevel < wireLevelCount) selectWireLevel(wireLevel + 1);
  }

  // ───────────────────────────── İç işler ─────────────────────────────

  void _clearResult() {
    showingResult = false;
    lastAnswerCorrect = false;
    lastChoice = null;
  }

  void _recordAnswer({required bool correct}) {
    lastAnswerCorrect = correct;
    if (correct) currentPlayer.correctCount++;
    currentPlayer.roundsPlayed++;
    showingResult = true;
    notifyListeners();
  }

  /// Tur türü `roundsPlayed % 5` ile dönüşümlü: her oyuncu her türden iki
  /// tur görür.
  ElectricTask _generateTask() {
    final kinds = ElectricTaskKind.values;
    final kind = kinds[currentPlayer.roundsPlayed % kinds.length];
    return generateElectricTask(kind, _rng);
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (currentPlayerIndex + offset) % players.length;
      if (players[index].roundsPlayed < electricRoundsPerPlayer) return index;
    }
    return null;
  }
}
