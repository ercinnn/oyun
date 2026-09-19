import 'dart:math';

import 'plant_conditions.dart';
import 'plant_species.dart';

/// Bir deneyin süresi (hafta). Zaman atlamalıdır: çocuk 0-10. haftayı
/// kaydırıcıyla gezer. "Gün" değil "hafta" denir ki ayçiçeğinin 100 cm'ye
/// ulaşması gerçekçi dursun. [PlantSnapshot.day] ve `day` parametreleri de
/// bu birimde (hafta) tutulur.
const int plantExperimentWeeks = 10;

/// Bitkinin görünen sağlık durumu.
enum PlantHealth {
  healthy('Sağlıklı'),
  slow('Yavaş büyüyor'),
  pale('Soluk ve cılız'),
  wilted('Solmuş'),
  rotting('Yaprakları sararmış'),
  scorched('Yaprakları yanmış'),
  weak('Cılız');

  const PlantHealth(this.label);
  final String label;

  /// Bu görünümün çocuğa yönelik kısa nedeni.
  String get reason => switch (this) {
    PlantHealth.healthy => 'Yaprakları yeşil ve dik.',
    PlantHealth.slow => 'Soğukta bitki çok yavaş gelişir.',
    PlantHealth.pale =>
      'Işık yetmeyince yaprak besin yapamaz; bitki soluk ve zayıf kalır.',
    PlantHealth.wilted =>
      'Susuz ya da çok sıcakta kalan bitkinin yaprakları sarkar.',
    PlantHealth.rotting =>
      'Çok su köklerin nefes almasını engeller; yapraklar sararır.',
    PlantHealth.scorched => 'Fazla ışık ya da sıcak yaprak uçlarını yakar.',
    PlantHealth.weak =>
      'Bulunduğu yükseklik bitkiye uygun değil; büyümesi cılız kalır.',
  };
}

/// Deneyin belli bir haftadaki görüntüsü.
class PlantSnapshot {
  const PlantSnapshot({
    required this.day,
    required this.heightCm,
    required this.leafCount,
    required this.vigor,
    required this.health,
  });

  final double day;
  final double heightCm;
  final int leafCount;

  /// 0-1: bitkinin canlılığı (1 = tam sağlıklı).
  final double vigor;
  final PlantHealth health;
}

/// Tahmin sorusunun olası cevapları.
enum PlantPrediction { a, b, same }

/// [conditions] altındaki [species]'ın [day]. haftadaki durumu.
///
/// Saf ve deterministiktir: rastgelelik yok, aynı girdi hep aynı sonucu verir
/// (testler ve "aynı deney tekrar edilirse aynı sonuç çıkar" fikri için).
/// Büyüme, dört uygunluk skorunun çarpımından ([PlantSpecies.overallScore])
/// türetilir; görünüm ise en zayıf etkene bakılarak seçilir.
PlantSnapshot simulatePlant(
  PlantSpecies species,
  PlantConditions conditions,
  double day,
) {
  final d = day.clamp(0.0, plantExperimentWeeks.toDouble()).toDouble();
  final overall = species.overallScore(conditions);
  const rate = 0.3;
  final progress =
      (1 - exp(-rate * d)) / (1 - exp(-rate * plantExperimentWeeks));
  final growth = pow(overall, 0.6).toDouble();

  final heightCm = 1 + (species.maxHeightCm - 1) * growth * progress;
  final leafCount = 2 + (growth * progress * 6).round();
  final stress = (1 - sqrt(overall)) * min(1.0, d / 5);

  return PlantSnapshot(
    day: d,
    heightCm: heightCm,
    leafCount: leafCount,
    vigor: 1 - stress,
    // İlk haftalarda bitki henüz "sorunlu" görünmez; belirtiler birkaç haftada çıkar.
    health: d >= 3 ? _healthOf(species, conditions, overall) : PlantHealth.healthy,
  );
}

PlantHealth _healthOf(
  PlantSpecies species,
  PlantConditions conditions,
  double overall,
) {
  if (overall >= 0.6) return PlantHealth.healthy;

  var worst = PlantFactor.light;
  var worstScore = double.infinity;
  for (final factor in PlantFactor.values) {
    final score = species.scoreOf(factor, conditions.levelOf(factor));
    if (score < worstScore) {
      worst = factor;
      worstScore = score;
    }
  }

  final tooLow =
      conditions.levelOf(worst) < species.idealLevelOf(worst);
  return switch (worst) {
    PlantFactor.light => tooLow ? PlantHealth.pale : PlantHealth.scorched,
    PlantFactor.water => tooLow ? PlantHealth.wilted : PlantHealth.rotting,
    PlantFactor.temperature => tooLow ? PlantHealth.slow : PlantHealth.wilted,
    PlantFactor.altitude => PlantHealth.weak,
  };
}

/// İki saksının [plantExperimentWeeks]. haftadaki boylarına göre hangisi daha
/// çok büyüdü. Fark yarım santimetreden azsa "aynı" sayılır.
PlantPrediction plantOutcome(
  PlantSpecies species,
  PlantConditions a,
  PlantConditions b,
) {
  final heightA = simulatePlant(
    species,
    a,
    plantExperimentWeeks.toDouble(),
  ).heightCm;
  final heightB = simulatePlant(
    species,
    b,
    plantExperimentWeeks.toDouble(),
  ).heightCm;
  if ((heightA - heightB).abs() < 0.5) return PlantPrediction.same;
  return heightA > heightB ? PlantPrediction.a : PlantPrediction.b;
}

/// "12,3" biçiminde (virgüllü) santimetre.
String formatCm(double value) => value.toStringAsFixed(1).replaceAll('.', ',');
