import 'dart:math';

import '../data/newton_objects.dart';
import '../models/newton/cart.dart';
import '../models/newton/falling.dart';
import '../models/newton/newton_scene.dart';
import '../models/newton/newton_task.dart';
import '../models/newton/prism.dart';
import '../models/science/scientist_phase.dart';
import '../services/scientist_sounds.dart';
import 'scientist_game_controller.dart';

/// Her oyuncunun görev sayısı: 3 görev türü × 2. Diğer oyunların tur
/// sabitleriyle aynı adı kullanmıyoruz ("ambiguous import" kuralı).
const int newtonRoundsPerPlayer = 6;

/// Havada belirgin farkla düşen çiftler (hafif/geniş olan havada süzülür).
const List<(String, String)> newtonDifferentPairs = [
  ('apple', 'feather'),
  ('paper_ball', 'paper_flat'),
  ('tennis', 'balloon'),
  ('hammer', 'feather'),
];

/// Aynı anda yere değen çiftler: havasız ortamda ya da kısa düşüşte havanın
/// ikisini de pek tutamadığı ağır cisimler.
const List<(String, String, FallEnvironment)> newtonSameTimePairs = [
  ('hammer', 'feather', FallEnvironment.moon),
  ('apple', 'paper_flat', FallEnvironment.vacuum),
  ('bowling', 'tennis', FallEnvironment.air),
];

