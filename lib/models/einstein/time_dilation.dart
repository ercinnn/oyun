/// Hızlı giden saat yavaş işler — saf model.
///
/// Işık saati: iki ayna arasında gidip gelen bir ışık. Hızla giden gemideki
/// saate yerden bakınca ışık çapraz, daha uzun bir yol gider; ışığın hızı
/// hiç değişmediği için her "tık" daha uzun sürer. Bu yüzden gemideki zaman
/// daha yavaş akar:
///   gemide geçen süre = Dünya'da geçen süre × √(1 − (v/c)²).
/// Çok hızlı giden bir astronot, Dünya'daki ikizinden daha az yaşlanır.
library;

import 'dart:math';

/// Seçilebilen gemi hızları (ışık hızının kesri).
const List<double> shipSpeeds = [0, 0.5, 0.6, 0.8, 0.9, 0.99];

/// Zaman yavaşlama çarpanı γ = 1 / √(1 − v²).
double lorentzGamma(double v) => 1 / sqrt(1 - v * v);

/// Dünya'da [earthYears] geçerken gemide geçen süre.
double shipYears(double earthYears, double v) =>
    earthYears * sqrt(1 - v * v);

/// Işık hızının yüzdesi olarak (0,8 → "%80").
String percentOfC(double v) => '%${(v * 100).round()}';
