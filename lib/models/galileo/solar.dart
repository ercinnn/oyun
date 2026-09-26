/// Güneş merkezli sistem ve Venüs'ün evreleri — saf model.
///
/// Gezegenler Güneş'in etrafında çembersel yörüngelerde dolanır; Güneş'e
/// yakın olan daha kısa yolda ve daha hızlı döner. Galileo teleskopla
/// Venüs'ün Ay gibi evreler gösterdiğini gördü: Dünya'ya yakınken büyük ve
/// ince bir hilal, Güneş'in öbür yanındayken küçük ve neredeyse dolunay.
/// Venüs Dünya'nın etrafında dönseydi hiçbir zaman dolunay gibi görünemezdi —
/// bu, Güneş merkezli modelin en güçlü kanıtlarından biri oldu.
library;

import 'dart:math';

class Planet {
  const Planet({
    required this.id,
    required this.name,
    required this.orbitAu,
    required this.periodDays,
    required this.color,
    required this.startAngleDeg,
  });

  final String id;
  final String name;

  /// Güneş'e uzaklık (Dünya-Güneş uzaklığı = 1).
  final double orbitAu;
  final double periodDays;
  final int color;
  final double startAngleDeg;

  double angleAt(double day) =>
      startAngleDeg * pi / 180 + 2 * pi * day / periodDays;

  (double, double) positionAt(double day) {
    final a = angleAt(day);
    return (orbitAu * cos(a), orbitAu * sin(a));
  }
}

const List<Planet> planets = [
  Planet(id: 'mercury', name: 'Merkür', orbitAu: 0.39, periodDays: 88, color: 0xB0A597, startAngleDeg: 30),
  Planet(id: 'venus', name: 'Venüs', orbitAu: 0.72, periodDays: 225, color: 0xF3D99B, startAngleDeg: 130),
  Planet(id: 'earth', name: 'Dünya', orbitAu: 1.0, periodDays: 365, color: 0x42A5F5, startAngleDeg: 0),
  Planet(id: 'mars', name: 'Mars', orbitAu: 1.52, periodDays: 687, color: 0xE0643C, startAngleDeg: 250),
  Planet(id: 'jupiter', name: 'Jüpiter', orbitAu: 5.2, periodDays: 4333, color: 0xD7A86E, startAngleDeg: 190),
];

Planet planetById(String id) => planets.firstWhere((p) => p.id == id);

/// Dünya'dan bakınca Venüs: aydınlık oran (0 = yeni, 1 = dolunay gibi) ve
/// görünen boy (Dünya-Venüs uzaklığının tersi; 1 AU'da 1).
class VenusView {
  const VenusView({required this.litFraction, required this.relativeSize});

  final double litFraction;
  final double relativeSize;

  VenusPhase get phase => litFraction < 0.35
      ? VenusPhase.crescent
      : litFraction > 0.75
      ? VenusPhase.full
      : VenusPhase.half;
}

enum VenusPhase {
  crescent('Büyük, ince bir hilal'),
  half('Yarım daire'),
  full('Küçük, neredeyse dolunay gibi');

  const VenusPhase(this.label);
  final String label;
}

/// [earthAngle] ve [venusAngle] radyan; Güneş orijinde.
VenusView venusFromEarth(double earthAngle, double venusAngle) {
  final ex = cos(earthAngle), ey = sin(earthAngle);
  final v = planetById('venus').orbitAu;
  final vx = v * cos(venusAngle), vy = v * sin(venusAngle);
  // Venüs'ten Güneş'e ve Dünya'ya giden vektörler arasındaki açı (evre açısı).
  final sx = -vx, sy = -vy;
  final dx = ex - vx, dy = ey - vy;
  final dist = sqrt(dx * dx + dy * dy);
  final cosPhase = (sx * dx + sy * dy) / (v * dist);
  return VenusView(
    litFraction: (1 + cosPhase) / 2,
    relativeSize: 1 / dist,
  );
}

VenusView venusOnDay(double day) => venusFromEarth(
  planetById('earth').angleAt(day),
  planetById('venus').angleAt(day),
);
