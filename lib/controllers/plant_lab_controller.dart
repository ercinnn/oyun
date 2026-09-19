import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/plant_catalog.dart';
import '../models/plant_conditions.dart';
import '../models/plant_growth.dart';
import '../models/plant_lab_game_phase.dart';
import '../models/plant_lab_player_state.dart';
import '../models/plant_lab_trial.dart';
import '../models/plant_species.dart';

/// Her oyuncunun oynadığı tur sayısı. Diğer tur tabanlı oyunların sabitleriyle
/// aynı adı kullanmıyoruz (test/widget_test.dart hepsini birlikte import eder;
/// aynı ad "ambiguous import" hatası verir).
const int plantLabRoundsPerPlayer = 8;

/// Bir deney turunda iki bitkinin 10. haftadaki boy farkının, bitkinin ideal
/// boyuna oranla en az ne kadar olacağı. Fark bundan küçükse çocuğun tahmini
/// gözle ayırt edilemez; böyle çiftler üretilmez.
const double _minHeightGapRatio = 0.12;

/// Bitki Laboratuvarı'nın durum makinesi.
///
/// Çarpım Bahçesi gibi **tamamen senkron**: hiç `Future.delayed` yok, bu yüzden
/// `_generation`/`_resolving` korumasına gerek yok. Cevaptan sonra tur kendi
/// kendine ilerlemez; [showingResult] true olur ve oyuncu "Devam"a
/// ([continueAfterResult]) basana kadar sonuç paneli ekranda kalır — asıl öğretici
/// kısım gözlem ve açıklama, onu okumak zaman ister. Zaman atlamalı büyüme
/// animasyonu tamamen sunum katmanındadır (`PlantComparisonPanel`).
///
/// İki mod vardır: puanlı **görevler** ([startGame]) ve puansız, tek kişilik
/// **serbest laboratuvar** ([startFreeLab]).
class PlantLabController extends ChangeNotifier {
  PlantLabController({Random? random}) : _rng = random ?? Random() {
    _factorOffset = _rng.nextInt(PlantFactor.values.length);
    freeSpecies = plantCatalog.first;
    freePotA = freeSpecies.idealConditions;
    freePotB = freeSpecies.idealConditions;
  }

  PlantLabPhase phase = PlantLabPhase.setup;
  List<PlantLabPlayerState> players = [];
  int currentPlayerIndex = 0;
  late PlantLabTrial currentTrial;

  /// Cevap verildikten sonra sonuç paneli gösterilirken true.
  bool showingResult = false;
  bool lastAnswerCorrect = false;
  PlantPrediction? lastPrediction;
  PlantFactor? lastDiagnosis;

  // Serbest laboratuvar durumu.
  late PlantSpecies freeSpecies;
  late PlantConditions freePotA;
  late PlantConditions freePotB;
  bool freeStarted = false;

  /// Her "Deneyi başlat"ta artar; gözlem panelinin animasyonu buna bağlı
  /// bir anahtarla baştan başlar.
  int freeRunCount = 0;

  final Random _rng;
  late final int _factorOffset;

  PlantLabPlayerState get currentPlayer => players[currentPlayerIndex];

  List<PlantLabPlayerState> get rankedByCorrect {
    final sorted = List<PlantLabPlayerState>.from(players);
    sorted.sort((a, b) => b.correctCount.compareTo(a.correctCount));
    return sorted;
  }

  /// Serbest laboratuvarda iki saksının farklı olduğu etkenler. Tam bir tane
  /// ise adil deney; birden çoksa fark hangisinden geldiği bilinemez.
  List<PlantFactor> get freeDifferingFactors =>
      freePotA.differingFactors(freePotB);

  // ─────────────────────────── Görevler ───────────────────────────

  void startGame(List<String> names) {
    players = names.map((name) => PlantLabPlayerState(name: name)).toList();
    currentPlayerIndex = 0;
    _clearResult();
    currentTrial = _generateTrial();
    phase = PlantLabPhase.playing;
    notifyListeners();
  }

  /// Deney turunda bir tahmin seçildi.
  void answerPrediction(PlantPrediction prediction) {
    if (phase != PlantLabPhase.playing || showingResult) return;
    if (currentTrial.kind != PlantLabTrialKind.experiment) return;

    lastPrediction = prediction;
    _recordAnswer(correct: prediction == currentTrial.outcome);
  }

  /// Doktor turunda bir etken seçildi.
  void answerDoctor(PlantFactor factor) {
    if (phase != PlantLabPhase.playing || showingResult) return;
    if (currentTrial.kind != PlantLabTrialKind.doctor) return;

    lastDiagnosis = factor;
    _recordAnswer(correct: factor == currentTrial.factor);
  }

  /// Sonuç panelindeki "Devam"a basıldı: sıradaki tura, sıra devrine ya da
  /// sonuç ekranına geçilir.
  void continueAfterResult() {
    if (!showingResult) return;
    _clearResult();

    if (currentPlayer.roundsPlayed >= plantLabRoundsPerPlayer) {
      final nextIndex = _findNextUnfinishedPlayerIndex();
      if (nextIndex == null) {
        phase = PlantLabPhase.finished;
        notifyListeners();
        return;
      }
      currentPlayerIndex = nextIndex;
      phase = PlantLabPhase.turnTransition;
    }

    currentTrial = _generateTrial();
    notifyListeners();
  }

  void acknowledgeTurnTransition() {
    phase = PlantLabPhase.playing;
    notifyListeners();
  }

