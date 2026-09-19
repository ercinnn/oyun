import 'plant_conditions.dart';
import 'plant_growth.dart';
import 'plant_species.dart';

enum PlantLabTrialKind {
  /// İki saksıyı karşılaştır, hangisinin daha çok büyüyeceğini tahmin et.
  experiment,

  /// Hasta bir bitkinin hangi koşulunun düzeltilmesi gerektiğini bul.
  doctor,
}

/// Görev modunun bir turu.
///
/// * [PlantLabTrialKind.experiment]: [potA] ve [potB] yalnızca [factor]'de
///   farklıdır (adil deney); diğer iki etken bitkinin ideal kademesindedir.
/// * [PlantLabTrialKind.doctor]: [potA] hasta bitkidir (yalnızca [factor]
///   bozuk), [potB] o etkeni düzeltilmiş hâlidir.
class PlantLabTrial {
  const PlantLabTrial({
    required this.kind,
    required this.species,
    required this.factor,
    required this.potA,
    required this.potB,
  });

  final PlantLabTrialKind kind;
  final PlantSpecies species;
  final PlantConditions potA;
  final PlantConditions potB;

  /// Deneyde test edilen, doktor turunda bozuk olan etken.
  final PlantFactor factor;

  /// Deney turunun doğru cevabı.
  PlantPrediction get outcome => plantOutcome(species, potA, potB);

  /// Doktor turunda hasta bitkinin belirtisi. Cümleler elle yazılmıştır.
  String get symptom {
    final tooLow = potA.levelOf(factor) < species.idealLevelOf(factor);
    return switch (factor) {
      PlantFactor.light =>
        tooLow
            ? 'Yaprakları soluk yeşil, gövdesi ince ve cılız.'
            : 'Yaprak uçları kahverengi, yanmış gibi.',
      PlantFactor.water =>
        tooLow
            ? 'Yaprakları sarkık, toprağı çatlamış ve kupkuru.'
            : 'Yaprakları sararmış, toprağı çamur gibi ıslak.',
      PlantFactor.temperature =>
        tooLow
            ? 'Neredeyse hiç büyümemiş, yaprakları küçük kalmış.'
            : 'Yaprakları buruşmuş ve kıvrılmış.',
    };
  }

  /// Cevaptan sonra gösterilen açıklama.
  String get explanation {
    if (kind == PlantLabTrialKind.doctor) {
      return 'Doğru cevap: ${factor.label}. ${species.noteOf(factor)} '
          'Bu koşul düzelince bitki toparlandı.';
    }
    final winner = switch (outcome) {
      PlantPrediction.a => 'A saksısındaki bitki daha çok büyüdü.',
      PlantPrediction.b => 'B saksısındaki bitki daha çok büyüdü.',
      PlantPrediction.same => 'İki bitki aynı boyda kaldı.',
    };
    final healthA = simulatePlant(
      species,
      potA,
      plantExperimentDays.toDouble(),
    ).health;
    final healthB = simulatePlant(
      species,
      potB,
      plantExperimentDays.toDouble(),
    ).health;
    return '$winner ${species.noteOf(factor)} '
        'A: ${healthA.label}. B: ${healthB.label}. '
        'Bu deneyde yalnızca ${factor.lowerLabel} farklıydı; bu yüzden '
        'farkın nedeni ${factor.lowerLabel}.';
  }
}
