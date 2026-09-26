import 'dart:math';

import '../data/curie_samples.dart';
import '../models/curie/curie_scene.dart';
import '../models/curie/curie_task.dart';
import '../models/curie/geiger.dart';
import '../models/curie/shielding.dart';
import '../models/curie/therapy.dart';
import '../models/science/scientist_phase.dart';
import '../services/scientist_sounds.dart';
import 'scientist_game_controller.dart';

/// Her oyuncunun görev sayısı: 3 görev türü × 2 ("ambiguous import" kuralı
/// yüzünden kendine özgü ad).
const int curieRoundsPerPlayer = 6;

/// Tedavi keşfinde en çok ışın sayısı.
const int curieMaxBeams = 6;

/// Curie oyununun görevleri ve Curie'nin Laboratuvarı (keşif).
class CurieController extends ScientistGameController<CurieTask> {
  CurieController({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  List<CurieTask> _geigerPlan = [];
  List<CurieTask> _shieldPlan = [];
  List<CurieTask> _therapyPlan = [];

  // Keşif durumu.
  CurieStation station = CurieStation.geiger;
  RadioSample? sample;
  double distanceCm = referenceDistanceCm;
  RayType ray = RayType.alpha;
  Shield shield = Shield.none;
  int beamCount = 1;

  /// Işınlar farklı yönlerden mi (yoksa hepsi aynı yönden mi) geliyor.
  bool spread = true;
  bool beamsOn = false;

  @override
  int get roundsPerPlayer => curieRoundsPerPlayer;

  List<Beam> get plan =>
      spread ? spreadBeams(beamCount) : stackedBeams(beamCount);

  CurieScene get scene {
    if (phase == ScientistPhase.explore) return _exploreScene;
    if (phase == ScientistPhase.playing && players.isNotEmpty) {
      return showingResult
          ? currentTask.resultScene(lastAnswerIndex!)
          : currentTask.questionScene;
    }
    return const CurieScene(station: CurieStation.geiger);
  }

  // ─────────────────────────── Görevler ───────────────────────────

  @override
  void planForPlayer() {
    final hot = curieSamples.where((s) => s.radioactive).toList()..shuffle(_rng);
    final cold = curieSamples.where((s) => !s.radioactive).toList()..shuffle(_rng);
    // Işımayanlar yalnızca iki tane; ikisi de her seferinde gelir.
    final findSamples = [hot.first, ...cold.take(2)]..shuffle(_rng);
    final to = _rng.nextBool() ? 20.0 : 30.0;
    _geigerPlan = [
      FindSampleTask(findSamples),
      DistanceTask(hot[1], to, List.of(DistanceTask.optionSet(to))..shuffle(_rng)),
    ]..shuffle(_rng);

    final rays = List.of(RayType.values)..shuffle(_rng);
    _shieldPlan = [StopperTask(rays[0]), IdentifyRayTask(rays[1])]..shuffle(_rng);

    final n = 3 + _rng.nextInt(curieMaxBeams - 2); // 3…6 farklı yönden
    final plans = <(List<Beam>, String)>[
      (spreadBeams(1), '1 güçlü ışın'),
      (stackedBeams(n), '$n zayıf ışın, hepsi aynı yönden'),
      (spreadBeams(n), '$n zayıf ışın, farklı yönlerden'),
    ]..shuffle(_rng);
    final count = 3 + _rng.nextInt(3);
    final strength = 1.0 + _rng.nextInt(2);
    final total = count * strength;
    _therapyPlan = [
      BeamPlanTask([for (final p in plans) p.$1], [for (final p in plans) p.$2]),
      DoseSumTask(count, strength, [total, strength, count + strength]..shuffle(_rng)),
    ]..shuffle(_rng);
  }

  @override
  CurieTask generateTask(int round) {
    final kind = CurieTaskKind.values[round % 3];
    final repeat = (round ~/ 3) % 2;
    return switch (kind) {
      CurieTaskKind.geiger => _geigerPlan[repeat],
      CurieTaskKind.shield => _shieldPlan[repeat],
      CurieTaskKind.therapy => _therapyPlan[repeat],
    };
  }

  // ─────────────────────────── Keşif ───────────────────────────

  @override
  void resetExplore() {
    station = CurieStation.geiger;
    sample = null;
    distanceCm = referenceDistanceCm;
    ray = RayType.alpha;
    shield = Shield.none;
    beamCount = 1;
    spread = true;
    beamsOn = false;
  }

  void setStation(CurieStation value) {
    if (station == value) return;
    station = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  /// Sayacı bir numuneye götürür; aynı numuneye tekrar basmak sayacı kaldırır.
  void pickSample(RadioSample value) {
    sample = sample?.id == value.id ? null : value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  /// Geiger sayacının tek tıkı (keşif ekranındaki zamanlayıcı çağırır).
  void geigerClick() => playSound(ScienceSound.geiger);

  void setDistance(double cm) {
    distanceCm = cm.clamp(counterMinCm, counterMaxCm).toDouble();
    notifyListeners();
  }

  void setRay(RayType value) {
    ray = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void setShield(Shield value) {
    shield = value;
    playSound(ScienceSound.knock);
    notifyListeners();
  }

  void setBeamCount(int n) {
    beamCount = n.clamp(1, curieMaxBeams);
    notifyListeners();
  }

  void setSpread(bool value) {
    spread = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void setBeamsOn(bool on) {
    beamsOn = on;
    playSound(on ? ScienceSound.powerUp : ScienceSound.click);
    notifyListeners();
  }

  CurieScene get _exploreScene => CurieScene(
    station: station,
    sample: sample,
    distanceCm: distanceCm,
    ray: ray,
    shield: shield,
    beams: plan,
    beamsOn: beamsOn,
  );
}
