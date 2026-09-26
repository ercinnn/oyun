import 'dart:math';

import '../models/galileo/galileo_scene.dart';
import '../models/galileo/galileo_task.dart';
import '../models/galileo/jupiter.dart';
import '../models/galileo/solar.dart';
import '../models/galileo/telescope.dart';
import '../models/science/scientist_phase.dart';
import '../services/scientist_sounds.dart';
import 'scientist_game_controller.dart';

/// Her oyuncunun görev sayısı: 3 görev türü × 2 ("ambiguous import" kuralı
/// yüzünden kendine özgü ad).
const int galileoRoundsPerPlayer = 6;

/// "Uydu nereye gitti?" sorularının gece sayıları: yarım tura yakın (öbür
/// yan) ya da tam tura yakın (aynı yan). Test her birinin açıkça bir yanda
/// kaldığını doğrular.
const Map<String, List<int>> galileoMoonNights = {
  'io': [1, 2],
  'europa': [2, 4],
  'ganymede': [4, 7],
  'callisto': [8, 17],
};

/// Venüs evre sorularında Venüs'ün Dünya'ya göre açısı: yakın (hilal) ya da
/// Güneş'in öbür yanı (dolunaya yakın).
const List<double> galileoVenusOffsets = [20, 160];

/// Keşif defterine en fazla bu kadar gece çizilir.
const int galileoNotebookLimit = 8;

/// Galileo oyununun görevleri ve Gözlemevi (keşif).
class GalileoController extends ScientistGameController<GalileoTask> {
  GalileoController({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  List<GalileoTask> _telescopePlan = [];
  List<GalileoTask> _jupiterPlan = [];
  List<GalileoTask> _solarPlan = [];

  // Keşif durumu.
  GalileoStation station = GalileoStation.telescope;
  SkyTarget target = SkyTarget.jupiter;
  double objectiveCm = 90;
  double eyepieceCm = 5;
  double tubeCm = 100;
  double nights = 0;
  double day = 0;

  /// Galileo'nun defteri gibi: çizilen geceler (gece numarası + çizim).
  List<(double, String)> notebook = [];

  @override
  int get roundsPerPlayer => galileoRoundsPerPlayer;

  GalileoScene get scene {
    if (phase == ScientistPhase.explore) return _exploreScene;
    if (phase == ScientistPhase.playing && players.isNotEmpty) {
      return showingResult
          ? currentTask.resultScene(lastAnswerIndex!)
          : currentTask.questionScene;
    }
    return const GalileoScene(station: GalileoStation.telescope);
  }

  // ─────────────────────────── Görevler ───────────────────────────

  @override
  void planForPlayer() {
    _telescopePlan = [_magnifyTask(), _focusTask()]..shuffle(_rng);
    _jupiterPlan = [_fastestMoonTask(), _moonWhereTask()]..shuffle(_rng);
    _solarPlan = [_fastestPlanetTask(), _venusTask()]..shuffle(_rng);
  }

  @override
  GalileoTask generateTask(int round) {
    final kind = GalileoTaskKind.values[round % 3];
    final repeat = (round ~/ 3) % 2;
    return switch (kind) {
      GalileoTaskKind.telescope => _telescopePlan[repeat],
      GalileoTaskKind.jupiter => _jupiterPlan[repeat],
      GalileoTaskKind.solar => _solarPlan[repeat],
    };
  }

  /// Üç çift; büyütmeleri birbirinden farklı olana kadar yeniden seçilir.
  MagnifyTask _magnifyTask() {
    while (true) {
      final pairs = [
        for (var i = 0; i < 3; i++)
          (
            objectiveLensesCm[_rng.nextInt(objectiveLensesCm.length)],
            eyepieceLensesCm[_rng.nextInt(eyepieceLensesCm.length)],
          ),
      ];
      final mags = pairs.map((p) => magnification(p.$1, p.$2)).toSet();
      if (mags.length == 3) return MagnifyTask(pairs);
    }
  }

  FocusTask _focusTask() {
    final fo = objectiveLensesCm[_rng.nextInt(objectiveLensesCm.length)];
    final fe = eyepieceLensesCm[_rng.nextInt(eyepieceLensesCm.length)];
    // Yaygın yanlışlar: toplamak ya da yalnızca objektifi almak.
    final choices = [fo - fe, fo + fe, fo]..shuffle(_rng);
    return FocusTask(fo, fe, choices);
  }

  FastestMoonTask _fastestMoonTask() =>
      FastestMoonTask((List.of(jupiterMoons)..shuffle(_rng)).take(3).toList());

  MoonWhereTask _moonWhereTask() {
    final moon = jupiterMoons[_rng.nextInt(jupiterMoons.length)];
    final options = galileoMoonNights[moon.id]!;
    return MoonWhereTask(moon, options[_rng.nextInt(options.length)]);
  }

  FastestPlanetTask _fastestPlanetTask() =>
      FastestPlanetTask((List.of(planets)..shuffle(_rng)).take(3).toList());

  VenusPhaseTask _venusTask() => VenusPhaseTask(
    galileoVenusOffsets[_rng.nextInt(galileoVenusOffsets.length)],
  );

  // ─────────────────────────── Keşif ───────────────────────────

  @override
  void resetExplore() {
    station = GalileoStation.telescope;
    target = SkyTarget.jupiter;
    objectiveCm = 90;
    eyepieceCm = 5;
    tubeCm = 100;
    nights = 0;
    day = 0;
    notebook = [];
  }

  void setStation(GalileoStation value) {
    if (station == value) return;
    station = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void setTarget(SkyTarget value) {
    target = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void setObjective(double cm) {
    objectiveCm = cm;
    notifyListeners();
  }

  void setEyepiece(double cm) {
    eyepieceCm = cm;
    notifyListeners();
  }

  void setTube(double cm) {
    tubeCm = cm.clamp(tubeMinCm, tubeMaxCm).toDouble();
    notifyListeners();
  }

  void setNights(double value) {
    nights = max(0, value);
    notifyListeners();
  }

  void nextNight() {
    playSound(ScienceSound.tick);
    setNights(nights.floorToDouble() + 1);
  }

  /// Bu gecenin görünüşünü deftere çizer (aynı gece iki kez çizilmez).
  void sketchTonight() {
    if (notebook.any((e) => e.$1 == nights)) return;
    notebook = [...notebook, (nights, notebookSketch(nights))];
    playSound(ScienceSound.scratch);
    if (notebook.length > galileoNotebookLimit) {
      notebook = notebook.sublist(notebook.length - galileoNotebookLimit);
    }
    notifyListeners();
  }

  void clearNotebook() {
    notebook = [];
    notifyListeners();
  }

  void setDay(double value) {
    day = max(0, value);
    notifyListeners();
  }

  void advanceDays(double days) {
    playSound(ScienceSound.tick);
    setDay(day + days);
  }

  GalileoScene get _exploreScene => GalileoScene(
    station: station,
    target: target,
    objectiveCm: objectiveCm,
    eyepieceCm: eyepieceCm,
    tubeCm: tubeCm,
    nights: nights,
    day: day,
  );
}
