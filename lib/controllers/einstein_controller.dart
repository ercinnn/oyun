import 'dart:math';

import '../models/einstein/einstein_scene.dart';
import '../models/einstein/einstein_task.dart';
import '../models/einstein/spacetime.dart';
import '../models/einstein/time_dilation.dart';
import '../models/science/scientist_phase.dart';
import '../services/scientist_sounds.dart';
import 'scientist_game_controller.dart';

/// Her oyuncunun görev sayısı: 3 görev türü × 2 ("ambiguous import" kuralı
/// yüzünden kendine özgü ad).
const int einsteinRoundsPerPlayer = 6;

/// "Bilye ne yapar?" sorularının kurguları; üç sonucun her biri temsil edilir.
const List<(CentralMass, LaunchSpeed)> einsteinFateCases = [
  (CentralMass.earth, LaunchSpeed.slow),
  (CentralMass.earth, LaunchSpeed.medium),
  (CentralMass.earth, LaunchSpeed.fast),
  (CentralMass.sun, LaunchSpeed.medium),
  (CentralMass.sun, LaunchSpeed.fast),
];

/// İkiz sorusunun hızları (yaşlar tam sayı çıksın diye 0,6 ve 0,8).
const List<double> einsteinTwinSpeeds = [0.6, 0.8];

/// Einstein oyununun görevleri ve Einstein'ın Laboratuvarı (keşif).
class EinsteinController extends ScientistGameController<EinsteinTask> {
  EinsteinController({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  List<EinsteinTask> _sheetPlan = [];
  List<EinsteinTask> _clockPlan = [];
  List<EinsteinTask> _energyPlan = [];

  // Keşif durumu.
  EinsteinStation station = EinsteinStation.sheet;
  CentralMass center = CentralMass.earth;
  LaunchSpeed speed = LaunchSpeed.medium;
  double shipSpeed = 0.8;
  double grams = 0.01;
  int _launches = 0;
  int _voyages = 0;
  int _conversions = 0;

  bool get launched => _launches > 0;
  bool get voyaged => _voyages > 0;
  bool get converted => _conversions > 0;

  @override
  int get roundsPerPlayer => einsteinRoundsPerPlayer;

  EinsteinScene get scene {
    if (phase == ScientistPhase.explore) return _exploreScene;
    if (phase == ScientistPhase.playing && players.isNotEmpty) {
      return showingResult
          ? currentTask.resultScene(lastAnswerIndex!)
          : currentTask.questionScene;
    }
    return const EinsteinScene(station: EinsteinStation.sheet);
  }

  // ─────────────────────────── Görevler ───────────────────────────

  @override
  void planForPlayer() {
    final (c, s) = einsteinFateCases[_rng.nextInt(einsteinFateCases.length)];
    _sheetPlan = [FateTask(c, s), const OrbitWhichTask(LaunchSpeed.medium)]
      ..shuffle(_rng);

    final v = einsteinTwinSpeeds[_rng.nextInt(einsteinTwinSpeeds.length)];
    final ship = shipYears(ShipAgeTask.earthYears, v);
    final three = (List.of(shipSpeeds.where((s) => s > 0))..shuffle(_rng))
        .take(3)
        .toList();
    _clockPlan = [
      ShipAgeTask(v, [
        ship,
        ShipAgeTask.earthYears,
        ShipAgeTask.earthYears * lorentzGamma(v),
      ]..shuffle(_rng)),
      SlowestClockTask(three),
    ]..shuffle(_rng);

    final k = 2 + _rng.nextInt(2);
    _energyPlan = [
      MassVsWoodTask(List.of(MassVsWoodTask.optionSet)..shuffle(_rng)),
      ScaleMassTask(k, List.of(ScaleMassTask.optionSet(k))..shuffle(_rng)),
    ]..shuffle(_rng);
  }

  @override
  EinsteinTask generateTask(int round) {
    final kind = EinsteinTaskKind.values[round % 3];
    final repeat = (round ~/ 3) % 2;
    return switch (kind) {
      EinsteinTaskKind.sheet => _sheetPlan[repeat],
      EinsteinTaskKind.clock => _clockPlan[repeat],
      EinsteinTaskKind.energy => _energyPlan[repeat],
    };
  }

  // ─────────────────────────── Keşif ───────────────────────────

  @override
  void resetExplore() {
    station = EinsteinStation.sheet;
    center = CentralMass.earth;
    speed = LaunchSpeed.medium;
    shipSpeed = 0.8;
    grams = 0.01;
    _launches = 0;
    _voyages = 0;
    _conversions = 0;
  }

  void setStation(EinsteinStation value) {
    if (station == value) return;
    station = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  /// Ayar değişince deney sıfırlanır (bilye kenara döner).
  void setCenter(CentralMass value) {
    center = value;
    _launches = 0;
    notifyListeners();
  }

  void setSpeed(LaunchSpeed value) {
    speed = value;
    _launches = 0;
    notifyListeners();
  }

  void launch() {
    _launches++;
    playSound(ScienceSound.whoosh);
    notifyListeners();
  }

  void setShipSpeed(double v) {
    shipSpeed = v;
    _voyages = 0;
    notifyListeners();
  }

  void startVoyage() {
    _voyages++;
    playSound(ScienceSound.rumble);
    notifyListeners();
  }

  void setGrams(double g) {
    grams = g;
    _conversions = 0;
    notifyListeners();
  }

  void convert() {
    _conversions++;
    playSound(ScienceSound.powerUp);
    notifyListeners();
  }

  EinsteinScene get _exploreScene => EinsteinScene(
    station: station,
    center: center,
    speed: speed,
    shipSpeed: shipSpeed,
    grams: grams,
    run: switch (station) {
      EinsteinStation.sheet => _launches,
      EinsteinStation.clock => _voyages,
      EinsteinStation.energy => _conversions,
    },
  );
}
