/// Fleming'in petri kabı — saf ve deterministik model.
///
/// 1928'de Alexander Fleming tatilden döndüğünde, bakteri ektiği bir kapta
/// küf ürediğini gördü. Küfün çevresinde bakteriler ölmüş, temiz bir halka
/// oluşmuştu: küf (Penicillium) bakterileri öldüren bir madde salgılıyordu.
/// Fleming ona penisilin adını verdi — ilk antibiyotik.
///
/// Kap birim çember; koloniler sabit tohumlu rastgele noktalardır (hep aynı
/// yerde çıkarlar). Koloniler günle büyür; küf 1. günden itibaren çevresine
/// penisilin yayar ve temiz halka günle genişler. Merkezi halkanın içinde
/// kalan koloni büyüyemez.
library;

import 'dart:math';

/// Kaptaki koloni sayısı (küfsüz kapta hepsi büyür).
const int petriColonyCount = 42;

/// Keşifte ilerletilebilen en çok gün.
const int petriMaxDays = 7;

/// Küfün kaptaki yeri (kap yarıçapı 1).
const double moldX = 0.3;
const double moldY = 0.15;

class Colony {
  const Colony(this.x, this.y, this.growth);

  final double x;
  final double y;

  /// Büyüme hızı çarpanı (koloniler biraz farklı büyür).
  final double growth;
}

/// Hep aynı koloni yerleri (tohum 1928: keşif yılı).
final List<Colony> petriColonies = () {
  final rng = Random(1928);
  final out = <Colony>[];
  while (out.length < petriColonyCount) {
    final x = rng.nextDouble() * 2 - 1;
    final y = rng.nextDouble() * 2 - 1;
    if (x * x + y * y > 0.8 * 0.8) continue;
    out.add(Colony(x, y, 0.8 + rng.nextDouble() * 0.4));
  }
  return out;
}();

/// Koloninin [day]. gündeki yarıçapı (kap yarıçapına göre).
double colonyRadius(Colony c, double day) =>
    min(0.085, 0.017 * day * c.growth);

/// Küfün yarıçapı (1. günden sonra görünür).
double moldRadius(double day) => day < 1 ? 0 : min(0.16, 0.05 + 0.018 * day);

/// Penisilinin bakteri büyütmeyen temiz halkasının yarıçapı.
double inhibitionRadius(double day) => day < 1 ? 0 : min(0.45, 0.09 * day);

/// Koloni küfün temiz halkasında mı (büyüyemez)?
bool colonyBlocked(Colony c, double day, {required bool mold}) {
  if (!mold) return false;
  final dx = c.x - moldX, dy = c.y - moldY;
  return sqrt(dx * dx + dy * dy) < inhibitionRadius(day);
}

/// [day]. günde büyüyen koloni sayısı.
int livingColonies(double day, {required bool mold}) {
  if (day <= 0) return 0;
  return petriColonies.where((c) => !colonyBlocked(c, day, mold: mold)).length;
}
