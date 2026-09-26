import 'dart:math';

import '../data/archimedes_objects.dart';
import '../models/archimedes/archimedes_scene.dart';
import '../models/archimedes/archimedes_screw.dart';
import '../models/archimedes/archimedes_task.dart';
import '../models/archimedes/boat.dart';
import '../models/archimedes/buoyancy.dart';
import '../models/science/scientist_phase.dart';
import '../services/scientist_sounds.dart';
import 'scientist_game_controller.dart';

/// Her oyuncunun görev sayısı: 4 görev türü × 2. Diğer oyunların tur
/// sabitleriyle aynı adı kullanmıyoruz ("ambiguous import" kuralı).
const int archimedesRoundsPerPlayer = 8;

/// Keşif Atölyesi'nde kaba en fazla kaç cisim bırakılabilir.
const int archimedesTankCapacity = 4;

/// Vida görevlerinin açı üçlüleri: her birinde tam bir açı en az turda sular
/// (biri tarlaya yetişmez ya da su geri kayar). Test bunu doğrular.
const List<List<double>> archimedesScrewAngleSets = [
  [15, 35, 70],
  [20, 30, 55],
  [25, 45, 65],
];

/// Arşimet oyununun görevleri ve Keşif Atölyesi. Oyuncu/tur/sonuç akışı
/// ortak tabandadır ([ScientistGameController]); burada yalnızca görev
/// üretimi ve atölyenin durumu var. Görünüm [scene]'e doğru yumuşakça ilerler
/// (cisim düşer, su yükselir, vida döner); mantık hiçbir animasyonu beklemez.
class ArchimedesController extends ScientistGameController<ArchimedesTask> {
  ArchimedesController({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  // Oyuncu başına görev planı (tekrar etmesin diye karıştırılmış havuzlar).
  List<BuoyancyObject> _floatPlan = [];
  List<BoatSpec> _boatPlan = [];
  List<List<double>> _screwPlan = [];
  bool _crownFakeIsA = true;

  // Keşif Atölyesi durumu.
  ArchimedesStation station = ArchimedesStation.tank;
  BuoyancyObject selectedObject = archimedesObjects.first;
  List<BuoyancyObject> tankObjects = [];
  BoatSpec exploreBoat = archimedesBoats.last;
  int exploreCrates = 0;
  double screwAngle = 30;
  double screwTurns = 0;
  double fieldLitres = 0;
  int _exploreRevision = 0;
  double _crankSoundTurns = 0;

  @override
  int get roundsPerPlayer => archimedesRoundsPerPlayer;

  /// Görünümün çizdiği sahne.
  ArchimedesScene get scene {
    if (phase == ScientistPhase.explore) return _exploreScene;
    if (phase == ScientistPhase.playing && players.isNotEmpty) {
      return showingResult
          ? currentTask.resultScene(lastAnswerIndex!)
          : currentTask.questionScene;
    }
    return const ArchimedesScene(station: ArchimedesStation.tank);
  }

  /// Oyuncunun iki "yüzer mi" turunda biri yüzen, biri batan cisim gelir;
  /// iki gemi ve iki açı üçlüsü birbirinden farklıdır.
  @override
  void planForPlayer() {
    final floating = archimedesObjects.where((o) => o.floats).toList()
      ..shuffle(_rng);
    final sinking = archimedesObjects.where((o) => !o.floats).toList()
      ..shuffle(_rng);
    _floatPlan = [floating.first, sinking.first]..shuffle(_rng);
    _boatPlan = List.of(archimedesBoats)..shuffle(_rng);
    _screwPlan = List.of(archimedesScrewAngleSets)..shuffle(_rng);
    _crownFakeIsA = _rng.nextBool();
  }

  @override
  ArchimedesTask generateTask(int round) {
    final kind = ArchimedesTaskKind.values[round % 4];
    final repeat = round ~/ 4; // bu türün kaçıncı turu (0 ya da 1)
    switch (kind) {
      case ArchimedesTaskKind.floatSink:
        return FloatSinkTask(_floatPlan[repeat % _floatPlan.length]);
      case ArchimedesTaskKind.displacement:
        if (repeat.isOdd) return CrownTask(fakeIsA: _crownFakeIsA);
        return _displacementPair();
      case ArchimedesTaskKind.boat:
        return _boatTask(_boatPlan[repeat % _boatPlan.length]);
      case ArchimedesTaskKind.screw:
        final angles = List.of(_screwPlan[repeat % _screwPlan.length])
          ..shuffle(_rng);
        return ScrewTask(angles);
    }
  }

  /// Batan iki cisim; hacimleri en az 1,5 kat farklı olsun ki su seviyesi
  /// farkı gözle görülsün.
  DisplacementTask _displacementPair() {
    final sinking = archimedesObjects.where((o) => !o.floats).toList();
    final pairs = <(BuoyancyObject, BuoyancyObject)>[
      for (final a in sinking)
        for (final b in sinking)
          if (a.id.compareTo(b.id) < 0 &&
              max(a.volumeCm3, b.volumeCm3) >=
                  1.5 * min(a.volumeCm3, b.volumeCm3) &&
              // Hiç değilse biri gözle görülür yükseltsin.
              max(a.waterRiseCm, b.waterRiseCm) >= 1)
            (a, b),
    ];
    final (a, b) = pairs[_rng.nextInt(pairs.length)];
    return _rng.nextBool() ? DisplacementTask(a, b) : DisplacementTask(b, a);
  }

  BoatTask _boatTask(BoatSpec boat) {
    final right = boat.maxCrates;
    final candidates = <int>{
      for (final d in const [-2, -1, 1, 2, 3])
        if (right + d >= 1) right + d,
    }.toList()
      ..shuffle(_rng);
    final choices = [right, candidates[0], candidates[1]]..sort();
    return BoatTask(boat, choices);
  }

  // ─────────────────────────── Keşif Atölyesi ───────────────────────────

  @override
  void resetExplore() {
    station = ArchimedesStation.tank;
    selectedObject = archimedesObjects.first;
    tankObjects = [];
    exploreBoat = archimedesBoats.last;
    exploreCrates = 0;
    screwAngle = 30;
    screwTurns = 0;
    fieldLitres = 0;
  }

  void setStation(ArchimedesStation value) {
    if (station == value) return;
    station = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void selectObject(BuoyancyObject object) {
    selectedObject = object;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  bool get tankFull => tankObjects.length >= archimedesTankCapacity;

  /// Seçili cismi kaba bırakır (her cisimden bir tane; kap dolunca no-op).
  void dropSelected() {
    if (tankFull || tankObjects.any((o) => o.id == selectedObject.id)) return;
    tankObjects = [...tankObjects, selectedObject];
    _exploreRevision++;
    playSound(ScienceSound.splash);
    notifyListeners();
  }

  void emptyTank() {
    if (tankObjects.isNotEmpty) playSound(ScienceSound.bubbles);
    tankObjects = [];
    _exploreRevision++;
    notifyListeners();
  }

  void selectBoat(BoatSpec boat) {
    exploreBoat = boat;
    exploreCrates = 0;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  /// Batmış gemiye sandık eklenmez; "−" ile yükü azaltınca gemi yeniden
  /// yüzer.
  void addCrate() {
    if (exploreBoat.sinks(exploreCrates)) return;
    exploreCrates++;
    // Son sandık gemiyi batırdıysa kabarcıklar, yoksa tahtanın tok sesi.
    playSound(
      exploreBoat.sinks(exploreCrates)
          ? ScienceSound.bubbles
          : ScienceSound.knock,
    );
    notifyListeners();
  }

  void removeCrate() {
    if (exploreCrates == 0) return;
    exploreCrates--;
    playSound(ScienceSound.knock);
    notifyListeners();
  }

  void setScrewAngle(double degrees) {
    screwAngle = degrees.clamp(screwMinAngle, screwMaxAngle).toDouble();
    notifyListeners();
  }

  /// Kol çevrildi ([turns] kadar tur, geri çevirmek suyu geri akıtmaz).
  void turnCrank(double turns) {
    if (turns <= 0) return;
    final before = fieldLitres;
    screwTurns += turns;
    fieldLitres = min(
      fieldNeedLitres,
      fieldLitres + screwLitresPerTurn(screwAngle) * turns,
    );
    // Kol sürüklenirken çok sık çağrılır: şırıltı yarım turda bir çalar,
    // tarla ilk kez dolduğunda da bir zil.
    _crankSoundTurns += turns;
    if (fieldLitres >= fieldNeedLitres && before < fieldNeedLitres) {
      playSound(ScienceSound.ding);
      _crankSoundTurns = 0;
    } else if (_crankSoundTurns >= 0.5) {
      _crankSoundTurns = 0;
      if (fieldLitres > before) playSound(ScienceSound.trickle);
    }
    notifyListeners();
  }

  void resetField() {
    fieldLitres = 0;
    notifyListeners();
  }

  ArchimedesScene get _exploreScene => ArchimedesScene(
    station: station,
    tanks: [
      TankState(
        held: tankFull || tankObjects.any((o) => o.id == selectedObject.id)
            ? null
            : selectedObject,
        dropped: tankObjects,
      ),
    ],
    boat: exploreBoat,
    crates: exploreCrates,
    screwAngle: screwAngle,
    screwTurns: screwTurns,
    fieldLitres: fieldLitres,
    revision: _exploreRevision,
  );
}
