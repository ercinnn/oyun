import 'dart:math';

import '../models/science/scientist_phase.dart';
import '../models/tesla/generator.dart';
import '../models/tesla/tesla_scene.dart';
import '../models/tesla/tesla_task.dart';
import '../models/tesla/transmission.dart';
import '../models/tesla/wireless.dart';
import '../services/scientist_sounds.dart';
import 'scientist_game_controller.dart';

/// Her oyuncunun görev sayısı: 3 görev türü × 2 ("ambiguous import" kuralı
/// yüzünden kendine özgü ad).
const int teslaRoundsPerPlayer = 6;

/// Gerilim sorularının uzaklıkları (km). 1 ve 10 km'de 2 000 V ile 20 000 V
/// aynı sayıda ev yakıyor (soru belirsizleşir); test her uzaklıkta tek bir en
/// iyi seçenek olduğunu doğrular.
const List<double> teslaVoltageTaskDistancesKm = [30, 50];

/// Transformatör soruları: (giriş V, birinci sarım, ikinci sarım).
const List<(double, int, int)> teslaTransformerCases = [
  (200, 10, 100),
  (200, 10, 1000),
  (2000, 100, 10),
  (20000, 1000, 10),
];

/// Lamba uzaklık soruları: (şimdiki m, yeni m).
const List<(double, double)> teslaLampMoves = [
  (1, 3),
  (0.8, 2.5),
  (3, 1),
];

/// Tesla oyununun görevleri ve Tesla'nın Laboratuvarı (keşif).
class TeslaController extends ScientistGameController<TeslaTask> {
  TeslaController({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  List<TeslaTask> _generatorPlan = [];
  List<TeslaTask> _transmissionPlan = [];
  List<TeslaTask> _wirelessPlan = [];

  // Keşif durumu.
  TeslaStation station = TeslaStation.generator;
  PowerSource source = PowerSource.generator;
  double turnsPerSecond = 1;
  double distanceKm = 10;
  int secondaryTurns = primaryTurns;
  bool coilOn = false;
  double transmitterKHz = 200;
  double receiverKHz = 120;
  double lampDistanceM = 1;

  @override
  int get roundsPerPlayer => teslaRoundsPerPlayer;

  TeslaScene get scene {
    if (phase == ScientistPhase.explore) return _exploreScene;
    if (phase == ScientistPhase.playing && players.isNotEmpty) {
      return showingResult
          ? currentTask.resultScene(lastAnswerIndex!)
          : currentTask.questionScene;
    }
    return const TeslaScene(station: TeslaStation.generator);
  }

  // ─────────────────────────── Görevler ───────────────────────────

  List<String> _shuffled(List<String> xs) => List.of(xs)..shuffle(_rng);

  @override
  void planForPlayer() {
    _generatorPlan = [
      SpeedTask(
        [0.5, 1.0][_rng.nextInt(2)],
        [2.0, 3.0][_rng.nextInt(2)],
        _shuffled(SpeedTask.optionSet),
      ),
      LedTask(
        PowerSource.values[_rng.nextInt(PowerSource.values.length)],
        _shuffled([for (final p in LedPattern.values) p.label]),
      ),
    ]..shuffle(_rng);

    final distance = teslaVoltageTaskDistancesKm[
        _rng.nextInt(teslaVoltageTaskDistancesKm.length)];
    final (input, primary, secondary) =
        teslaTransformerCases[_rng.nextInt(teslaTransformerCases.length)];
    final out = transformerOut(input, primary, secondary);
    // Yaygın yanlışlar: ters yönde çarpmak ya da hiç değişmediğini sanmak.
    final wrongWay = input * primary / secondary;
    _transmissionPlan = [
      VoltageTask(distance, List.of(secondaryTurnsOptions)..shuffle(_rng)),
      TransformerTask(
        inputVolts: input,
        primary: primary,
        secondary: secondary,
        choices: [out, wrongWay, input]..shuffle(_rng),
      ),
    ]..shuffle(_rng);

    final (from, to) = teslaLampMoves[_rng.nextInt(teslaLampMoves.length)];
    final transmitter = transmitterFrequenciesKHz[
        _rng.nextInt(transmitterFrequenciesKHz.length)];
    _wirelessPlan = [
      LampDistanceTask(from, to, _shuffled(LampDistanceTask.optionSet)),
      TuningTask(transmitter, List.of(transmitterFrequenciesKHz)..shuffle(_rng)),
    ]..shuffle(_rng);
  }

  @override
  TeslaTask generateTask(int round) {
    final kind = TeslaTaskKind.values[round % 3];
    final repeat = (round ~/ 3) % 2;
    return switch (kind) {
      TeslaTaskKind.generator => _generatorPlan[repeat],
      TeslaTaskKind.transmission => _transmissionPlan[repeat],
      TeslaTaskKind.wireless => _wirelessPlan[repeat],
    };
  }

  // ─────────────────────────── Keşif ───────────────────────────

  @override
  void resetExplore() {
    station = TeslaStation.generator;
    source = PowerSource.generator;
    turnsPerSecond = 1;
    distanceKm = 10;
    secondaryTurns = primaryTurns;
    coilOn = false;
    transmitterKHz = 200;
    receiverKHz = 120;
    lampDistanceM = 1;
  }

  void setStation(TeslaStation value) {
    if (station == value) return;
    station = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void setSource(PowerSource value) {
    source = value;
    playSound(ScienceSound.click);
    notifyListeners();
  }

  void setSpeed(double value) {
    turnsPerSecond = value.clamp(0, maxTurnsPerSecond).toDouble();
    notifyListeners();
  }

  void setDistance(double km) {
    distanceKm = km;
    notifyListeners();
  }

  void setSecondaryTurns(int turns) {
    if (turns != secondaryTurns) playSound(ScienceSound.click);
    secondaryTurns = turns;
    notifyListeners();
  }

  void setCoil(bool on) {
    coilOn = on;
    playSound(on ? ScienceSound.zap : ScienceSound.click);
    notifyListeners();
  }

  void setTransmitter(double kHz) {
    transmitterKHz = kHz;
    notifyListeners();
  }

  void setReceiver(double kHz) {
    receiverKHz = kHz.clamp(receiverMinKHz, receiverMaxKHz).toDouble();
    notifyListeners();
  }

  void setLampDistance(double m) {
    lampDistanceM = m.clamp(lampMinM, lampMaxM).toDouble();
    notifyListeners();
  }

  TeslaScene get _exploreScene => TeslaScene(
    station: station,
    source: source,
    turnsPerSecond: turnsPerSecond,
    distanceKm: distanceKm,
    secondaryTurns: secondaryTurns,
    coilOn: coilOn,
    transmitterKHz: transmitterKHz,
    receiverKHz: receiverKHz,
    lampDistanceM: lampDistanceM,
  );
}
