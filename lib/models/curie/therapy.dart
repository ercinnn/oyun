/// Işınla tedavi — "çapraz ateş" ilkesi, saf model.
///
/// Doktorlar tümörü tek yönden güçlü bir ışınla değil, birçok yönden zayıf
/// ışınlarla ışınlar. Her ışın yolundaki sağlıklı dokuya biraz doz verir,
/// ama bütün ışınlar tümörde kesiştiği için tümör hepsinin toplamını alır.
/// Böylece tümör yüksek doz alırken sağlıklı doku korunur. Marie Curie'nin
/// radyumla yaptığı çalışmalar bu tedavilerin önünü açtı.
///
/// Vücut kesiti bir ızgaradır; tümör ortadadır. Işın, merkezden geçen ve
/// [beamHalfWidth] yarı genişlikli bir şerittir.
///
/// Sağlıklı doku ölçüsü tümörün çevresindeki **güvenlik payının dışında**
/// alınır ([safetyMarginRadius]): ışınların kesiştiği yerin hemen yanı her
/// planda yüksek doz alır (gerçek tedavide de tümörün çevresine bir pay
/// bırakılır); asıl fark, uzaktaki dokunun kaç ışından doz aldığıdır.
/// Ortalama doz bilerek kullanılmaz: toplam doz sabitken ortalama ışın
/// sayısından bağımsızdır.
library;

import 'dart:math';

const int therapyGrid = 21;
const double tumorRadius = 1.5;
const double bodyRadius = 9.5;
const double beamHalfWidth = 1.6;

/// Sağlıklı doku bu yarıçapın dışında ölçülür.
const double safetyMarginRadius = 5;

/// Keşifte ve görevlerde tümöre verilmesi istenen toplam doz.
const double targetDose = 6;

/// Sağlıklı dokunun güvenle alabileceği en yüksek doz.
const double safeHealthyDose = 2.5;

class Beam {
  const Beam(this.angleDeg, this.strength);

  final double angleDeg;
  final double strength;
}

/// [n] ışını eşit açılarla (yarım daireye) yayar; her biri toplam dozun
/// n'de biri kadar güçlü.
List<Beam> spreadBeams(int n, {double total = targetDose}) => [
  for (var i = 0; i < n; i++) Beam(180.0 * i / n, total / n),
];

/// Hepsi aynı yönden gelen [n] ışın.
List<Beam> stackedBeams(int n, {double total = targetDose}) => [
  for (var i = 0; i < n; i++) Beam(0, total / n),
];

class DoseMap {
  DoseMap(this.values);

  /// `values[y][x]`; vücut dışı hücreler null.
  final List<List<double?>> values;

  static bool isTumor(int x, int y) {
    final c = (therapyGrid - 1) / 2;
    final dx = x - c, dy = y - c;
    return dx * dx + dy * dy <= tumorRadius * tumorRadius;
  }

  static bool isFarHealthy(int x, int y) {
    final c = (therapyGrid - 1) / 2;
    final dx = x - c, dy = y - c;
    return isBody(x, y) && dx * dx + dy * dy >= safetyMarginRadius * safetyMarginRadius;
  }

  static bool isBody(int x, int y) {
    final c = (therapyGrid - 1) / 2;
    final dx = x - c, dy = y - c;
    return dx * dx + dy * dy <= bodyRadius * bodyRadius;
  }

  /// Tümörün en az aldığı doz.
  double get tumorDose {
    var m = double.infinity;
    for (var y = 0; y < therapyGrid; y++) {
      for (var x = 0; x < therapyGrid; x++) {
        if (isTumor(x, y)) m = min(m, values[y][x]!);
      }
    }
    return m;
  }

  /// Güvenlik payı dışındaki sağlıklı dokunun en çok aldığı doz.
  double get maxHealthyDose {
    var m = 0.0;
    for (var y = 0; y < therapyGrid; y++) {
      for (var x = 0; x < therapyGrid; x++) {
        final v = values[y][x];
        if (v != null && isFarHealthy(x, y)) m = max(m, v);
      }
    }
    return m;
  }

  bool get safe => maxHealthyDose <= safeHealthyDose;
}

DoseMap computeDose(List<Beam> beams) {
  final c = (therapyGrid - 1) / 2;
  return DoseMap([
    for (var y = 0; y < therapyGrid; y++)
      [
        for (var x = 0; x < therapyGrid; x++)
          if (!DoseMap.isBody(x, y))
            null
          else
            beams.fold<double>(0, (sum, b) {
              // Hücrenin ışın ekseninden (merkezden geçen doğru) uzaklığı.
              final a = b.angleDeg * pi / 180;
              final dx = x - c, dy = y - c;
              final dist = (dx * sin(a) - dy * cos(a)).abs();
              return dist <= beamHalfWidth ? sum + b.strength : sum;
            }),
      ],
  ]);
}
