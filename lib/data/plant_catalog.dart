import '../models/plant_species.dart';

/// Laboratuvardaki bitkiler. Skorlar dört etken için ayrı ayrı, üçer kademelidir:
/// ışık {karanlık, gölge, güneş}, su {az, orta, çok}, sıcaklık {5°, 20°, 35°},
/// yükseklik {alçak/deniz kenarı, orta/800 m, yüksek/2000 m}. 1.0 en uygun
/// kademe; her etkende tek bir en yüksek skor olmalı ve en az bir "belirgin
/// bozuk" (≤ 0.5) kademe bulunmalıdır (testler bunları doğrular; doktor turu
/// bozuk kademeyi ondan seçer).
///
/// Bu değerler ilkokul düzeyinde sadeleştirilmiş, genel bitki bilgisidir; bir
/// öğretmen/ebeveyn gözden geçirip skorları ya da cümleleri düzeltebilir —
/// büyüme modeli yalnızca bu tabloya bakar. Boy ([PlantSpecies.maxHeightCm])
/// 10 haftalık zaman atlamalı deneyin sonundaki fide/genç bitki boyudur.
///
/// **Yükseklik etkeni** en çok çay ve kahvede fark yaratır: kahve dağlık,
/// serin yerleri (yüksek), çay denize yakın ama çok yüksek olmayan nemli
/// yamaçları (orta), pirinç, muz ve narenciye ise alçak, sıcak yerleri sever.
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
    altitudeScores: [1.0, 0.8, 0.3],
    lightNote:
        'Fasulye güneşi çok sever; ışıkta yaprakları besin yapar ve boyu hızla uzar.',
    waterNote:
        'Fasulye toprağı nemli ister ama sulu istemez; çok su köklerin nefes almasını engeller.',
    temperatureNote:
        'Fasulye ılık havada en iyi büyür; soğukta çok yavaşlar, çok sıcakta ise yorulur.',
    altitudeNote:
        'Fasulye ovada ve orta yükseklikte rahat büyür; çok yüksek yerde hava serin olduğu için gelişimi yavaşlar.',
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
    altitudeScores: [0.8, 1.0, 0.4],
    lightNote:
        'Mercimek filizi ışık görünce yeşerir; ışıksız kalırsa soluk ve cılız olur.',
    waterNote:
        'Mercimek az suda susar, çok suda çürür; toprağı hafif nemli tutmak yeterlidir.',
    temperatureNote:
        'Mercimek ılık havayı sever; çok soğukta yavaşlar, çok sıcakta yorulur.',
    altitudeNote:
        'Mercimek Anadolu\'nun orta yükseklikteki ovalarında iyi yetişir; çok yüksekte soğuk ona zarar verir.',
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
    altitudeScores: [0.8, 1.0, 0.5],
    lightNote: 'Buğday fidesi bol ışıkta güçlü ve yeşil büyür.',
    waterNote:
        'Buğday toprağın hep ıslak kalmasını istemez; orta derecede nem yeterlidir.',
    temperatureNote:
        'Buğday serin ve ılık havayı sever; çok sıcakta zayıf düşer.',
    altitudeNote:
        'Buğday orta yükseklikteki geniş ovalarda iyi yetişir; çok yüksek ve soğuk yerde zayıf kalır.',
    funFact: 'Ekmeğin unu buğdaydan yapılır.',
  ),
  PlantSpecies(
    id: 'pirinc',
    name: 'Pirinç',
    emoji: '🍚',
    shape: PlantShape.grass,
    maxHeightCm: 80,
    lightScores: [0.05, 0.6, 1.0],
    waterScores: [0.1, 0.6, 1.0],
    temperatureScores: [0.1, 0.7, 1.0],
    altitudeScores: [1.0, 0.6, 0.15],
    lightNote: 'Pirinç bol güneş ister.',
    waterNote:
        'Pirinç tarlaları suyla kaplı olur; pirinç, çok suyu sevmesiyle diğer tahıllardan ayrılır.',
    temperatureNote:
        'Pirinç sıcak havayı sever; soğukta büyümesi çok yavaşlar.',
    altitudeNote:
        'Pirinç alçak ovalarda, suyla kaplanabilen tarlalarda yetişir; yüksek ve soğuk yerde zor büyür.',
    funFact: 'Pirinç, dünyada çok sayıda insanın temel yiyeceğidir.',
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
    altitudeScores: [1.0, 0.8, 0.3],
    lightNote: 'Ayçiçeği bol güneşte hızla uzar ve yüzünü güneşe çevirir.',
    waterNote:
        'Ayçiçeği orta miktarda su ister; sürekli ıslak toprağı sevmez.',
    temperatureNote:
        'Ayçiçeği sıcak havayı çok sever; soğukta çok yavaş büyür.',
    altitudeNote:
        'Ayçiçeği alçak ve sıcak ovaları sever; çok yüksekte serin havada zayıf kalır.',
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
    altitudeScores: [1.0, 0.8, 0.3],
    lightNote: 'Domates bol güneş ister; ışık azsa boyu ve meyvesi azalır.',
    waterNote:
        'Domates düzenli ve orta miktarda sulanmalıdır; çok su köklerini çürütebilir.',
    temperatureNote:
        'Domates ılık havada en iyi büyür; soğuk da aşırı sıcak da onu yorar.',
    altitudeNote:
        'Domates alçak ve orta yüksekliklerin sıcak yerlerinde iyi büyür; çok yükseklerde soğuk onu yorar.',
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
    altitudeScores: [0.8, 1.0, 0.5],
    lightNote:
        'Nane aydınlık ama çok yakıcı olmayan yerleri sever; gölgede de güneşte de büyür.',
    waterNote: 'Nane suyu sever; toprak kuruyunca hemen solar.',
    temperatureNote:
        'Nane ılık havada güzel büyür; soğukta yavaşlar, çok sıcakta yorulur.',
    altitudeNote:
        'Nane pek çok yerde yetişir ama en çok alçak ve orta yüksekliği sever; çok yükseklerde yavaşlar.',
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
    altitudeScores: [0.8, 1.0, 0.5],
    lightNote: 'Marul aydınlıkta iyi büyür ama gölgede de idare eder.',
    waterNote:
        'Marul yaprakları çok su tutar; toprağı düzenli nemli olmalı, ama fazla sudan da zarar görür.',
    temperatureNote:
        'Marul serin havayı sever; çok sıcakta büyümesi bozulur.',
    altitudeNote:
        'Marul orta yükseklikteki serin yerlerde iyi büyür; çok yükseklerde soğuk onu yavaşlatır.',
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
    altitudeScores: [1.0, 0.8, 0.4],
    lightNote: 'Kaktüs çölde yaşar; bol güneşi sever.',
    waterNote:
        'Kaktüs gövdesinde su depolar, o yüzden çok az suyla yaşar; çok su onu çürütür.',
    temperatureNote: 'Kaktüs sıcağı sever; soğukta zarar görür.',
    altitudeNote:
        'Kaktüs kurak, açık yerleri sever; çok yüksekteki soğuk ona uygun değildir.',
    funFact: 'Kaktüsün dikenleri aslında değişmiş yapraklardır.',
  ),
  PlantSpecies(
    id: 'cilek',
    name: 'Çilek',
    emoji: '🍓',
    shape: PlantShape.leafy,
    maxHeightCm: 25,
    lightScores: [0.1, 0.7, 1.0],
    waterScores: [0.3, 1.0, 0.5],
    temperatureScores: [0.5, 1.0, 0.35],
    altitudeScores: [0.9, 1.0, 0.5],
    lightNote: 'Çilek güneşi sever; ışık azsa az ve tatsız meyve verir.',
    waterNote:
        'Çileğin kökleri sığdır; toprağı düzenli nemli olmalı ama su birikmemeli.',
    temperatureNote:
        'Çilek serin ve ılık havayı sever; çok sıcakta yorulur.',
    altitudeNote:
        'Çilek orta yükseklikteki serin yerlerde çok güzel yetişir.',
    funFact: 'Çileğin çekirdekleri aslında meyvenin dışındadır.',
  ),
  PlantSpecies(
    id: 'limon',
    name: 'Limon',
    emoji: '🍋',
    shape: PlantShape.leafy,
    maxHeightCm: 90,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.3, 1.0, 0.5],
    temperatureScores: [0.05, 0.85, 1.0],
    altitudeScores: [1.0, 0.7, 0.15],
    lightNote: 'Limon ağacı bol güneş ister.',
    waterNote:
        'Limon ağacı orta miktarda su sever; kökleri çok suda çürür.',
    temperatureNote:
        'Limon sıcak ve ılık havayı sever; soğukta, özellikle donda zarar görür.',
    altitudeNote:
        'Limon deniz kenarındaki alçak, ılık yerlerde iyi yetişir; yüksek ve soğuk yerde zor büyür.',
    funFact: 'Limon ağacı yıl boyu çiçek ve meyve verebilir.',
  ),
  PlantSpecies(
    id: 'portakal',
    name: 'Portakal',
    emoji: '🍊',
    shape: PlantShape.leafy,
    maxHeightCm: 90,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.3, 1.0, 0.5],
    temperatureScores: [0.05, 0.85, 1.0],
    altitudeScores: [1.0, 0.7, 0.15],
    lightNote: 'Portakal ağacı bol güneş ister.',
    waterNote:
        'Portakal orta miktarda su ister; çok su köklerine zarar verir.',
    temperatureNote:
        'Portakal ılık ve sıcak havayı sever; don ona zarar verir.',
    altitudeNote:
        'Portakal deniz kenarındaki alçak, ılık yerlerde iyi yetişir.',
    funFact: 'Portakal C vitamini bakımından zengindir.',
  ),
  PlantSpecies(
    id: 'karpuz',
    name: 'Karpuz',
    emoji: '🍉',
    shape: PlantShape.leafy,
    maxHeightCm: 120,
    lightScores: [0.05, 0.5, 1.0],
    waterScores: [0.3, 1.0, 0.5],
    temperatureScores: [0.05, 0.7, 1.0],
    altitudeScores: [1.0, 0.8, 0.2],
    lightNote: 'Karpuz sıcak güneşi çok sever.',
    waterNote:
        'Karpuz düzenli sulanır ama su birikmesinden hoşlanmaz; meyvesinin çoğu sudur.',
    temperatureNote: 'Karpuz sıcak havayı sever; soğukta büyümez.',
    altitudeNote:
        'Karpuz alçak ve sıcak ovalarda iyi yetişir; yükseğin serin havasını sevmez.',
    funFact: 'Karpuzun yüzde doksandan fazlası sudur.',
  ),
  PlantSpecies(
    id: 'seftali',
    name: 'Şeftali',
    emoji: '🍑',
    shape: PlantShape.leafy,
    maxHeightCm: 100,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.3, 1.0, 0.4],
    temperatureScores: [0.4, 1.0, 0.5],
    altitudeScores: [0.7, 1.0, 0.5],
    lightNote: 'Şeftali ağacı güneşte tatlı meyve verir.',
    waterNote:
        'Şeftali orta miktarda su ister; çok su köklerini çürütür.',
    temperatureNote:
        'Şeftali ılık havayı sever; çok soğuk da çok sıcak da onu yorar.',
    altitudeNote:
        'Şeftali orta yükseklikteki serin ve güneşli yerlerde iyi yetişir.',
    funFact: 'Şeftalinin çekirdeği sert bir kabukla korunur.',
  ),
  PlantSpecies(
    id: 'muz',
    name: 'Muz',
    emoji: '🍌',
    shape: PlantShape.leafy,
    maxHeightCm: 180,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.2, 0.7, 1.0],
    temperatureScores: [0.05, 0.7, 1.0],
    altitudeScores: [1.0, 0.6, 0.1],
    lightNote: 'Muz bol ışık ister.',
    waterNote:
        'Muzun büyük yaprakları çok su kullanır; muz bol suyu sever.',
    temperatureNote:
        'Muz tropik bir bitkidir; sıcak ve nemli havayı sever, soğukta zarar görür.',
    altitudeNote:
        'Muz alçak, sıcak yerlerde yetişir; yüksek ve serin yerde büyüyemez.',
    funFact: 'Muz ağacı aslında bir ağaç değil, dev bir ottur.',
  ),
  PlantSpecies(
    id: 'cay',
    name: 'Çay',
    emoji: '🍵',
    shape: PlantShape.leafy,
    maxHeightCm: 60,
    lightScores: [0.15, 1.0, 0.8],
    waterScores: [0.2, 0.8, 1.0],
    temperatureScores: [0.4, 1.0, 0.6],
    altitudeScores: [0.7, 1.0, 0.5],
    lightNote:
        'Çay bitkisi yumuşak, gölgeli ışığı sever; çok yakıcı güneşte yaprakları yorulur.',
    waterNote: 'Çay bitkisi bol yağmuru ve nemli havayı sever.',
    temperatureNote: 'Çay ılık ve nemli havayı sever; dona dayanamaz.',
    altitudeNote:
        'Çay, Karadeniz\'in denize yakın ama çok yüksek olmayan nemli yamaçlarında iyi yetişir.',
    funFact: 'Çayın taze yaprakları toplanıp kurutularak demlik çay olur.',
  ),
  PlantSpecies(
    id: 'kahve',
    name: 'Kahve',
    emoji: '☕',
    shape: PlantShape.leafy,
    maxHeightCm: 60,
    lightScores: [0.2, 1.0, 0.7],
    waterScores: [0.25, 1.0, 0.5],
    temperatureScores: [0.4, 1.0, 0.35],
    altitudeScores: [0.3, 0.8, 1.0],
    lightNote:
        'Kahve ağacı yumuşak, gölgeli ışığı sever; büyük ağaçların altında yetişir.',
    waterNote:
        'Kahve düzenli yağmur ister; toprak çok ıslak kalırsa köklerine zarar gelir.',
    temperatureNote:
        'Kahve serin-ılık havayı sever; çok sıcakta ve donda zarar görür.',
    altitudeNote:
        'Kahve dağlık, yüksek yerlerde daha iyi yetişir; çünkü orada hava daha serindir.',
    funFact: 'Kahvenin çekirdeği aslında bir meyvenin içindeki tohumdur.',
  ),
  PlantSpecies(
    id: 'patates',
    name: 'Patates',
    emoji: '🥔',
    shape: PlantShape.leafy,
    maxHeightCm: 50,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.3, 1.0, 0.4],
    temperatureScores: [0.4, 1.0, 0.25],
    altitudeScores: [0.6, 1.0, 0.5],
    lightNote:
        'Patates yaprakları güneşte besin yapar ve yumruları büyütür.',
    waterNote:
        'Patates orta miktarda su ister; çok su yumrularını çürütür.',
    temperatureNote:
        'Patates serin havayı sever; çok sıcakta yumruları küçük kalır.',
    altitudeNote:
        'Patates orta yükseklikteki serin ovalarda çok iyi yetişir.',
    funFact: 'Patates, kökü değil gövdesi kalınlaşmış bir yumrudur.',
  ),
  PlantSpecies(
    id: 'misir',
    name: 'Mısır',
    emoji: '🌽',
    shape: PlantShape.leafy,
    maxHeightCm: 150,
    lightScores: [0.05, 0.5, 1.0],
    waterScores: [0.3, 1.0, 0.5],
    temperatureScores: [0.1, 0.75, 1.0],
    altitudeScores: [1.0, 0.8, 0.3],
    lightNote: 'Mısır bol güneş ister.',
    waterNote:
        'Mısır orta miktarda su ister; çok kuru ya da çok sulu toprağı sevmez.',
    temperatureNote: 'Mısır sıcak havayı sever; soğukta çok yavaş büyür.',
    altitudeNote:
        'Mısır alçak ve orta yükseklikteki sıcak yerlerde iyi yetişir.',
    funFact: 'Mısır koçanında yüzlerce tane bulunur.',
  ),
  PlantSpecies(
    id: 'salatalik',
    name: 'Salatalık',
    emoji: '🥒',
    shape: PlantShape.leafy,
    maxHeightCm: 100,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.2, 1.0, 0.6],
    temperatureScores: [0.05, 0.8, 1.0],
    altitudeScores: [1.0, 0.7, 0.2],
    lightNote: 'Salatalık bol ışık ister.',
    waterNote:
        'Salatalık çok su sever; toprak kuruyunca yaprakları hemen sarkar.',
    temperatureNote: 'Salatalık sıcak havayı sever; soğuğa dayanamaz.',
    altitudeNote:
        'Salatalık alçak ve sıcak yerlerde iyi büyür; yüksekte serin hava onu yorar.',
    funFact: 'Salatalığın çoğu sudur.',
  ),
  PlantSpecies(
    id: 'biber',
    name: 'Biber',
    emoji: '🌶️',
    shape: PlantShape.leafy,
    maxHeightCm: 50,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.3, 1.0, 0.4],
    temperatureScores: [0.1, 0.8, 1.0],
    altitudeScores: [1.0, 0.8, 0.25],
    lightNote: 'Biber güneşi sever.',
    waterNote: 'Biber orta miktarda su ister; çok su köklerini yorar.',
    temperatureNote:
        'Biber sıcak havayı sever; soğukta çiçek ve meyve vermez.',
    altitudeNote: 'Biber alçak ve sıcak yerlerde iyi yetişir.',
    funFact: 'Acı biberdeki acılık, biberin içindeki bir maddeden gelir.',
  ),
  PlantSpecies(
    id: 'havuc',
    name: 'Havuç',
    emoji: '🥕',
    shape: PlantShape.leafy,
    maxHeightCm: 30,
    lightScores: [0.2, 0.7, 1.0],
    waterScores: [0.3, 1.0, 0.5],
    temperatureScores: [0.5, 1.0, 0.3],
    altitudeScores: [0.9, 1.0, 0.5],
    lightNote:
        'Havuç yaprakları ışıkta besin yapıp kökünü büyütür.',
    waterNote:
        'Havuç orta miktarda su ister; hep ıslak toprakta kökü çatlar ve çürür.',
    temperatureNote:
        'Havuç serin ve ılık havayı sever; çok sıcakta kökü iyi gelişmez.',
    altitudeNote: 'Havuç alçak ve orta yüksekliklerde iyi yetişir.',
    funFact: 'Yediğimiz havuç, bitkinin kalınlaşmış köküdür.',
  ),
  PlantSpecies(
    id: 'ispanak',
    name: 'Ispanak',
    emoji: '🍃',
    shape: PlantShape.leafy,
    maxHeightCm: 20,
    lightScores: [0.15, 0.8, 1.0],
    waterScores: [0.3, 1.0, 0.5],
    temperatureScores: [0.7, 1.0, 0.15],
    altitudeScores: [0.8, 1.0, 0.5],
    lightNote:
        'Ispanak ışıkta güçlü yapraklar çıkarır; gölgede de idare eder.',
    waterNote: 'Ispanak düzenli nemli toprak ister.',
    temperatureNote:
        'Ispanak serin havayı sever; hava ısınınca büyümesi bozulur.',
    altitudeNote:
        'Ispanak alçak ve orta yüksekliklerin serin yerlerinde iyi büyür.',
    funFact: 'Ispanak, yaprağını yediğimiz bir sebzedir.',
  ),
  PlantSpecies(
    id: 'nohut',
    name: 'Nohut',
    emoji: '🌱',
    shape: PlantShape.leafy,
    maxHeightCm: 45,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.4, 1.0, 0.3],
    temperatureScores: [0.4, 1.0, 0.5],
    altitudeScores: [0.7, 1.0, 0.5],
    lightNote: 'Nohut güneşli yerleri sever.',
    waterNote:
        'Nohut susuzluğa oldukça dayanıklıdır; ama çok su köklerini çürütür.',
    temperatureNote:
        'Nohut ılık havayı sever; çok soğuk ve çok sıcak büyümesini yavaşlatır.',
    altitudeNote:
        'Nohut Anadolu\'nun orta yükseklikteki ovalarında yetişir.',
    funFact: 'Nohut, mercimek gibi bir baklagildir.',
  ),
  PlantSpecies(
    id: 'zeytin',
    name: 'Zeytin',
    emoji: '🫒',
    shape: PlantShape.leafy,
    maxHeightCm: 80,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.5, 1.0, 0.3],
    temperatureScores: [0.3, 1.0, 0.6],
    altitudeScores: [1.0, 0.7, 0.2],
    lightNote: 'Zeytin ağacı bol güneş ister.',
    waterNote:
        'Zeytin susuzluğa oldukça dayanıklıdır; ama çok su köklerine zarar verir.',
    temperatureNote:
        'Zeytin ılık, güneşli havayı sever; sert soğuk onu yorar.',
    altitudeNote:
        'Zeytin Ege ve Akdeniz kıyısının alçak yerlerinde yetişir; yüksek ve soğuk yerde zor büyür.',
    funFact: 'Zeytin ağaçları yüzlerce yıl yaşayabilir.',
  ),
  PlantSpecies(
    id: 'findik',
    name: 'Fındık',
    emoji: '🌰',
    shape: PlantShape.leafy,
    maxHeightCm: 80,
    lightScores: [0.1, 0.8, 1.0],
    waterScores: [0.3, 1.0, 0.6],
    temperatureScores: [0.4, 1.0, 0.4],
    altitudeScores: [1.0, 0.8, 0.3],
    lightNote: 'Fındık güneşi sever ama serin, nemli yamaçlarda da yetişir.',
    waterNote:
        'Fındık yağışlı bölgeleri sever; ama toprakta su birikmesi köklerini yorar.',
    temperatureNote:
        'Fındık ılık ve nemli havayı sever; çok soğukta ve çok sıcakta yorulur.',
    altitudeNote:
        'Fındık Karadeniz kıyısında, denizden çok yüksek olmayan yamaçlarda yetişir.',
    funFact: 'Türkiye dünyada çok fındık üreten bir ülkedir.',
  ),
  PlantSpecies(
    id: 'uzum',
    name: 'Üzüm',
    emoji: '🍇',
    shape: PlantShape.leafy,
    maxHeightCm: 150,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.4, 1.0, 0.3],
    temperatureScores: [0.3, 0.9, 1.0],
    altitudeScores: [0.8, 1.0, 0.5],
    lightNote: 'Asma bol güneş ister; güneş azsa üzümler tatlanmaz.',
    waterNote: 'Asma orta miktarda su ister; çok su köklerine zarar verir.',
    temperatureNote:
        'Asma sıcak ve güneşli yazları sever; soğukta gelişmez.',
    altitudeNote:
        'Asma alçak ve orta yüksekliklerde, güneşli yamaçlarda iyi yetişir.',
    funFact: 'Üzüm kurutulunca kuru üzüm olur.',
  ),
  PlantSpecies(
    id: 'elma',
    name: 'Elma',
    emoji: '🍎',
    shape: PlantShape.leafy,
    maxHeightCm: 100,
    lightScores: [0.1, 0.6, 1.0],
    waterScores: [0.3, 1.0, 0.5],
    temperatureScores: [0.6, 1.0, 0.3],
    altitudeScores: [0.5, 1.0, 0.7],
    lightNote: 'Elma ağacı güneşte iyi meyve verir.',
    waterNote: 'Elma orta miktarda su ister; çok su köklerini çürütür.',
    temperatureNote: 'Elma serin ve ılık havayı sever; çok sıcak onu yorar.',
    altitudeNote:
        'Elma, Anadolu\'nun orta ve yüksek serin yerlerinde çok iyi yetişir.',
    funFact: 'Elma ağacının çiçeklerini arılar tozlaştırır.',
  ),
];
