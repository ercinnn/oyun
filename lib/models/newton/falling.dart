/// Newton'un kütleçekimi — düşen cisimler, saf ve deterministik model.
///
/// Havasız ortamda her cisim aynı ivmeyle düşer: y = ½·g·t². Havada ise her
/// cismin bir **limit hızı** vardır (hava direnci ağırlığına eşit olunca daha
/// fazla hızlanamaz); karesel sürtünmenin kapalı çözümü kullanılır:
///   v(t) = vₜ·tanh(g·t/vₜ),  y(t) = vₜ²/g · ln(cosh(g·t/vₜ)).
/// Tüy ve düz kâğıdın limit hızı çok küçük olduğu için havada yavaş iner;
/// havayı kaldırınca (vakum tüpü, Ay) çekiçle aynı anda yere değer.
library;

import 'dart:math';

/// Kulenin yüksekliği (m): cisimler bu yükseklikten bırakılır.
const double towerHeightM = 6;

/// Bu farktan küçük süreler "aynı anda" sayılır (göz ayırt edemez).
const double sameTimeThresholdS = 0.1;

enum FallEnvironment {
  air('Dünya (havalı)', 9.8, true),
  vacuum('Havasız tüp', 9.8, false),
  moon('Ay', 1.62, false);

  const FallEnvironment(this.label, this.g, this.hasAir);

  final String label;

  /// Yerçekimi ivmesi (m/s²).
  final double g;
  final bool hasAir;
}

class FallingObject {
  const FallingObject({
    required this.id,
    required this.name,
    required this.emoji,
    required this.massG,
    required this.terminalSpeed,
    required this.note,
  });

  /// Kimlik; 3B modeldeki grup adı `fall_<id>`.
  final String id;
  final String name;
  final String emoji;
  final double massG;

  /// Havada ulaşabildiği en büyük hız (m/s).
  final double terminalSpeed;

  /// Elle yazılmış açıklama (neden böyle düşer).
  final String note;

  String get modelId => 'fall_$id';
}

/// ln(cosh(u)), büyük u'da taşmadan.
double _logCosh(double u) => u + log(1 + exp(-2 * u)) - ln2;

/// acosh(eˣ), büyük x'te taşmadan.
double _acoshExp(double x) => x + log(1 + sqrt(1 - exp(-2 * x)));

/// [t] saniyede düşülen yol (m), kule yüksekliğiyle sınırlı.
double fallDistance(FallingObject o, double t, FallEnvironment env) {
  if (t <= 0) return 0;
  final double d;
  if (!env.hasAir) {
    d = 0.5 * env.g * t * t;
  } else {
    final vt = o.terminalSpeed;
    d = vt * vt / env.g * _logCosh(env.g * t / vt);
  }
  return min(d, towerHeightM);
}

/// Kuleden yere düşme süresi (s).
double fallTime(FallingObject o, FallEnvironment env) {
  if (!env.hasAir) return sqrt(2 * towerHeightM / env.g);
  final vt = o.terminalSpeed;
  return vt / env.g * _acoshExp(towerHeightM * env.g / (vt * vt));
}

/// İki cisimden hangisi önce yere değer: 0 = A, 1 = B, 2 = aynı anda.
int fallWinner(FallingObject a, FallingObject b, FallEnvironment env) {
  final ta = fallTime(a, env);
  final tb = fallTime(b, env);
  if ((ta - tb).abs() < sameTimeThresholdS) return 2;
  return ta < tb ? 0 : 1;
}
