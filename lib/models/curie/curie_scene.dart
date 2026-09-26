import 'geiger.dart';
import 'shielding.dart';
import 'therapy.dart';

enum CurieStation {
  geiger('Sayaçla Keşif'),
  shield('Kalkanlar'),
  therapy('Işınla Tedavi');

  const CurieStation(this.label);
  final String label;
}

/// 3B ve 2B görünümlerin çizdiği **saf veri**.
class CurieScene {
  const CurieScene({
    required this.station,
    this.sample,
    this.distanceCm = referenceDistanceCm,
    this.ray = RayType.alpha,
    this.shield = Shield.none,
    this.beams = const [],
    this.beamsOn = false,
  });

  final CurieStation station;

  /// Sayacın tuttuğu numune (yoksa sayaç boşta, yalnızca arka plan).
  final RadioSample? sample;
  final double distanceCm;

  final RayType ray;
  final Shield shield;

  /// Tedavi planı ve ışınların açık olup olmadığı (kapalıyken doz haritası
  /// boş gösterilir).
  final List<Beam> beams;
  final bool beamsOn;

  double get geigerCps => countsPerSecond(sample, distanceCm);
  double get shieldCps => shieldedCps(ray, shield);
  DoseMap get dose => computeDose(beamsOn ? beams : const []);
}
