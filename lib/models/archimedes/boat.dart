import 'buoyancy.dart';

/// Bir sandığın kütlesi (g). Bütün gemilerde aynı: çocuk yalnızca geminin
/// büyüklüğünü karşılaştırsın.
const double crateMassG = 300;

/// Yük taşıyan bir gemi. Gemi, gövdesinin su altında kalan kısmı kadar su
/// iter; toplam ağırlık gövdenin **tamamının** itebileceği sudan fazla olursa
/// su küpeşteden içeri dolar ve gemi batar.
class BoatSpec {
  const BoatSpec({
    required this.id,
    required this.name,
    required this.emoji,
    required this.massG,
    required this.hullVolumeCm3,
    required this.hullHeightCm,
  });

  final String id;
  final String name;
  final String emoji;
  final double massG;

  /// Gövdenin kapladığı toplam hacim (içindeki hava dahil).
  final double hullVolumeCm3;
  final double hullHeightCm;

  /// Gövdenin taban alanı (düz duvarlı kutu gemi varsayımı).
  double get hullAreaCm2 => hullVolumeCm3 / hullHeightCm;

  double totalMassG(int crates) => massG + crates * crateMassG;

  /// Batmadan taşıyabileceği en çok sandık.
  int get maxCrates => ((hullVolumeCm3 - massG) / crateMassG).floor();

  bool sinks(int crates) => totalMassG(crates) / waterDensity > hullVolumeCm3;

  /// Suya gömülme derinliği (cm); batınca gövde yüksekliğine eşit.
  double draftCm(int crates) {
    final d = totalMassG(crates) / waterDensity / hullAreaCm2;
    return d > hullHeightCm ? hullHeightCm : d;
  }

  /// Gömülmenin gövdeye oranı (0-1); 3B/2B çizim bunu kullanır.
  double draftRatio(int crates) => draftCm(crates) / hullHeightCm;
}
