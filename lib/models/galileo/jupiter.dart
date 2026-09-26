/// Jüpiter'in dört büyük uydusu — saf model.
///
/// Galileo 1610'da teleskobunu Jüpiter'e çevirdi ve yanında dizili dört
/// "yıldız" gördü. Geceden geceye yer değiştiriyor, bazen biri kayboluyordu:
/// Jüpiter'in etrafında dönüyorlardı! Bu, her şeyin Dünya'nın etrafında
/// dönmediğinin ilk kanıtıydı.
///
/// Yörüngeler çember sayılır. Dünya'dan Jüpiter'e yandan bakarız, bu yüzden
/// teleskopta yalnızca yatay konum görünür: x = a·cos(açı). |x| < 1 (Jüpiter
/// yarıçapı) ise uydu Jüpiter'in önünde ya da arkasındadır ve görünmez.
library;

import 'dart:math';

class JupiterMoon {
  const JupiterMoon({
    required this.id,
    required this.name,
    required this.distance,
    required this.periodDays,
    required this.startAngleDeg,
    required this.color,
  });

  final String id;
  final String name;

  /// Jüpiter'e uzaklık (Jüpiter yarıçapı cinsinden).
  final double distance;
  final double periodDays;

  /// 0. gecedeki açı (0° = Jüpiter'in tam sağı, gökyüzünde doğu değil;
  /// basitleştirildi).
  final double startAngleDeg;
  final int color;

  double angleAt(double nights) =>
      startAngleDeg * pi / 180 + 2 * pi * nights / periodDays;

  /// Teleskopta görünen yatay konum (Jüpiter yarıçapı; + sağ, − sol).
  double skyX(double nights) => distance * cos(angleAt(nights));

  /// Bize doğru (+) ya da uzağa (−) derinlik.
  double depth(double nights) => distance * sin(angleAt(nights));

  bool hiddenAt(double nights) => skyX(nights).abs() < 1;
}

/// Gerçek uzaklıklar ve dolanma süreleri (yuvarlatılmış).
const List<JupiterMoon> jupiterMoons = [
  JupiterMoon(
    id: 'io',
    name: 'İo',
    distance: 5.9,
    periodDays: 1.77,
    startAngleDeg: 40,
    color: 0xFFD54F,
  ),
  JupiterMoon(
    id: 'europa',
    name: 'Europa',
    distance: 9.4,
    periodDays: 3.55,
    startAngleDeg: 200,
    color: 0xECEFF1,
  ),
  JupiterMoon(
    id: 'ganymede',
    name: 'Ganimed',
    distance: 15.0,
    periodDays: 7.15,
    startAngleDeg: 320,
    color: 0xBCAAA4,
  ),
  JupiterMoon(
    id: 'callisto',
    name: 'Kallisto',
    distance: 26.4,
    periodDays: 16.69,
    startAngleDeg: 150,
    color: 0x8D6E63,
  ),
];

JupiterMoon jupiterMoonById(String id) =>
    jupiterMoons.firstWhere((m) => m.id == id);

/// Uydunun teleskopta nerede göründüğü.
enum MoonSide { left, right, hidden }

MoonSide moonSide(JupiterMoon m, double nights) {
  final x = m.skyX(nights);
  if (x.abs() < 1) return MoonSide.hidden;
  return x < 0 ? MoonSide.left : MoonSide.right;
}

/// Galileo'nun defterindeki gibi bir gecenin çizimi: `* * O *` (O = Jüpiter,
/// * = görünen uydu).
String notebookSketch(double nights) {
  const width = 29; // her karakter ~2 Jüpiter yarıçapı
  final cells = List.filled(width, ' ');
  final center = width ~/ 2;
  cells[center] = 'O';
  for (final m in jupiterMoons) {
    if (m.hiddenAt(nights)) continue;
    final i = (center + m.skyX(nights) / 2).round().clamp(0, width - 1);
    if (cells[i] == ' ') cells[i] = '*';
  }
  return cells.join().trimRight();
}
