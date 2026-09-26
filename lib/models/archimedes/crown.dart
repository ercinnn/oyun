import 'buoyancy.dart';

/// Kralın tacı hikâyesi: kral kuyumcuya bir külçe altın verir, gelen taç aynı
/// ağırlıktadır ama kral kuyumcunun altının bir kısmını gümüşle değiştirdiğinden
/// şüphelenir. Arşimet tacı eritmeden anlamanın yolunu banyoda bulur: aynı
/// ağırlıktaki gümüş altından **daha büyük yer kaplar**, yani dolu kaptan daha
/// çok su taşırır. "Evreka! (Buldum!)"
const double goldDensity = 19.3;
const double silverDensity = 10.5;
const double crownMassG = 1000;

/// Sahte taçtaki gümüşün kütle oranı.
const double fakeSilverShare = 0.3;

double _crownVolume({required double silverShare}) =>
    crownMassG * (1 - silverShare) / goldDensity +
    crownMassG * silverShare / silverDensity;

/// Saf altın taç (~52 cm³).
final BuoyancyObject goldCrown = BuoyancyObject(
  id: 'crown_gold',
  name: 'Altın taç',
  emoji: '👑',
  massG: crownMassG,
  volumeCm3: _crownVolume(silverShare: 0),
  note: 'Saf altın çok yoğundur: 1000 gramlık taç küçücük bir yer kaplar.',
);

/// İçine gümüş karıştırılmış taç (~65 cm³): aynı ağırlıkta ama daha büyük.
final BuoyancyObject fakeCrown = BuoyancyObject(
  id: 'crown_fake',
  name: 'Karışık taç',
  emoji: '👑',
  massG: crownMassG,
  volumeCm3: _crownVolume(silverShare: fakeSilverShare),
  note: 'Gümüş altından hafiftir; aynı ağırlığa ulaşmak için daha çok '
      'gümüş gerekir, bu yüzden taç biraz daha büyük olur.',
);
