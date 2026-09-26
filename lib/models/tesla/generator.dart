/// Tesla'nın alternatif akımı — jeneratör, saf model.
///
/// Bir tel bobin iki mıknatısın arasında döndükçe içinde gerilim oluşur.
/// Bobin yarım tur boyunca bir yöne, sonraki yarım turda öbür yöne
/// "kestiği" için gerilim bir artı bir eksi olur: v = k · f · sin(2π·f·t).
/// Akım saniyede f kez yön değiştirip geri gelir — **alternatif akım**.
/// Hızlı çevirmek hem gerilimi (ampul parlaklığı) hem sıklığı artırır.
/// Pil ise hep aynı yönde, sabit gerilim verir — **doğru akım**.
library;

import 'dart:math';

/// Saniyede bir tur için tepe gerilimi (V).
const double voltsPerTurnPerSecond = 4.0;

/// Pilin sabit gerilimi (V).
const double batteryVolts = 3.0;

/// Ampulün tam parlaklıkla yandığı gerilim (V).
const double bulbFullVolts = 10.0;

/// Kolu çevirme hızının sınırları (tur/sn).
const double maxTurnsPerSecond = 3.0;

/// LED'in yanması için gereken en küçük gerilim (V).
const double ledThresholdVolts = 0.8;

enum PowerSource {
  battery('Pil (doğru akım)'),
  generator('Jeneratör (alternatif akım)');

  const PowerSource(this.label);
  final String label;
}

/// Tepe gerilimi (V): hızla doğru orantılı.
double peakVolts(double turnsPerSecond) =>
    voltsPerTurnPerSecond * turnsPerSecond;

/// [t] saniyedeki gerilim (V).
double voltsAt(PowerSource source, double turnsPerSecond, double t) =>
    source == PowerSource.battery
    ? batteryVolts
    : peakVolts(turnsPerSecond) * sin(2 * pi * turnsPerSecond * t);

/// Ampulün ortalama parlaklığı (0-1). AC'de etkin gerilim tepe/√2'dir.
double bulbBrightness(PowerSource source, double turnsPerSecond) {
  final v = source == PowerSource.battery
      ? batteryVolts
      : peakVolts(turnsPerSecond) / sqrt2;
  return (v / bulbFullVolts).clamp(0.0, 1.0);
}

/// Ters bağlı iki LED'in davranışı.
enum LedPattern {
  none('Hiçbiri yanmaz'),
  steady('Yalnızca biri yanar, hep aynı'),
  alternating('İkisi sırayla yanıp söner');

  const LedPattern(this.label);
  final String label;
}

LedPattern ledPattern(PowerSource source, double turnsPerSecond) {
  if (source == PowerSource.battery) {
    return batteryVolts >= ledThresholdVolts ? LedPattern.steady : LedPattern.none;
  }
  return peakVolts(turnsPerSecond) >= ledThresholdVolts
      ? LedPattern.alternating
      : LedPattern.none;
}
