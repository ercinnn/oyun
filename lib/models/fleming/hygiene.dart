/// Temizlik ve mikroplar — saf model.
///
/// Mikroplar havada ve ellerimizde bulunur; gözle göremeyiz ama besleyici bir
/// petri kabında birkaç günde koloni olup görünür hâle gelirler. Kapağı açık
/// kalan kaba havadan, yıkanmamış elle dokunulan kaba elden mikrop geçer.
/// Sabunla yıkanmış el çok daha az mikrop taşır. Fleming de kaplarını kapalı
/// tutar, deneylerini temiz çalışarak yapardı.
library;

import 'dart:math';

enum HandTouch {
  none('Kimse dokunmadı', 0),
  washed('Yıkanmış elle dokunuldu', 2),
  unwashed('Yıkanmamış elle dokunuldu', 22);

  const HandTouch(this.label, this.colonies);
  final String label;

  /// 3 gün sonra elden gelen koloni sayısı.
  final int colonies;
}

/// Kapak açık kalırsa havadan gelen koloni sayısı (3 gün sonra).
const int openLidColonies = 9;

/// Bekletme süresi (gün).
const int hygieneDays = 3;

/// [days] gün sonra kaptaki koloni sayısı.
int hygieneColonies({
  required bool lidOpen,
  required HandTouch hand,
  int days = hygieneDays,
}) {
  if (days <= 0) return 0;
  return (lidOpen ? openLidColonies : 0) + hand.colonies;
}

/// Koloni yerleri: hep aynı tohumla (çizimler her seferinde aynı olsun).
List<(double, double)> hygieneColonySpots(int count) {
  final rng = Random(7);
  final out = <(double, double)>[];
  while (out.length < count) {
    final x = rng.nextDouble() * 2 - 1;
    final y = rng.nextDouble() * 2 - 1;
    if (x * x + y * y <= 0.8 * 0.8) out.add((x, y));
  }
  return out;
}
