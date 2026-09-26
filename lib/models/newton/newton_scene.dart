import 'cart.dart';
import 'falling.dart';
import 'prism.dart';

enum NewtonStation {
  fall('Düşme Kulesi'),
  prism('Prizma'),
  cart('İtme Pisti');

  const NewtonStation(this.label);
  final String label;
}

/// 3B ve 2B görünümlerin çizdiği **saf veri**. Deneyler zamana bağlıdır:
/// [run] 0 iken cisimler kulede / arabalar yayın önünde bekler; [run]
/// değişince görünüm kendi saatini sıfırlayıp deneyi baştan oynatır ve
/// konumları modelden (`fallDistance`, `cartPositionAt`) okur.
class NewtonScene {
  const NewtonScene({
    required this.station,
    this.fallA,
    this.fallB,
    this.environment = FallEnvironment.air,
    this.light = LightSource.white,
    this.secondPrism = false,
    this.laneA = const CartLane(),
    this.laneB,
    this.push = PushStrength.medium,
    this.run = 0,
  });

  final NewtonStation station;

  final FallingObject? fallA;
  final FallingObject? fallB;
  final FallEnvironment environment;

  final LightSource light;
  final bool secondPrism;

  final CartLane laneA;

  /// İkinci pist (karşılaştırma); yoksa tek araba.
  final CartLane? laneB;
  final PushStrength push;

  /// 0: deney başlamadı. Her yeni değer deneyi baştan oynatır.
  final int run;

  PrismOutcome get prism => prismOutcome(light, secondPrism: secondPrism);

  /// Deneyin tamamlanma süresi (s); 2B görünümün animasyon uzunluğu.
  double get duration => switch (station) {
    NewtonStation.fall => [
      0.0,
      if (fallA != null) fallTime(fallA!, environment),
      if (fallB != null) fallTime(fallB!, environment),
    ].reduce((a, b) => a > b ? a : b),
    NewtonStation.prism => 1.2,
    NewtonStation.cart => [
      cartTravelTime(laneA, push),
      if (laneB != null) cartTravelTime(laneB!, push),
    ].reduce((a, b) => a > b ? a : b),
  };
}