  void restart() {
    players = [];
    currentPlayerIndex = 0;
    _clearResult();
    freeStarted = false;
    phase = PlantLabPhase.setup;
    notifyListeners();
  }

  // ─────────────────────── Serbest laboratuvar ───────────────────────

  void startFreeLab() {
    freeSpecies = plantCatalog.first;
    freePotA = freeSpecies.idealConditions;
    freePotB = freeSpecies.idealConditions;
    freeStarted = false;
    phase = PlantLabPhase.freeLab;
    notifyListeners();
  }

  /// Bitki değişince iki saksı da o bitkinin ideal koşullarına döner.
  void setFreeSpecies(PlantSpecies species) {
    freeSpecies = species;
    freePotA = species.idealConditions;
    freePotB = species.idealConditions;
    freeStarted = false;
    notifyListeners();
  }

  void setFreeCondition({
    required bool potA,
    required PlantFactor factor,
    required int level,
  }) {
    if (potA) {
      freePotA = freePotA.withLevel(factor, level);
    } else {
      freePotB = freePotB.withLevel(factor, level);
    }
    freeStarted = false;
    notifyListeners();
  }

  void runFreeExperiment() {
    freeStarted = true;
    freeRunCount++;
    notifyListeners();
  }

  // ───────────────────────────── İç işler ─────────────────────────────

  void _clearResult() {
    showingResult = false;
    lastAnswerCorrect = false;
    lastPrediction = null;
    lastDiagnosis = null;
  }

  void _recordAnswer({required bool correct}) {
    lastAnswerCorrect = correct;
    if (correct) currentPlayer.correctCount++;
    currentPlayer.roundsPlayed++;
    showingResult = true;
    notifyListeners();
  }

  PlantLabTrial _generateTrial() {
    // Tur tipi dönüşümlü: 1./3./5./7. tur deney, 2./4./6./8. tur doktor.
    final round = currentPlayer.roundsPlayed;
    final species = plantCatalog[_rng.nextInt(plantCatalog.length)];
    return round.isEven
        ? _experimentTrial(species, round ~/ 2)
        : _doctorTrial(species);
  }

  /// Deney turu: iki saksı yalnızca test edilen etkende farklıdır. Etken
  /// dönüşümlü seçilir (`pairIndex + _factorOffset`), böylece bir oyuncu dört
  /// deneyde ışığı, suyu, sıcaklığı ve yüksekliği birer kez görür.
  PlantLabTrial _experimentTrial(PlantSpecies species, int pairIndex) {
    final factor =
        PlantFactor.values[(pairIndex + _factorOffset) %
            PlantFactor.values.length];
    final ideal = species.idealConditions;
    final minGap = species.maxHeightCm * _minHeightGapRatio;

    double finalHeight(PlantConditions c) =>
        simulatePlant(species, c, plantExperimentWeeks.toDouble()).heightCm;

    for (var attempt = 0; attempt < 50; attempt++) {
      final levelA = _rng.nextInt(plantLevelCount);
      final levelB = _rng.nextInt(plantLevelCount);
      if (levelA == levelB) continue;
      final a = ideal.withLevel(factor, levelA);
      final b = ideal.withLevel(factor, levelB);
      if ((finalHeight(a) - finalHeight(b)).abs() >= minGap) {
        return PlantLabTrial(
          kind: PlantLabTrialKind.experiment,
          species: species,
          factor: factor,
          potA: a,
          potB: b,
        );
      }
    }

    // Şans yardım etmezse (çok düşük olasılık) en kötü kademe ile ideali karşılaştır.
    final scores = species.scoresOf(factor);
    var worst = 0;
    for (var level = 1; level < scores.length; level++) {
      if (scores[level] < scores[worst]) worst = level;
    }
    return PlantLabTrial(
      kind: PlantLabTrialKind.experiment,
      species: species,
      factor: factor,
      potA: ideal.withLevel(factor, worst),
      potB: ideal,
    );
  }

  /// Doktor turu: yalnızca tek bir etken bozuktur, böylece doğru cevap
  /// belirsizlik bırakmaz.
  PlantLabTrial _doctorTrial(PlantSpecies species) {
    final factor = PlantFactor.values[_rng.nextInt(PlantFactor.values.length)];
    final idealLevel = species.idealLevelOf(factor);
    final broken = [
      for (var level = 0; level < plantLevelCount; level++)
        if (level != idealLevel && species.scoreOf(factor, level) <= 0.5)
          level,
    ];
    // Boş kalırsa (yeni bir bitki tablosu eklenip gözden kaçarsa) en düşük
    // skorlu kademeye düşülür; tur asla üretilemeden kilitlenmez.
    final level = broken.isNotEmpty
        ? broken[_rng.nextInt(broken.length)]
        : _lowestLevel(species, factor);

    final ideal = species.idealConditions;
    return PlantLabTrial(
      kind: PlantLabTrialKind.doctor,
      species: species,
      factor: factor,
      potA: ideal.withLevel(factor, level),
      potB: ideal,
    );
  }

  int _lowestLevel(PlantSpecies species, PlantFactor factor) {
    final scores = species.scoresOf(factor);
    var lowest = 0;
    for (var level = 1; level < scores.length; level++) {
      if (scores[level] < scores[lowest]) lowest = level;
    }
    return lowest;
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (currentPlayerIndex + offset) % players.length;
      if (players[index].roundsPlayed < plantLabRoundsPerPlayer) return index;
    }
    return null;
  }
}
