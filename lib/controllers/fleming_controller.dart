import 'dart:math';

import '../models/fleming/fleming_scene.dart';
import '../models/fleming/fleming_task.dart';
import '../models/fleming/hygiene.dart';
import '../models/fleming/petri.dart';
import '../models/fleming/resistance.dart';
import '../models/science/scientist_phase.dart';
import '../services/scientist_sounds.dart';
import 'scientist_game_controller.dart';

/// Her oyuncunun görev sayısı: 3 görev türü × 2 ("ambiguous import" kuralı
/// yüzünden kendine özgü ad).
const int flemingRoundsPerPlayer = 6;

/// Temizlik düzenekleri (her biri farklı sayıda koloni verir; test doğrular).
const List<HygieneSetup> flemingHygieneSetups = [
  HygieneSetup(false, HandTouch.none),
  HygieneSetup(true, HandTouch.none),
  HygieneSetup(false, HandTouch.washed),
  HygieneSetup(false, HandTouch.unwashed),
  HygieneSetup(true, HandTouch.unwashed),
];

/// Fleming oyununun görevleri ve Fleming'in Laboratuvarı (keşif).
class FlemingController extends ScientistGameController<FlemingTask> {
  FlemingController({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  List<FlemingTask> _petriPlan = [];
  List<FlemingTask> _hygienePlan = [];
  List<FlemingTask> _medicinePlan = [];

  // Keşif durumu.
  FlemingStation station = FlemingStation.petri;
  bool mold = true;
  double day = 0;
  bool lidOpen = false;
  HandTouch hand = HandTouch.none;
  bool incubated = false;
  int treatmentDays = 3;
  double medicineDay = 0;

  @override
  int get roundsPerPlayer => flemingRoundsPerPlayer;

  FlemingScene get scene {
    if (phase == ScientistPhase.explore) return _exploreScene;
    if (phase == ScientistPhase.playing && players.isNotEmpty) {
      return showingResult
          ? currentTask.resultScene(lastAnswerIndex!)
          : currentTask.questionScene;
    }
    return const FlemingScene(station: FlemingStation.petri);
  }

  // ─────────────────────────── Görevler ───────────────────────────

  @override
  void planForPlayer() {
    _petriPlan = [
      ZoneTask(List.of(ZoneTask.optionSet)..shuffle(_rng)),
      ControlDishTask(3.0 + _rng.nextInt(3)),
    ]..shuffle(_rng);

    final setups = (List.of(flemingHygieneSetups)..shuffle(_rng)).take(3).toList();
    final countSetup = flemingHygieneSetups[_rng.nextInt(flemingHygieneSetups.length)];
    final counts = {
      countSetup.colonies,
      for (final s in flemingHygieneSetups) s.colonies,
    }.toList();
    // Doğru sayı + iki farklı yanlış.
    final wrong = counts.where((c) => c != countSetup.colonies).toList()..shuffle(_rng);
    _hygienePlan = [
      DirtiestDishTask(setups),
      ColonyCountTask(countSetup, [countSetup.colonies, wrong[0], wrong[1]]..shuffle(_rng)),
    ]..shuffle(_rng);

    _medicinePlan = [
      StopEarlyTask(3 + _rng.nextInt(3), List.of(StopEarlyTask.optionSet)..shuffle(_rng)),
      VirusTask(Pathogen.values[_rng.nextInt(Pathogen.values.length)]),
    ]..shuffle(_rng);
  }

  @override
  FlemingTask generateTask(int round) {
    final kind = FlemingTaskKind.values[round % 3];
    final repeat = (round ~/ 3) % 2;
    return switch (kind) {
      FlemingTaskKind.petri => _petriPlan[repeat],
      FlemingTaskKind.hygiene => _hygienePlan[repeat],
      FlemingTaskKind.medicine => _medicinePlan[repeat],
    };
  }

  // ─────────────────────────── Keşif ───────────────────────────

  @override
  void resetExplore() {
    station = FlemingStation.petri;
    mold = true;
    day = 0;
    lidOpen = false;
    hand = HandTouch.none;
    incubated = false;
    treatmentDays = 3;
    medicineDay = 0;
  }

  void setStation(FlemingStation value) {
    if (station == value) return;
    station = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void setMold(bool value) {
    mold = value;
    playSound(ScienceSound.clink);
    notifyListeners();
  }

  void setDay(double value) {
    day = value.clamp(0, petriMaxDays.toDouble()).toDouble();
    notifyListeners();
  }

  void nextDay() {
    playSound(ScienceSound.tick);
    setDay(day.floorToDouble() + 1);
  }

  /// Ayar değişince kap temizlenir (yeniden bekletilmeli).
  void setLid(bool open) {
    lidOpen = open;
    incubated = false;
    playSound(ScienceSound.clink);
    notifyListeners();
  }

  void setHand(HandTouch value) {
    hand = value;
    incubated = false;
    notifyListeners();
  }

  void incubate() {
    incubated = true;
    playSound(ScienceSound.ding);
    notifyListeners();
  }

  void setTreatmentDays(int days) {
    treatmentDays = days.clamp(0, fullCourseDays);
    medicineDay = 0;
    notifyListeners();
  }

  void runCourse() {
    medicineDay = observedDays.toDouble();
    playSound(ScienceSound.ding);
    notifyListeners();
  }

  FlemingScene get _exploreScene => FlemingScene(
    station: station,
    mold: mold,
    day: day,
    lidOpen: lidOpen,
    hand: hand,
    incubated: incubated,
    treatmentDays: treatmentDays,
    medicineDay: medicineDay,
  );
}
