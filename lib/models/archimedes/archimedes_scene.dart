import 'boat.dart';
import 'buoyancy.dart';

/// Atölyedeki istasyonlar. Kalın çizgiyle ayrılmış, kamera istasyondan
/// istasyona kayar.
enum ArchimedesStation {
  tank('Su Kabı'),
  boat('Gemi'),
  screw('Arşimet Vidası');

  const ArchimedesStation(this.label);
  final String label;
}

/// Bir deney kabı: üstünde tutulan (henüz bırakılmamış) cisim ve suyun içine
/// bırakılmış cisimler. [brimFull] kap ağzına kadar doludur; bırakılan cisim
/// seviyeyi yükseltmek yerine suyu önündeki ölçü kabına taşırır (taç deneyi).
class TankState {
  const TankState({
    this.held,
    this.dropped = const [],
    this.brimFull = false,
    this.label,
  });

  final BuoyancyObject? held;
  final List<BuoyancyObject> dropped;
  final bool brimFull;

  /// Karşılaştırmalı görevlerde kabın altındaki harf ("A", "B").
  final String? label;

  double get waterLevelCm =>
      brimFull ? tankHeightCm : tankWaterLevelCm(dropped);

  double get overflowMl => brimFull ? overflowCm3(dropped) : 0;
}

/// 3B ve 2B görünümlerin çizdiği **saf veri**. Görünüm bu duruma doğru
/// yumuşakça ilerler (cisim düşer, su yükselir, vida döner); mantık hiçbir
/// animasyon beklemez.
class ArchimedesScene {
  const ArchimedesScene({
    required this.station,
    this.tanks = const [TankState()],
    this.boat,
    this.crates = 0,
    this.screwAngle = 30,
    this.screwTurns = 0,
    this.fieldLitres = 0,
    this.revision = 0,
  });

  final ArchimedesStation station;
  final List<TankState> tanks;
  final BoatSpec? boat;
  final int crates;

  /// Derece.
  final double screwAngle;

  /// Vidanın toplam dönüşü (tur); görünüm vidayı bu değere doğru döndürür.
  final double screwTurns;
  final double fieldLitres;

  /// Her anlamlı değişimde artar; 2B görünüm düşme animasyonunu buna bağlı
  /// bir anahtarla baştan başlatır.
  final int revision;
}
