import 'mass_energy.dart';
import 'spacetime.dart';

enum EinsteinStation {
  sheet('Uzay-Zaman'),
  clock('Işık Saati'),
  energy('E=mc²');

  const EinsteinStation(this.label);
  final String label;
}

/// 3B ve 2B görünümlerin çizdiği **saf veri**. [run] değişince görünüm
/// deneyi baştan oynatır (bilye fırlatılır, yıllar akar, şehir yanar).
class EinsteinScene {
  const EinsteinScene({
    required this.station,
    this.center = CentralMass.sun,
    this.speed = LaunchSpeed.medium,
    this.shipSpeed = 0.8,
    this.earthYears = 10,
    this.grams = 1,
    this.run = 0,
  });

  final EinsteinStation station;

  final CentralMass center;
  final LaunchSpeed speed;

  /// Geminin hızı (ışık hızının kesri) ve deneyde Dünya'da geçen yıl.
  final double shipSpeed;
  final double earthYears;

  final double grams;

  final int run;

  MarbleRun get marble => simulateMarble(center, speed);
  int get housesLit => cityHousesLit(grams);
}
