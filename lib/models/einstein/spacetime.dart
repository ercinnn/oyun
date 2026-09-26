/// Einstein'ın uzay-zaman örtüsü — saf ve deterministik model.
///
/// Einstein'a göre kütle, uzay-zamanı esnek bir örtü gibi büker. Ağır bir top
/// örtüyü çukurlaştırır; yanından geçen küçük bir bilye bu çukura doğru
/// kıvrılır. Hızı azsa içine düşer, yeterince hızlıysa çukurun etrafında
/// döner (yörünge), çok hızlıysa kaçıp gider. Gezegenlerin Güneş'in
/// etrafında dönmesi de, ışığın ağır yıldızların yanında bükülmesi de böyle
/// açıklanır.
///
/// Bilye düzlemde, merkezdeki kütlenin çekimiyle (a = −M·r/|r|³) hareket eder;
/// sabit adımlı "leapfrog" yöntemiyle hesaplanır (rastgelelik yok). Birimler
/// oyun içindir.
library;

import 'dart:math';

enum CentralMass {
  earth('Dünya', 1, 0x42A5F5, 0.7),
  sun('Güneş', 4, 0xFFB300, 1.0),
  neutron('Nötron yıldızı', 10, 0xB388FF, 0.45);

  const CentralMass(this.label, this.mass, this.color, this.radius);

  final String label;
  final double mass;
  final int color;

  /// Çizimdeki yarıçap (nötron yıldızı çok ağır ama küçücüktür).
  final double radius;
}

enum LaunchSpeed {
  slow('Yavaş', 0.15),
  medium('Orta', 0.35),
  fast('Hızlı', 0.6);

  const LaunchSpeed(this.label, this.value);
  final String label;
  final double value;
}

enum MarbleFate {
  fallsIn('Merkeze düşer'),
  orbits('Etrafında döner (yörünge)'),
  escapes('Kaçıp gider');

  const MarbleFate(this.label);
  final String label;
}

/// Bilyenin fırlatıldığı uzaklık, düşme ve kaçma sınırları.
const double launchRadius = 8;
const double captureRadius = 1.2;
const double escapeRadius = 16;

/// Benzetim süresi ve adımı; [pathEvery] adımda bir nokta kaydedilir.
const double _simDuration = 90;
const double _dt = 0.005;
const int _pathEvery = 20;

class MarbleRun {
  const MarbleRun(this.fate, this.path, this.dtPerPoint);

  final MarbleFate fate;

  /// Bilyenin düzlemdeki yolu (x, y); ilk nokta fırlatma noktası.
  final List<(double, double)> path;

  /// Ardışık iki yol noktası arasındaki benzetim süresi.
  final double dtPerPoint;

  double get duration => (path.length - 1) * dtPerPoint;
}

/// Bilye (launchRadius, 0)'dan +y yönünde [speed] hızla fırlatılır.
MarbleRun simulateMarble(CentralMass center, LaunchSpeed speed) {
  final m = center.mass;
  var x = launchRadius, y = 0.0;
  var vx = 0.0, vy = speed.value;
  (double, double) acc(double px, double py) {
    final r2 = px * px + py * py;
    final r3 = r2 * sqrt(r2);
    return (-m * px / r3, -m * py / r3);
  }

  var (ax, ay) = acc(x, y);
  final path = <(double, double)>[(x, y)];
  final steps = (_simDuration / _dt).round();
  var fate = MarbleFate.orbits;
  for (var i = 1; i <= steps; i++) {
    vx += ax * _dt / 2;
    vy += ay * _dt / 2;
    x += vx * _dt;
    y += vy * _dt;
    (ax, ay) = acc(x, y);
    vx += ax * _dt / 2;
    vy += ay * _dt / 2;
    final r = sqrt(x * x + y * y);
    if (i % _pathEvery == 0) path.add((x, y));
    if (r < captureRadius) {
      fate = MarbleFate.fallsIn;
      break;
    }
    if (r > escapeRadius) {
      fate = MarbleFate.escapes;
      break;
    }
  }
  if (path.last != (x, y)) path.add((x, y));
  return MarbleRun(fate, path, _dt * _pathEvery);
}

/// Örtünün [r] uzaklıktaki çukur derinliği (çizim için, ≥ 0).
double sheetDepth(CentralMass center, double r) =>
    center.mass * 0.35 / (r + 0.8);
