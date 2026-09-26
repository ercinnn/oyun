/// Marie Curie'nin radyoaktivitesi — Geiger sayacı, saf model.
///
/// Bazı maddelerin atomları kendiliğinden görünmez ışınlar yayar. Sayaç her
/// ışını bir "tık" olarak sayar. Hiçbir şey yokken bile doğadan gelen birkaç
/// tık duyulur (arka plan). Işıma kaynaktan her yöne yayıldığı için sayaç
/// uzaklaştıkça tıklar hızla azalır: uzaklık 2 katına çıkınca 4'te 1'e iner
/// (ters kare kuralı).
///
/// Curie, uranyum cevherinin (zift blendi) saf uranyumdan daha çok ışıdığını
/// ölçtü ve içinde bilinmeyen, çok daha güçlü elementler olduğunu anladı:
/// polonyum ve radyum. Değerler oyun için sadeleştirilmiştir.
library;

import '../science/science_task.dart' show formatTr;

/// Hiç numune yokken sayacın saydığı (tık/sn).
const double backgroundCps = 0.5;

/// Numunenin ölçüm değerlerinin verildiği uzaklık (cm).
const double referenceDistanceCm = 10;

/// Sayacın uzaklık kaydırıcısı (cm).
const double counterMinCm = 5;
const double counterMaxCm = 50;

/// Bu hızın üstü "ışıma yapıyor" sayılır (tık/sn, 10 cm'de).
const double radioactiveThresholdCps = 3;

class RadioSample {
  const RadioSample({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cpsAt10cm,
    required this.note,
    this.glows = false,
  });

  /// Kimlik; 3B modeldeki grup adı `curie_sample_<id>`.
  final String id;
  final String name;
  final String emoji;

  /// 10 cm'de ölçülen tık/sn (arka plan hariç).
  final double cpsAt10cm;
  final String note;

  /// Karanlıkta hafifçe parlar mı (radyum tuzları parlar).
  final bool glows;

  String get modelId => 'curie_sample_$id';

  bool get radioactive => cpsAt10cm >= radioactiveThresholdCps;
}

/// [d] cm uzaklıktaki sayım (tık/sn), arka plan dahil.
double countsPerSecond(RadioSample? sample, double distanceCm) {
  if (sample == null) return backgroundCps;
  final r = referenceDistanceCm / distanceCm;
  return backgroundCps + sample.cpsAt10cm * r * r;
}

/// Uzaklık [from]'dan [to]'ya çıkınca (arka plan hariç) sayım kaç katına iner.
double inverseSquareFactor(double fromCm, double toCm) =>
    (fromCm / toCm) * (fromCm / toCm);

/// Tık hızını okunaklı yazar: 10'un altında bir ondalıkla (0,5), üstünde tam
/// sayı. (Tam sayıya yuvarlamak arka plandaki 0,5'i "1" gösteriyordu.)
String formatCps(double cps) => formatTr(cps, digits: cps < 10 ? 1 : 0);
