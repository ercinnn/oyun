/// Uzak şehre elektrik taşımak — saf model.
///
/// Teller elektriğe biraz direnir ve bu direnç enerjinin bir kısmını ısıya
/// çevirir. Kaybolan güç = akım² × direnç. Aynı gücü **yüksek gerilimle**
/// gönderince akım küçülür (güç = gerilim × akım), kayıp akımın karesiyle
/// azalır. Tesla'nın alternatif akımı transformatörle kolayca yükseltilip
/// alçaltılabildiği için uzağa taşınabildi; Edison'un doğru akımı her birkaç
/// kilometrede bir santral gerektiriyordu.
library;

import 'dart:math';

/// Santralin ürettiği gerilim (V) ve şehrin istediği güç (W).
const double plantVolts = 200;
const double cityDemandWatts = 10000;

/// Şehirdeki ev sayısı; her ev 1000 W ister.
const int cityHouses = 10;
const double houseWatts = cityDemandWatts / cityHouses;

/// Hattın kilometre başına direnci (Ω), gidiş ve dönüş telleri birlikte.
const double lineOhmsPerKm = 1.0;

/// Seçilebilen uzaklıklar (km) ve transformatör ikinci bobin sarımları.
const List<double> cityDistancesKm = [1, 10, 50];
const int primaryTurns = 10;
const List<int> secondaryTurnsOptions = [10, 100, 1000];

/// Transformatör: çıkış gerilimi = giriş × (ikinci sarım ÷ birinci sarım).
double transformerOut(double volts, int primary, int secondary) =>
    volts * secondary / primary;

double lineVolts(int secondary) =>
    transformerOut(plantVolts, primaryTurns, secondary);

/// Şehre ulaşan güç (W).
double deliveredWatts(double lineV, double distanceKm) {
  final current = cityDemandWatts / lineV;
  final loss = current * current * lineOhmsPerKm * distanceKm;
  return max(0, cityDemandWatts - loss);
}

/// Yanan ev sayısı (ulaşan gücün kaç eve yettiği, en yakın tam sayıya
/// yuvarlanır: %99,9'u ulaşan şehirde 10 evin hepsi yanar).
int housesLit(double lineV, double distanceKm) =>
    (deliveredWatts(lineV, distanceKm) / houseWatts).round().clamp(0, cityHouses);

/// Ulaşan enerji yüzdesi (0-100).
double deliveredPercent(double lineV, double distanceKm) =>
    deliveredWatts(lineV, distanceKm) / cityDemandWatts * 100;
