/// E = mc² — kütle ve enerji, saf model.
///
/// Einstein, kütlenin çok yoğun bir enerji olduğunu gösterdi: enerji = kütle ×
/// ışık hızının karesi. Işık hızı çok büyük (saniyede 300 000 km) olduğu için
/// minicik bir kütle bile dev bir enerjiye eşittir. Güneş her saniye yaklaşık
/// 4 milyon ton kütlesini ışığa ve ısıya çevirir. Gerçekte kütlenin yalnızca
/// çok küçük bir kısmı enerjiye dönüştürülebilir; oyundaki "tamamen dönüşse"
/// hesabı bir düşünce deneyidir.
library;

/// Işık hızı (m/s).
const double speedOfLight = 3e8;

/// Bir evin bir yıllık elektriği (J), yaklaşık 3 000 kWh.
const double homeYearJoules = 1.1e10;

/// 1 gram odunun yanınca verdiği enerji (J).
const double woodJoulesPerGram = 16000;

/// 3B şehirdeki her ev bu kadar gerçek evi temsil eder.
const int homesPerCityHouse = 100;
const int cityHouseCount = 100;

class TinyMass {
  const TinyMass(this.id, this.name, this.emoji, this.grams);

  final String id;
  final String name;
  final String emoji;
  final double grams;
}

const List<TinyMass> tinyMasses = [
  TinyMass('dust', 'Toz zerresi', '·', 0.0001),
  TinyMass('salt', 'Tuz tanesi', '🧂', 0.01),
  TinyMass('raisin', 'Kuru üzüm', '🍇', 0.5),
  TinyMass('clip', 'Ataş', '📎', 1),
];

TinyMass tinyMassById(String id) => tinyMasses.firstWhere((m) => m.id == id);

/// E = m·c² (J); [grams] gram.
double massEnergyJoules(double grams) =>
    grams / 1000 * speedOfLight * speedOfLight;

/// Bu enerji kaç evin bir yıllık elektriğine yeter.
double homesPowered(double grams) => massEnergyJoules(grams) / homeYearJoules;

/// Aynı kütlede odun yakınca kaç ev (çoğunlukla sıfıra çok yakın).
double homesFromBurning(double grams) =>
    grams * woodJoulesPerGram / homeYearJoules;

/// Şehirde yanan ev sayısı (her biri [homesPerCityHouse] gerçek ev).
int cityHousesLit(double grams) =>
    (homesPowered(grams) / homesPerCityHouse).ceil().clamp(0, cityHouseCount);

/// Büyük sayıları çocuk dilinde yazar: "8 200", "1,2 milyon".
String friendlyNumber(double n) {
  if (n >= 1e9) return '${_one(n / 1e9)} milyar';
  if (n >= 1e6) return '${_one(n / 1e6)} milyon';
  if (n >= 1000) {
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
  if (n >= 10) return n.round().toString();
  return _one(n);
}

String _one(double v) {
  final r = double.parse(v.toStringAsFixed(1));
  return r == r.roundToDouble()
      ? r.round().toString()
      : r.toStringAsFixed(1).replaceAll('.', ',');
}

/// Gramı gereksiz sıfırsız yazar: 0,01 g, 0,0001 g, 1 g.
String formatGrams(double g) {
  var t = g.toStringAsFixed(4);
  if (t.contains('.')) t = t.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return t.replaceAll('.', ',');
}

/// Odun yakmanın karşılığı, çocuk diliyle.
String burningPhrase(double grams) {
  final h = homesFromBurning(grams);
  return h < 0.05
      ? 'bir evin elektriğine bile yetmezdi'
      : '${friendlyNumber(h)} evin elektriğini verirdi';
}
