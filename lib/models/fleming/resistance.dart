/// Antibiyotiği doğru kullanmak — saf ve deterministik model.
///
/// Hastalık yapan bakterilerin arasında, ilaca biraz daha dayanıklı birkaç
/// bakteri bulunur. İlaç her gün duyarlı bakterilerin çoğunu, dayanıklıların
/// ise daha azını öldürür. Tam süre kullanılırsa hepsi yok olur. Erken
/// bırakılırsa geriye kalan (çoğu dayanıklı) bakteriler yeniden çoğalır:
/// hastalık geri döner ve bu kez ilaç daha zor işe yarar. Bu yüzden ilaç,
/// doktorun söylediği gün sayısı kadar kullanılmalıdır.
///
/// Antibiyotik yalnızca bakterilere etki eder; grip gibi virüs hastalıklarında
/// işe yaramaz. Antibiyotiği yalnızca doktor verir.
library;

import 'dart:math';

/// Başlangıçta duyarlı ve dayanıklı bakteri sayısı.
const double startSensitive = 1000;
const double startResistant = 10;

/// İlacın her gün hayatta bıraktığı oran.
const double sensitiveSurvival = 0.3;
const double resistantSurvival = 0.6;

/// İlaçsız günlerde çoğalma ve vücuttaki üst sınır.
const double growthPerDay = 2;
const double populationCap = 1010;

/// Doktorun söylediği tam süre ve izlenen gün sayısı.
const int fullCourseDays = 7;
const int observedDays = 10;

/// 0,5'ten az bakteri "kalmadı" sayılır.
const double extinctBelow = 0.5;

class Population {
  const Population(this.sensitive, this.resistant);

  final double sensitive;
  final double resistant;

  double get total => sensitive + resistant;
  bool get cleared => total < extinctBelow;

  /// Dayanıklıların oranı (0-1).
  double get resistantShare => total <= 0 ? 0 : resistant / total;
}

/// İlaç [treatmentDays] gün alınırsa her günün sonundaki topluluk
/// (index 0 = başlangıç, [observedDays]'e kadar).
List<Population> simulateTreatment(int treatmentDays) {
  var s = startSensitive, r = startResistant;
  final days = <Population>[Population(s, r)];
  for (var d = 1; d <= observedDays; d++) {
    if (d <= treatmentDays) {
      s *= sensitiveSurvival;
      r *= resistantSurvival;
    } else {
      s *= growthPerDay;
      r *= growthPerDay;
      final t = s + r;
      if (t > populationCap) {
        s *= populationCap / t;
        r *= populationCap / t;
      }
    }
    if (s < extinctBelow) s = 0;
    if (r < extinctBelow) r = 0;
    days.add(Population(s, r));
  }
  return days;
}

Population finalPopulation(int treatmentDays) =>
    simulateTreatment(treatmentDays).last;

/// Hastalığa yol açan mikrop türü.
enum Pathogen {
  bacteria('Bakteri (örneğin boğaz enfeksiyonu)'),
  virus('Virüs (örneğin grip, soğuk algınlığı)');

  const Pathogen(this.label);
  final String label;
}

bool antibioticWorks(Pathogen p) => p == Pathogen.bacteria;

/// Yuvarlanmış sayı (çizim/metin için).
int rounded(double v) => max(0, v.round());
