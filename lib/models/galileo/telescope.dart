/// Galileo'nun teleskobu — saf model.
///
/// Galileo 1609'da iki mercekli bir teleskop yaptı: önde uzak odaklı
/// **dışbükey** bir objektif, gözün önünde kısa odaklı **içbükey** bir göz
/// merceği. Bu düzende:
/// - büyütme = objektifin odak uzaklığı ÷ göz merceğinin odak uzaklığı,
/// - görüntünün net olması için tüp boyu = objektif − göz merceği.
/// (Bugünkü dışbükey göz mercekli teleskoplarda tüp "toplam" olur; Galileo'nun
/// modelinde "fark"tır — içbükey mercek ışığı dağıttığı için.)
library;

/// Seçilebilen objektifler (odak uzaklığı, cm).
const List<double> objectiveLensesCm = [60, 90, 120];

/// Seçilebilen içbükey göz mercekleri (odak uzaklığı, cm).
const List<double> eyepieceLensesCm = [3, 5, 10];

/// Tüp kaydırıcısının sınırları (cm).
const double tubeMinCm = 40;
const double tubeMaxCm = 125;

/// Tüp boyu doğru boydan bu kadar sapınca görüntü "net" sayılır.
const double sharpToleranceCm = 1.5;

double magnification(double objectiveCm, double eyepieceCm) =>
    objectiveCm / eyepieceCm;

/// Net görüntü için gereken tüp boyu (cm).
double sharpTubeCm(double objectiveCm, double eyepieceCm) =>
    objectiveCm - eyepieceCm;

/// Bulanıklık (0 = net): doğru tüp boyundan sapma, cm cinsinden.
double focusErrorCm(double objectiveCm, double eyepieceCm, double tubeCm) =>
    (tubeCm - sharpTubeCm(objectiveCm, eyepieceCm)).abs();

bool isSharp(double objectiveCm, double eyepieceCm, double tubeCm) =>
    focusErrorCm(objectiveCm, eyepieceCm, tubeCm) <= sharpToleranceCm;

/// Teleskopla bakılan hedefler.
enum SkyTarget {
  moon('Ay', 0xE0E0E0),
  jupiter('Jüpiter', 0xD7A86E),
  venus('Venüs', 0xFFF3C4);

  const SkyTarget(this.label, this.color);

  final String label;
  final int color;
}
