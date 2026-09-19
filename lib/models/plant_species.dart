import 'plant_conditions.dart';

/// Bitkinin çizim biçimi (bkz. `widgets/plant_view.dart`).
enum PlantShape { leafy, grass, cactus }

/// Laboratuvarda denenen gerçek bir bitki. Her etken için üç kademelik
/// "uygunluk skoru" (0-1) taşır: 1.0 en uygun, 0'a yakın en kötü kademe.
/// Büyüme modeli (bkz. `plant_growth.dart`) yalnızca bu skorlardan çalışır,
/// bu yüzden bitki bilgisini düzeltmek için tek bir veri satırını değiştirmek
/// yeterlidir (bkz. `data/plant_catalog.dart`).
class PlantSpecies {
  const PlantSpecies({
    required this.id,
    required this.name,
    required this.emoji,
    required this.shape,
    required this.maxHeightCm,
    required this.lightScores,
    required this.waterScores,
    required this.temperatureScores,
    required this.altitudeScores,
    required this.lightNote,
    required this.waterNote,
    required this.temperatureNote,
    required this.altitudeNote,
    required this.funFact,
  });

  final String id;
  final String name;
  final String emoji;
  final PlantShape shape;

  /// İdeal koşullarda 10. haftada ulaşılan boy (zaman atlamalı deney).
  final double maxHeightCm;

  final List<double> lightScores;
  final List<double> waterScores;
  final List<double> temperatureScores;
  final List<double> altitudeScores;

  /// Her etken için elle yazılmış açıklama cümlesi (yükseklik dahil). Değişken bir kelimeye ek
  /// getirilmez (bkz. CLAUDE.md, Simon/Çarpım Bahçesi cümle kuralı): cümleler
  /// bitkinin adıyla başlar ya da adsız yazılır.
  final String lightNote;
  final String waterNote;
  final String temperatureNote;
  final String altitudeNote;

  final String funFact;

  List<double> scoresOf(PlantFactor factor) => switch (factor) {
    PlantFactor.light => lightScores,
    PlantFactor.water => waterScores,
    PlantFactor.temperature => temperatureScores,
    PlantFactor.altitude => altitudeScores,
  };

  double scoreOf(PlantFactor factor, int level) => scoresOf(factor)[level];

  String noteOf(PlantFactor factor) => switch (factor) {
    PlantFactor.light => lightNote,
    PlantFactor.water => waterNote,
    PlantFactor.temperature => temperatureNote,
    PlantFactor.altitude => altitudeNote,
  };

  /// Bu etken için en yüksek skorlu kademe.
  int idealLevelOf(PlantFactor factor) {
    final scores = scoresOf(factor);
    var best = 0;
    for (var level = 1; level < scores.length; level++) {
      if (scores[level] > scores[best]) best = level;
    }
    return best;
  }

  /// Dört etkenin de en uygun olduğu koşullar.
  PlantConditions get idealConditions => PlantConditions(
    light: idealLevelOf(PlantFactor.light),
    water: idealLevelOf(PlantFactor.water),
    temperature: idealLevelOf(PlantFactor.temperature),
    altitude: idealLevelOf(PlantFactor.altitude),
  );

  /// Dört skorun çarpımı: herhangi bir etken kötüyse bitki toplamda zorlanır.
  double overallScore(PlantConditions conditions) =>
      scoreOf(PlantFactor.light, conditions.light) *
      scoreOf(PlantFactor.water, conditions.water) *
      scoreOf(PlantFactor.temperature, conditions.temperature) *
      scoreOf(PlantFactor.altitude, conditions.altitude);
}
