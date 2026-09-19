import '../models/plant_species.dart';

/// Laboratuvardaki bitkiler. Skorlar [light, water, temperature] için ayrı ayrı
/// üçer kademelidir: ışık {karanlık, gölge, güneş}, su {az, orta, çok},
/// sıcaklık {5°, 20°, 35°}. 1.0 en uygun kademe; her etkende tek bir en yüksek
/// skor olmalıdır (testler bunu doğrular).
///
/// Bu değerler ilkokul düzeyinde sadeleştirilmiş, genel bitki bilgisidir; bir
/// öğretmen/ebeveyn gözden geçirip skorları ya da cümleleri düzeltebilir —
/// büyüme modeli yalnızca bu tabloya bakar.
const List<PlantSpecies> plantCatalog = [
  PlantSpecies(
    id: 'fasulye',
    name: 'Fasulye',
    emoji: '🫘',
    shape: PlantShape.leafy,
    maxHeightCm: 40,
    lightScores: [0.05, 0.55, 1.0],
    waterScores: [0.35, 1.0, 0.35],
    temperatureScores: [0.15, 1.0, 0.55],
    lightNote:
        'Fasulye güneşi çok sever; ışıkta yaprakları besin yapar ve boyu hızla uzar.',
    waterNote:
        'Fasulye toprağı nemli ister ama sulu istemez; çok su köklerin nefes almasını engeller.',
    temperatureNote:
        'Fasulye ılık havada en iyi büyür; soğukta çok yavaşlar, çok sıcakta ise yorulur.',
    funFact: 'Fasulye filizi bir destek bulursa ona sarılarak tırmanır.',
  ),
  PlantSpecies(
    id: 'mercimek',
    name: 'Mercimek',
    emoji: '🌱',
    shape: PlantShape.leafy,
    maxHeightCm: 25,
    lightScores: [0.05, 0.6, 1.0],
    waterScores: [0.3, 1.0, 0.35],
    temperatureScores: [0.4, 1.0, 0.5],
    lightNote:
        'Mercimek filizi ışık görünce yeşerir; ışıksız kalırsa soluk ve cılız olur.',
    waterNote:
        'Mercimek az suda susar, çok suda çürür; toprağı hafif nemli tutmak yeterlidir.',
    temperatureNote:
        'Mercimek ılık havayı sever; çok soğukta yavaşlar, çok sıcakta yorulur.',
    funFact:
        'Mercimek tohumu birkaç gün içinde filizlenir; bu yüzden okul deneylerinin gözdesidir.',
  ),
  PlantSpecies(
    id: 'bugday',
    name: 'Buğday',
    emoji: '🌾',
    shape: PlantShape.grass,
    maxHeightCm: 50,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.3, 1.0, 0.4],
    temperatureScores: [0.7, 1.0, 0.3],
    lightNote: 'Buğday fidesi bol ışıkta güçlü ve yeşil büyür.',
    waterNote:
        'Buğday toprağın hep ıslak kalmasını istemez; orta derecede nem yeterlidir.',
    temperatureNote:
        'Buğday serin ve ılık havayı sever; çok sıcakta zayıf düşer.',
    funFact: 'Ekmeğin unu buğdaydan yapılır.',
  ),
  PlantSpecies(
    id: 'aycicegi',
    name: 'Ayçiçeği',
    emoji: '🌻',
    shape: PlantShape.leafy,
    maxHeightCm: 100,
    lightScores: [0.05, 0.5, 1.0],
    waterScores: [0.3, 1.0, 0.4],
    temperatureScores: [0.2, 0.85, 1.0],
    lightNote: 'Ayçiçeği bol güneşte hızla uzar ve yüzünü güneşe çevirir.',
    waterNote:
        'Ayçiçeği orta miktarda su ister; sürekli ıslak toprağı sevmez.',
    temperatureNote:
        'Ayçiçeği sıcak havayı çok sever; soğukta çok yavaş büyür.',
    funFact: 'Genç ayçiçekleri gün boyunca yüzlerini güneşe doğru çevirir.',
  ),
  PlantSpecies(
    id: 'domates',
    name: 'Domates',
    emoji: '🍅',
    shape: PlantShape.leafy,
    maxHeightCm: 60,
    lightScores: [0.05, 0.5, 1.0],
    waterScores: [0.3, 1.0, 0.4],
    temperatureScores: [0.15, 1.0, 0.5],
    lightNote: 'Domates bol güneş ister; ışık azsa boyu ve meyvesi azalır.',
    waterNote:
        'Domates düzenli ve orta miktarda sulanmalıdır; çok su köklerini çürütebilir.',
    temperatureNote:
        'Domates ılık havada en iyi büyür; soğuk da aşırı sıcak da onu yorar.',
    funFact: 'Domates aslında bir meyvedir.',
  ),
  PlantSpecies(
    id: 'nane',
    name: 'Nane',
    emoji: '🌿',
    shape: PlantShape.leafy,
    maxHeightCm: 30,
    lightScores: [0.15, 1.0, 0.75],
    waterScores: [0.2, 0.8, 1.0],
    temperatureScores: [0.3, 1.0, 0.5],
    lightNote:
        'Nane aydınlık ama çok yakıcı olmayan yerleri sever; gölgede de güneşte de büyür.',
    waterNote: 'Nane suyu sever; toprak kuruyunca hemen solar.',
    temperatureNote:
        'Nane ılık havada güzel büyür; soğukta yavaşlar, çok sıcakta yorulur.',
    funFact: 'Nane yaprağını ovunca hoş bir koku çıkar.',
  ),
  PlantSpecies(
    id: 'marul',
    name: 'Marul',
    emoji: '🥬',
    shape: PlantShape.leafy,
    maxHeightCm: 25,
    lightScores: [0.1, 0.8, 1.0],
    waterScores: [0.25, 1.0, 0.6],
    temperatureScores: [0.55, 1.0, 0.15],
    lightNote: 'Marul aydınlıkta iyi büyür ama gölgede de idare eder.',
    waterNote:
        'Marul yaprakları çok su tutar; toprağı düzenli nemli olmalı, ama fazla sudan da zarar görür.',
    temperatureNote:
        'Marul serin havayı sever; çok sıcakta büyümesi bozulur.',
    funFact: 'Marul yaprağının büyük kısmı sudur.',
  ),
  PlantSpecies(
    id: 'kaktus',
    name: 'Kaktüs',
    emoji: '🌵',
    shape: PlantShape.cactus,
    maxHeightCm: 20,
    lightScores: [0.15, 0.55, 1.0],
    waterScores: [1.0, 0.5, 0.1],
    temperatureScores: [0.1, 0.8, 1.0],
    lightNote: 'Kaktüs çölde yaşar; bol güneşi sever.',
    waterNote:
        'Kaktüs gövdesinde su depolar, o yüzden çok az suyla yaşar; çok su onu çürütür.',
    temperatureNote: 'Kaktüs sıcağı sever; soğukta zarar görür.',
    funFact: 'Kaktüsün dikenleri aslında değişmiş yapraklardır.',
  ),
];