/// Newton oyununun görevleri ve Keşif Laboratuvarı.
class NewtonController extends ScientistGameController<NewtonTask> {
  NewtonController({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  // Oyuncu başına görev planı.
  List<FallTask> _fallPlan = [];
  List<PrismQuestion> _prismPlan = [];
  List<CartQuestion> _cartPlan = [];

  // Keşif durumu.
  NewtonStation station = NewtonStation.fall;
  FallingObject fallA = fallingObjectById('apple');
  FallingObject fallB = fallingObjectById('feather');
  FallEnvironment environment = FallEnvironment.air;
  LightSource light = LightSource.white;
  bool secondPrism = false;
  bool lampOn = false;
  CartLane laneA = const CartLane();
  CartLane laneB = const CartLane(boxes: 2);
  PushStrength push = PushStrength.medium;
  int _fallRun = 0;
  int _cartRun = 0;

  /// Son "Bırak!"/"İt!" deneyinin ayarları değişmeden duruyorsa true
  /// (sonuç kartı ancak o zaman gösterilir).
  bool get fallDone => _fallRun > 0;
  bool get cartDone => _cartRun > 0;

  @override
  int get roundsPerPlayer => newtonRoundsPerPlayer;

  NewtonScene get scene {
    if (phase == ScientistPhase.explore) return _exploreScene;
    if (phase == ScientistPhase.playing && players.isNotEmpty) {
      return showingResult
          ? currentTask.resultScene(lastAnswerIndex!)
          : currentTask.questionScene;
    }
    return const NewtonScene(station: NewtonStation.fall);
  }

  // ─────────────────────────── Görevler ───────────────────────────

  @override
  void planForPlayer() {
    final diff = newtonDifferentPairs[_rng.nextInt(newtonDifferentPairs.length)];
    final same = newtonSameTimePairs[_rng.nextInt(newtonSameTimePairs.length)];
    FallTask pair(String a, String b, FallEnvironment env) => _rng.nextBool()
        ? FallTask(fallingObjectById(a), fallingObjectById(b), env)
        : FallTask(fallingObjectById(b), fallingObjectById(a), env);
    _fallPlan = [
      pair(diff.$1, diff.$2, FallEnvironment.air),
      pair(same.$1, same.$2, same.$3),
    ]..shuffle(_rng);
    _prismPlan = (List.of(PrismQuestion.values)..shuffle(_rng)).take(2).toList();
    _cartPlan = List.of(CartQuestion.values)..shuffle(_rng);
  }

  @override
  NewtonTask generateTask(int round) {
    final kind = NewtonTaskKind.values[round % 3];
    final repeat = round ~/ 3;
    return switch (kind) {
      NewtonTaskKind.fall => _fallPlan[repeat % _fallPlan.length],
      NewtonTaskKind.prism => _prismTask(_prismPlan[repeat % _prismPlan.length]),
      NewtonTaskKind.cart => _cartTask(_cartPlan[repeat % _cartPlan.length]),
    };
  }

  PrismTask _prismTask(PrismQuestion q) {
    if (q == PrismQuestion.mostBent) {
      // Rastgele üç farklı renk; doğru cevap sapma açısından hesaplanır.
      final colors = (List.of(spectrumColors)..shuffle(_rng)).take(3).toList();
      return PrismTask(
        q,
        [for (final c in colors) c.name],
        colorChoices: colors,
      );
    }
    return PrismTask(q, List.of(PrismTask.optionSet(q))..shuffle(_rng));
  }

  CartTask _cartTask(CartQuestion q) {
    late CartLane a;
    late CartLane b;
    late PushStrength p;
    switch (q) {
      case CartQuestion.load:
        final surface = _rng.nextBool() ? CartSurface.wood : CartSurface.ice;
        a = CartLane(surface: surface);
        b = CartLane(surface: surface, boxes: 1 + _rng.nextInt(maxBoxes));
        p = surface == CartSurface.ice ? PushStrength.soft : PushStrength.medium;
      case CartQuestion.surface:
        final pairs = [
          (CartSurface.ice, CartSurface.carpet),
          (CartSurface.ice, CartSurface.wood),
          (CartSurface.wood, CartSurface.carpet),
        ];
        final (s1, s2) = pairs[_rng.nextInt(pairs.length)];
        a = CartLane(surface: s1);
        b = CartLane(surface: s2);
        p = PushStrength.soft;
    }
    return _rng.nextBool() ? CartTask(q, a, b, p) : CartTask(q, b, a, p);
  }

  // ─────────────────────────── Keşif ───────────────────────────

  @override
  void resetExplore() {
    station = NewtonStation.fall;
    fallA = fallingObjectById('apple');
    fallB = fallingObjectById('feather');
    environment = FallEnvironment.air;
    light = LightSource.white;
    secondPrism = false;
    lampOn = false;
    laneA = const CartLane();
    laneB = const CartLane(boxes: 2);
    push = PushStrength.medium;
    _fallRun = 0;
    _cartRun = 0;
  }

  void setStation(NewtonStation value) {
    if (station == value) return;
    station = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  /// Ayar değişince deney sıfırlanır: cisimler kuleye geri çıkar.
  void setFallA(FallingObject o) {
    fallA = o;
    _fallRun = 0;
    notifyListeners();
  }

  void setFallB(FallingObject o) {
    fallB = o;
    _fallRun = 0;
    notifyListeners();
  }

  void setEnvironment(FallEnvironment env) {
    environment = env;
    _fallRun = 0;
    notifyListeners();
  }

  /// Cisimleri bırakır; tekrar basmak deneyi baştan oynatır.
  void dropObjects() {
    _fallRun++;
    playSound(ScienceSound.whoosh);
    notifyListeners();
  }

  void setLight(LightSource value) {
    light = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void setSecondPrism(bool value) {
    secondPrism = value;
    playSound(ScienceSound.clink);
    notifyListeners();
  }

  void setLamp(bool on) {
    lampOn = on;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void setLaneA(CartLane lane) {
    laneA = lane;
    _cartRun = 0;
    notifyListeners();
  }

  void setLaneB(CartLane lane) {
    laneB = lane;
    _cartRun = 0;
    notifyListeners();
  }

  void setPush(PushStrength value) {
    push = value;
    _cartRun = 0;
    notifyListeners();
  }

  void pushCarts() {
    _cartRun++;
    playSound(ScienceSound.boing);
    notifyListeners();
  }

  NewtonScene get _exploreScene => NewtonScene(
    station: station,
    fallA: fallA,
    fallB: fallB,
    environment: environment,
    light: light,
    secondPrism: secondPrism,
    laneA: laneA,
    laneB: laneB,
    push: push,
    run: switch (station) {
      NewtonStation.fall => _fallRun,
      NewtonStation.prism => lampOn ? 1 : 0,
      NewtonStation.cart => _cartRun,
    },
  );
}
