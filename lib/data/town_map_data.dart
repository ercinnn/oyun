import '../models/town/town_map.dart';

/// Kasaba: 20×18. Kuzeyde üç bina (giyim, market, ev), ortada park (havuz,
/// çeşme, lamba), doğuda oyun salonu, çevresinde halka yol. Karakter
/// açıklamaları için bkz. [TownMap.parse]. Testler her kapının ve yürünebilir
/// karenin başlangıçtan ulaşılabilir olduğunu doğrular.
const List<String> townRows = [
  'TTTTTTTTTTTTTTTTTTTT',
  'T..................T',
  'T.AAAA..BBBB..CCCC.T',
  'T.AAAA..BBBB..CCCC.T',
  'T.AAAA..BBBB..CCCC.T',
  'T..a......b.....c..T',
  'T,,,,,,,,,,,,,,,,,,T',
  'T,..T..........T..,T',
  'T,.____....L.....T,T',
  'T,.__~~_..F....EEE.T',
  'T,.__~~_.......EEE.T',
  'T,.____T.......EEE.T',
  'T,..T..........e...T',
  'T,....T.......T....T',
  'T,.................T',
  'T,,,,,,,,,,,,,,,,,,T',
  'T..................T',
  'TTTTTTTTTTTTTTTTTTTT',
];

/// Kasabada altın/yıldız çıkan sabit noktalar (kare koordinatı, merkez +0,5).
const List<(int, int)> townCoinSpots = [
  (2, 6), (5, 6), (8, 6), (12, 6), (15, 6), (17, 6),
  (2, 9), (2, 12), (5, 14), (9, 14), (13, 14), (17, 14),
  (18, 9), (18, 12), (9, 8), (12, 9), (10, 12), (6, 12),
  (14, 8), (4, 1), (10, 1), (16, 1), (9, 16), (16, 16),
];

/// Parkur pisti: 16×7. Üç kareden geniş koridor; kenarlarda su (tehlike),
/// ortada çamur, koridoru dikine geçen varillerle dolu. `S` başlangıç, `G`
/// bayrak.
const List<String> parkourRows = [
  'TTTTTTTTTTTTTTTT',
  'T~~~~~~~~~~~~~~T',
  'T.,,,,,m,,,,,,GT',
  'TS,,,,,,mm,,,,,T',
  'T.,,,,,,,,,,,,,T',
  'T~~~~~~~~~~~~~~T',
  'TTTTTTTTTTTTTTTT',
];

/// Karakterin kasabada doğduğu yer: kuzey binaların önündeki ana yol.
const double townStartX = 9.5;
const double townStartY = 6.5;

TownMap buildTownMap() => TownMap.parse(townRows);

TownMap buildParkourMap() => TownMap.parse(parkourRows, waterIsHazard: true);
