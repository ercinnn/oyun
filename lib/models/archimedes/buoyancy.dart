/// Arşimet'in kaldırma kuvveti — saf ve deterministik model.
///
/// Birimler ilkokul düzeyinde tutuldu: kütle **gram**, hacim **cm³**, suyun
/// yoğunluğu 1 g/cm³ (1 cm³ su = 1 g = 1 mL). Böylece "cisim, kapladığı yer
/// kadar suyu iter" cümlesi sayılarla birebir okunur.
library;

/// Suyun yoğunluğu (g/cm³).
const double waterDensity = 1.0;

/// Deney kabının taban alanı (cm²). 10 × 10 cm'lik bir kavanoz: 100 cm³
/// su ittiren bir cisim su seviyesini 1 cm yükseltir, çocuk için kolay oran.
const double tankAreaCm2 = 100;

/// Kaba başta konan suyun yüksekliği ve kabın kendi yüksekliği (cm).
const double tankStartWaterCm = 10;
const double tankHeightCm = 20;

/// Suya bırakılabilen bir cisim.
class BuoyancyObject {
  const BuoyancyObject({
    required this.id,
    required this.name,
    required this.emoji,
    required this.massG,
    required this.volumeCm3,
    required this.note,
  });

  /// Kimlik; 3B modeldeki grup adı `obj_<id>`.
  final String id;
  final String name;
  final String emoji;
  final double massG;

  /// Cismin dışarıdan kapladığı hacim. Oyun hamurundan kasede içindeki hava
  /// da dahildir — kasenin yüzmesinin nedeni tam olarak bu.
  final double volumeCm3;

  /// Sonuç panelinde gösterilen, elle yazılmış açıklama.
  final String note;

  String get modelId => 'obj_$id';

  /// g/cm³.
  double get density => massG / volumeCm3;

  /// Suyun yoğunluğundan hafifse yüzer.
  bool get floats => density < waterDensity;

  /// Suyun altında kalan kısmın oranı (0-1). Yüzen cisim kendi ağırlığı kadar
  /// su itene kadar batar: oran = yoğunluk / suyun yoğunluğu.
  double get submergedFraction => floats ? density / waterDensity : 1.0;

  /// İttiği su (cm³ = mL).
  double get displacedCm3 => volumeCm3 * submergedFraction;

  /// Bu cisim tek başına kaba bırakılınca su seviyesinin yükselişi (cm).
  double get waterRiseCm => displacedCm3 / tankAreaCm2;
}

/// Kaptaki cisimlerin hepsiyle su seviyesi (cm). Kabın ağzını aşamaz; aşan
/// kısım taşar (bkz. [overflowCm3]).
double tankWaterLevelCm(Iterable<BuoyancyObject> objects) {
  final level = tankStartWaterCm + totalDisplacedCm3(objects) / tankAreaCm2;
  return level > tankHeightCm ? tankHeightCm : level;
}

double totalDisplacedCm3(Iterable<BuoyancyObject> objects) =>
    objects.fold(0.0, (sum, o) => sum + o.displacedCm3);

/// Ağzına kadar dolu bir kaba bırakılan cisimlerin taşırdığı su (mL).
/// Arşimet'in taç deneyi tam olarak budur.
double overflowCm3(Iterable<BuoyancyObject> objects) =>
    totalDisplacedCm3(objects);
