/// Tesla bobini ve kablosuz enerji — saf model.
///
/// Tesla bobini çok hızlı titreşen (yüz binlerce kez/sn) bir elektrik alanı
/// yayar. Yakındaki bir floresan lamba, hiçbir kabloya bağlı olmadan bu
/// alanla yanar; uzaklaştıkça alan zayıflar. Bir alıcı devre, vericiyle
/// **aynı frekansa** ayarlanırsa enerjiyi en iyi toplar (rezonans) — tıpkı
/// salıncağı doğru anlarda itmek gibi. Radyoyu bir istasyona ayarlamak da
/// budur; Tesla radyonun temellerini böyle attı.
library;

/// Vericinin seçilebilen frekansları (kHz).
const List<double> transmitterFrequenciesKHz = [100, 200, 300];

/// Alıcı ayar kaydırıcısının sınırları (kHz).
const double receiverMinKHz = 50;
const double receiverMaxKHz = 350;

/// Lamba uzaklığı sınırları (m).
const double lampMinM = 0.5;
const double lampMaxM = 4;

/// Rezonansın genişliği (kHz): ayar bu kadar kayınca güç yarıya iner.
const double resonanceWidthKHz = 20;

/// Bu uzaklıkta alan gücü yarıya iner (m).
const double halfFieldDistanceM = 1.2;

/// Lambanın yanması için gereken en küçük parlaklık.
const double lampThreshold = 0.15;

/// Ayarın uygunluğu (0-1): tam aynı frekansta 1.
double resonance(double transmitterKHz, double receiverKHz) {
  final x = (receiverKHz - transmitterKHz) / resonanceWidthKHz;
  return 1 / (1 + x * x);
}

/// Uzaklıkla alan gücü (0-1).
double fieldStrength(double distanceM) {
  final x = distanceM / halfFieldDistanceM;
  return 1 / (1 + x * x);
}

/// Lambanın parlaklığı (0-1); bobin kapalıysa 0.
double lampBrightness({
  required bool coilOn,
  required double transmitterKHz,
  required double receiverKHz,
  required double distanceM,
}) {
  if (!coilOn) return 0;
  return resonance(transmitterKHz, receiverKHz) * fieldStrength(distanceM);
}

bool lampLit(double brightness) => brightness >= lampThreshold;
