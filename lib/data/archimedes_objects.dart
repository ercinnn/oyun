import '../models/archimedes/boat.dart';
import '../models/archimedes/buoyancy.dart';

/// Arşimet oyununda suya bırakılabilen cisimler. Kütle/hacim değerleri
/// ilkokul düzeyinde yuvarlatılmış gerçekçi değerlerdir; bir öğretmen/ebeveyn
/// düzeltebilir, model yalnızca bu tabloya bakar. Her kimliğin 3B modeli
/// `assets/models/archimedes.glb` içinde `obj_<id>` grubudur.
///
/// Oyun hamuru çifti bilerek var: **aynı hamur** top olunca batar, kase olunca
/// yüzer — demirden gemilerin neden yüzdüğünün çocuk boyu kanıtı.
const List<BuoyancyObject> archimedesObjects = [
  BuoyancyObject(
    id: 'stone',
    name: 'Taş',
    emoji: '🪨',
    massG: 390,
    volumeCm3: 150,
    note: 'Taş, kapladığı yer kadar sudan çok daha ağırdır; dibe iner ama '
        'yine de kendi büyüklüğü kadar suyu yukarı iter.',
  ),
  BuoyancyObject(
    id: 'wood',
    name: 'Tahta blok',
    emoji: '🪵',
    massG: 120,
    volumeCm3: 200,
    note: 'Tahtanın içinde minik hava boşlukları vardır; aynı büyüklükteki '
        'sudan hafif olduğu için yüzer.',
  ),
  BuoyancyObject(
    id: 'cork',
    name: 'Mantar tıpa',
    emoji: '🍾',
    massG: 6,
    volumeCm3: 25,
    note: 'Mantar çok hafiftir; suyun ancak küçük bir kısmına gömülür, '
        'neredeyse tamamı suyun üstünde kalır.',
  ),
  BuoyancyObject(
    id: 'apple',
    name: 'Elma',
    emoji: '🍎',
    massG: 180,
    volumeCm3: 220,
    note: 'Elmanın içinde de hava vardır; bu yüzden elma yüzer. Armut ise '
        'daha yoğun olduğundan çoğu zaman batar!',
  ),
  BuoyancyObject(
    id: 'iron_ball',
    name: 'Demir bilye',
    emoji: '⚙️',
    massG: 250,
    volumeCm3: 32,
    note: 'Demir çok yoğundur: küçücük bir bilye bile avucunda ağır gelir. '
        'Hemen batar ama küçük olduğu için suyu az yükseltir.',
  ),
  BuoyancyObject(
    id: 'key',
    name: 'Anahtar',
    emoji: '🔑',
    massG: 30,
    volumeCm3: 4,
    note: 'Anahtar hafif gibi görünür ama metalden yapılmıştır; kapladığı '
        'yer kadar sudan ağır olduğu için batar.',
  ),
  BuoyancyObject(
    id: 'ball',
    name: 'Plastik top',
    emoji: '⚽',
    massG: 40,
    volumeCm3: 160,
    note: 'Topun içi havayla doludur; büyük ama hafif olduğu için yüzer.',
  ),
  BuoyancyObject(
    id: 'ice',
    name: 'Buz küpü',
    emoji: '🧊',
    massG: 46,
    volumeCm3: 50,
    note: 'Su donunca genişler, buz aynı miktar sudan biraz daha büyük olur. '
        'Bu yüzden buz yüzer ama neredeyse tamamı suyun altında kalır — '
        'buzdağları gibi!',
  ),
  BuoyancyObject(
    id: 'coin',
    name: 'Madeni para',
    emoji: '🪙',
    massG: 7,
    volumeCm3: 1,
    note: 'Para batar ama o kadar küçüktür ki su seviyesi neredeyse hiç '
        'değişmez: yükselme cismin ağırlığına değil, büyüklüğüne bağlıdır.',
  ),
  BuoyancyObject(
    id: 'clay_ball',
    name: 'Hamur top',
    emoji: '🟠',
    massG: 200,
    volumeCm3: 125,
    note: 'Top biçimindeki hamur, kapladığı yer kadar sudan ağırdır ve batar.',
  ),
  BuoyancyObject(
    id: 'clay_bowl',
    name: 'Hamur kase',
    emoji: '🥣',
    massG: 200,
    volumeCm3: 320,
    note: 'Aynı hamuru kase yaptık! İçindeki hava sayesinde çok daha büyük '
        'bir yer kaplıyor ve daha çok su itiyor; bu yüzden yüzüyor. Demir '
        'gemiler de böyle yüzer.',
  ),
];

BuoyancyObject archimedesObjectById(String id) =>
    archimedesObjects.firstWhere((o) => o.id == id);

/// Gemi istasyonundaki gemiler; taşıyabildikleri sandık sayısı birbirinden
/// belirgin farklı olsun diye seçildi (2 / 4 / 6).
const List<BoatSpec> archimedesBoats = [
  BoatSpec(
    id: 'rowboat',
    name: 'Kayık',
    emoji: '🛶',
    massG: 200,
    hullVolumeCm3: 1000,
    hullHeightCm: 8,
  ),
  BoatSpec(
    id: 'raft',
    name: 'Sal',
    emoji: '🪵',
    massG: 300,
    hullVolumeCm3: 1500,
    hullHeightCm: 6,
  ),
  BoatSpec(
    id: 'sailboat',
    name: 'Yelkenli',
    emoji: '⛵',
    massG: 600,
    hullVolumeCm3: 2400,
    hullHeightCm: 10,
  ),
];
