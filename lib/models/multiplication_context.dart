import 'multiplication_difficulty.dart';

/// Bir çarpmanın gerçek hayatta karşımıza çıkış *biçimi*.
///
/// Oyunun tamamı hâlâ tek bir görsel üzerine kurulu (dikdörtgen dizi) — asıl
/// fikir zaten bu: birbirinden çok farklı görünen bu yedi durum aslında aynı
/// dikdörtgendir. Tür yalnızca (a) cümlelerin nasıl kurulduğunu ve (b)
/// ızgaraya grup/başlık emojisi eklenip eklenmediğini değiştirir; çarpma
/// mantığı her türde birebir aynıdır.
enum MultiplicationContextKind {
  /// Nesnelerin zaten sıra sıra dizili olduğu sahneler: yumurta kolisi,
  /// sinema koltukları, çikolata kareleri.
  dizi,

  /// "Her X'te Y tane" — eşit gruplar. Çocukların okulda ilk karşılaştığı
  /// model; her sıra bir grubu temsil eder ve sıranın başına grup emojisi
  /// konur (5 bisiklet, her birinde 2 tekerlek).
  esitGrup,

  /// Birim fiyat: "bir tanesi {c} TL, {r} tanesi kaç TL?". Sayılan şey artık
  /// nesne değil para — çarpmanın nesne saymaktan ibaret olmadığını gösterir.
  para,

  /// Zaman: "{r} hafta kaç gün?". Yine sayılamayan bir büyüklük.
  zaman,

  /// Alan modeli: kenar × kenar = kare sayısı. Dizi modelinin doğal devamı ve
  /// ilerideki metrekare/alan konusuna köprü.
  alan,

  /// Kartezyen çarpım: {r} tişört × {c} pantolon = {n} farklı kombinasyon.
  /// Ortada sayılacak {n} nesne yoktur; dizi onları *üretir*.
  kombinasyon,

  /// Kat kat karşılaştırma: "onun {r} katı kadar". Çarpmanın "kat" anlamı.
  karsilastirma,
}

/// Tek bir gerçek hayat sahnesi ve o sahnenin Türkçe cümleleri.
///
/// **Cümleler neden şablon metin olarak saklanıyor?** Türkçe ek uyumu
/// yüzünden. `SimonTrial.instructionText` için alınan kararın aynısı burada
/// da geçerli: değişken bir kelimeye çalışma zamanında ek getirmeye
/// çalışılmaz. Burada bir adım daha ileri gidiliyor — cümlenin tamamı sahne
/// için elle yazılıyor, koda yalnızca sayı yerleştirme kalıyor. Böylece
/// "kolide"/"tepside"/"kümeste" gibi hiçbir ek üretilmiyor, sadece
/// `{r}` (sıra), `{c}` (sütun) ve `{n}` (sonuç) yer tutucuları doldruluyor.
class MultiplicationContext {
  const MultiplicationContext({
    required this.id,
    required this.kind,
    required this.title,
    required this.emoji,
    required this.levels,
    required this.question,
    required this.grouping,
    required this.conclusion,
    this.buildPrompt,
    this.groupEmoji,
    this.columnHeaderEmoji,
    this.fixedColumns,
    this.unit = '',
  });

  /// Testlerde/hata ayıklamada sahneyi tanımlayan kısa anahtar.
  final String id;

  final MultiplicationContextKind kind;

  /// Kurulum ekranında örnek olarak listelenen kısa ad ("Yumurta kolisi").
  final String title;

  /// Izgaranın her hücresinde çizilen nesne.
  final String emoji;

  /// Bu sahnenin sunulduğu zorluk seviyeleri.
  final Set<MultiplicationDifficulty> levels;

  /// Okuma turunun soru cümlesi. `{r}` ve `{c}` doldurulur.
  final String question;

  /// Açıklama panelindeki "ne vardı" cümlesi: "5 bisiklet, her birinde 2
  /// tekerlek".
  final String grouping;

  /// Açıklama panelinin kapanış cümlesi; `{n}` sonucu içerir.
  final String conclusion;

  /// Kurma turunun yönergesi. `null` ise bu sahne kurma turunda kullanılmaz —
  /// bazı sahnelerde (para, zaman, kat karşılaştırma) "bunu sen kur" cümlesi
  /// zorlama kaçıyor, sahne yalnızca okuma turlarında çıkıyor.
  final String? buildPrompt;

  /// Eşit grup / kombinasyon sahnelerinde her sıranın başına konan emoji:
  /// sıranın bir *grup* olduğunu görünür kılar (🚲 → 🛞 🛞).
  final String? groupEmoji;

  /// Yalnızca kombinasyon sahnelerinde: sütunların üstüne konan ikinci
  /// kümenin emojisi (👕 sıralar × 👖 sütunlar).
  final String? columnHeaderEmoji;

  /// Sahnenin doğasından gelen sabit sütun sayısı (bisiklet 2 tekerlek,
  /// örümcek 8 bacak, hafta 7 gün). Verildiğinde tur üreticisi yalnızca sıra
  /// sayısını rastgele seçer — "her bisiklette 3 tekerlek" saçma olurdu.
  final int? fixedColumns;

  /// Toplamın birimi (" TL", " gün", " m²"). Boşsa sayı çıplak yazılır.
  final String unit;

  /// Kurma turunda kullanılabilir mi.
  bool get isBuildable => buildPrompt != null;

  /// Sahnenin ilk kez sunulduğu seviye. [MultiplicationController] tur
  /// üretirken seviyeye *yeni gelen* sahneleri havuzda iki kez sayıyor: bir
  /// seviyenin karakterini o seviyede açılan sahneler belirliyor (Zor'da alan
  /// ve kombinasyon gibi), ama alt seviyelerden taşınan sahneler sayıca fazla
  /// olduğu için düz rastgele seçimde yeni sahneler sekiz turluk bir oyunda
  /// hiç çıkmayabiliyordu.
  MultiplicationDifficulty get introducedAt => levels.reduce(
    (a, b) => a.index <= b.index ? a : b,
  );

  String _fill(String template, int rows, int columns) => template
      .replaceAll('{r}', '$rows')
      .replaceAll('{c}', '$columns')
      .replaceAll('{n}', '${rows * columns}');

  String questionFor(int rows, int columns) => _fill(question, rows, columns);

  String groupingFor(int rows, int columns) => _fill(grouping, rows, columns);

  String conclusionFor(int rows, int columns) =>
      _fill(conclusion, rows, columns);

  String? buildPromptFor(int rows, int columns) =>
      buildPrompt == null ? null : _fill(buildPrompt!, rows, columns);
}

const Set<MultiplicationDifficulty> _kolay = {MultiplicationDifficulty.kolay};
const Set<MultiplicationDifficulty> _kolayOrta = {
  MultiplicationDifficulty.kolay,
  MultiplicationDifficulty.orta,
};
const Set<MultiplicationDifficulty> _ortaZor = {
  MultiplicationDifficulty.orta,
  MultiplicationDifficulty.zor,
};
const Set<MultiplicationDifficulty> _zor = {MultiplicationDifficulty.zor};

/// Oyunun gerçek hayat sahneleri.
///
/// Seviyeye dağılım rastgele değil, sahnenin *bilişsel* zorluğuna göre:
///
/// - **Kolay**: sayılabilir, elle tutulur, günlük — ve çoğunda sütun sayısı
///   doğadan sabit (bisikletin 2 tekerleği, elin 5 parmağı). Sabit sütun
///   çocuğa "her seferinde aynı sayıda" fikrini bedava veriyor.
/// - **Orta**: daha büyük diziler, daha büyük sabit gruplar (örümcek 8) ve
///   ilk soyutlamalar: para ve zaman. Burada artık nesne saymıyoruz.
/// - **Zor**: alan modeli (kenar × kenar), kombinasyon (ortada sayılacak
///   nesne bile yok) ve kat kat karşılaştırma. Üçü de çarpmanın "tekrarlı
///   toplama" tanımının ötesine geçtiği yerler.
const List<MultiplicationContext> multiplicationContexts = [
  // ---------------------------------------------------------------- KOLAY --
  MultiplicationContext(
    id: 'bisiklet',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Bisiklet tekerlekleri',
    emoji: '🛞',
    groupEmoji: '🚲',
    fixedColumns: 2,
    levels: _kolayOrta,
    question:
        'Garajda {r} bisiklet var. Her bisikletin {c} tekerleği var. '
        'Toplam kaç tekerlek var?',
    grouping: '{r} bisiklet, her birinde {c} tekerlek',
    conclusion: '{r} bisikletin toplam {n} tekerleği var.',
    buildPrompt:
        'Her bisikletin {c} tekerleği var. {r} bisikletin tekerleklerini diz.',
  ),
  MultiplicationContext(
    id: 'ayakkabi',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Ayakkabı çiftleri',
    emoji: '👟',
    groupEmoji: '👣',
    fixedColumns: 2,
    levels: _kolay,
    question:
        'Dolapta {r} çift ayakkabı var. Her çift {c} tekten oluşur. '
        'Dolapta kaç tek ayakkabı var?',
    grouping: '{r} çift, her çiftte {c} tek ayakkabı',
    conclusion: '{r} çift ayakkabı {n} tek eder.',
    buildPrompt: 'Her çiftte {c} tek var. {r} çift ayakkabıyı diz.',
  ),
  MultiplicationContext(
    id: 'tavuk',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Kümesteki tavuklar',
    emoji: '🦶',
    groupEmoji: '🐔',
    fixedColumns: 2,
    levels: _kolay,
    question:
        'Kümeste {r} tavuk var. Her tavuğun {c} ayağı var. '
        'Toplam kaç ayak var?',
    grouping: '{r} tavuk, her birinde {c} ayak',
    conclusion: '{r} tavuğun toplam {n} ayağı var.',
    buildPrompt: 'Her tavuğun {c} ayağı var. {r} tavuğun ayaklarını diz.',
  ),
  MultiplicationContext(
    id: 'araba',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Araba tekerlekleri',
    emoji: '🛞',
    groupEmoji: '🚗',
    fixedColumns: 4,
    levels: _kolayOrta,
    question:
        'Yolda {r} araba var. Her arabanın {c} tekerleği var. '
        'Toplam kaç tekerlek var?',
    grouping: '{r} araba, her birinde {c} tekerlek',
    conclusion: '{r} arabanın toplam {n} tekerleği var.',
    buildPrompt:
        'Her arabanın {c} tekerleği var. {r} arabanın tekerleklerini diz.',
  ),
  MultiplicationContext(
    id: 'parmak',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Eldeki parmaklar',
    emoji: '👆',
    groupEmoji: '✋',
    fixedColumns: 5,
    levels: _kolayOrta,
    question:
        'Havada {r} el var. Her elde {c} parmak var. Toplam kaç parmak var?',
    grouping: '{r} el, her elde {c} parmak',
    conclusion: '{r} elde toplam {n} parmak var.',
    buildPrompt: 'Her elde {c} parmak var. {r} elin parmaklarını diz.',
  ),
  MultiplicationContext(
    id: 'yumurta',
    kind: MultiplicationContextKind.dizi,
    title: 'Yumurta kolisi',
    emoji: '🥚',
    levels: _kolayOrta,
    question:
        'Yumurta kolisinde {r} sıra var, her sırada {c} yumurta. '
        'Kolide toplam kaç yumurta var?',
    grouping: '{r} sıra, her sırada {c} yumurta',
    conclusion: 'Kolide {n} yumurta var.',
    buildPrompt: 'Koliye {r} sıra aç, her sıraya {c} yumurta koy.',
  ),
  MultiplicationContext(
    id: 'kurabiye',
    kind: MultiplicationContextKind.dizi,
    title: 'Kurabiye tepsisi',
    emoji: '🍪',
    levels: _kolayOrta,
    question:
        'Fırın tepsisinde {r} sıra kurabiye var, her sırada {c} tane. '
        'Tepside kaç kurabiye var?',
    grouping: '{r} sıra, her sırada {c} kurabiye',
    conclusion: 'Tepside {n} kurabiye var.',
    buildPrompt: 'Tepsiye {r} sıra diz, her sıraya {c} kurabiye koy.',
  ),
  MultiplicationContext(
    id: 'kek',
    kind: MultiplicationContextKind.dizi,
    title: 'Kek kalıbı',
    emoji: '🧁',
    levels: _kolay,
    question:
        'Kek kalıbında {r} sıra göz var, her sırada {c} göz. '
        'Kalıpta kaç kek pişer?',
    grouping: '{r} sıra, her sırada {c} göz',
    conclusion: 'Kalıpta {n} kek pişer.',
    buildPrompt: 'Kalıba {r} sıra aç, her sıraya {c} kek koy.',
  ),
  MultiplicationContext(
    id: 'elma',
    kind: MultiplicationContextKind.dizi,
    title: 'Meyve kasası',
    emoji: '🍎',
    levels: _kolayOrta,
    question:
        'Kasada {r} sıra elma var, her sırada {c} elma. '
        'Kasada kaç elma var?',
    grouping: '{r} sıra, her sırada {c} elma',
    conclusion: 'Kasada {n} elma var.',
    buildPrompt: 'Kasaya {r} sıra diz, her sıraya {c} elma koy.',
  ),
  MultiplicationContext(
    id: 'lale',
    kind: MultiplicationContextKind.dizi,
    title: 'Lale tarhı',
    emoji: '🌷',
    levels: _kolayOrta,
    question:
        'Bahçedeki tarhta {r} sıra lale var, her sırada {c} lale. '
        'Tarhta kaç lale var?',
    grouping: '{r} sıra, her sırada {c} lale',
    conclusion: 'Tarhta {n} lale var.',
    buildPrompt: 'Tarha {r} sıra ek, her sıraya {c} lale koy.',
  ),

  // ----------------------------------------------------------------- ORTA --
  MultiplicationContext(
    id: 'orumcek',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Örümcek bacakları',
    emoji: '🦵',
    groupEmoji: '🕷️',
    fixedColumns: 8,
    levels: _ortaZor,
    question:
        'Tavan arasında {r} örümcek var. Her örümceğin {c} bacağı var. '
        'Toplam kaç bacak var?',
    grouping: '{r} örümcek, her birinde {c} bacak',
    conclusion: '{r} örümceğin toplam {n} bacağı var.',
    buildPrompt: 'Her örümceğin {c} bacağı var. {r} örümceğin bacaklarını diz.',
  ),
  MultiplicationContext(
    id: 'ahtapot',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Ahtapot kolları',
    emoji: '➰',
    groupEmoji: '🐙',
    fixedColumns: 8,
    levels: _ortaZor,
    question:
        'Akvaryumda {r} ahtapot var. Her ahtapotun {c} kolu var. '
        'Toplam kaç kol var?',
    grouping: '{r} ahtapot, her birinde {c} kol',
    conclusion: '{r} ahtapotun toplam {n} kolu var.',
    buildPrompt: 'Her ahtapotun {c} kolu var. {r} ahtapotun kollarını diz.',
  ),
  MultiplicationContext(
    id: 'seker',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Kutulardaki şekerler',
    emoji: '🍬',
    groupEmoji: '🎁',
    levels: _ortaZor,
    question:
        'Rafta {r} kutu var. Her kutuda {c} şeker var. Toplam kaç şeker var?',
    grouping: '{r} kutu, her kutuda {c} şeker',
    conclusion: '{r} kutuda toplam {n} şeker var.',
    buildPrompt: 'Her kutuya {c} şeker koy. {r} kutuyu doldur.',
  ),
  MultiplicationContext(
    id: 'buket',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Çiçek buketleri',
    emoji: '🌹',
    groupEmoji: '💐',
    levels: _ortaZor,
    question:
        'Vitrinde {r} buket var. Her bukette {c} gül var. Toplam kaç gül var?',
    grouping: '{r} buket, her bukette {c} gül',
    conclusion: '{r} bukette toplam {n} gül var.',
    buildPrompt: 'Her bukete {c} gül koy. {r} buketi hazırla.',
  ),
  MultiplicationContext(
    id: 'grup',
    kind: MultiplicationContextKind.esitGrup,
    title: 'Sınıftaki gruplar',
    emoji: '🧒',
    groupEmoji: '👥',
    levels: _ortaZor,
    question:
        'Sınıf {r} gruba ayrıldı. Her grupta {c} öğrenci var. '
        'Sınıfta kaç öğrenci var?',
    grouping: '{r} grup, her grupta {c} öğrenci',
    conclusion: 'Sınıfta toplam {n} öğrenci var.',
    buildPrompt: 'Her gruba {c} öğrenci yerleştir. {r} grubu kur.',
  ),
  MultiplicationContext(
    id: 'sinema',
    kind: MultiplicationContextKind.dizi,
    title: 'Sinema koltukları',
    emoji: '💺',
    levels: _ortaZor,
    question:
        'Sinema salonunda {r} sıra var, her sırada {c} koltuk. '
        'Salonda kaç koltuk var?',
    grouping: '{r} sıra, her sırada {c} koltuk',
    conclusion: 'Salonda {n} koltuk var.',
    buildPrompt: 'Salona {r} sıra diz, her sıraya {c} koltuk koy.',
  ),
  MultiplicationContext(
    id: 'otopark',
    kind: MultiplicationContextKind.dizi,
    title: 'Otopark',
    emoji: '🚗',
    levels: _ortaZor,
    question:
        'Otoparkta {r} sıra var, her sırada {c} araba park etmiş. '
        'Otoparkta kaç araba var?',
    grouping: '{r} sıra, her sırada {c} araba',
    conclusion: 'Otoparkta {n} araba var.',
    buildPrompt: 'Otoparka {r} sıra çiz, her sıraya {c} araba park et.',
  ),
  MultiplicationContext(
    id: 'pencere',
    kind: MultiplicationContextKind.dizi,
    title: 'Apartman pencereleri',
    emoji: '🪟',
    levels: _ortaZor,
    question:
        'Apartmanın {r} katı var, her katta {c} pencere. '
        'Binada kaç pencere var?',
    grouping: '{r} kat, her katta {c} pencere',
    conclusion: 'Binada {n} pencere var.',
    buildPrompt: 'Binaya {r} kat çık, her kata {c} pencere koy.',
  ),
  MultiplicationContext(
    id: 'kitaplik',
    kind: MultiplicationContextKind.dizi,
    title: 'Kitaplık rafları',
    emoji: '📚',
    levels: _ortaZor,
    question:
        'Kitaplıkta {r} raf var, her rafta {c} kitap. '
        'Kitaplıkta kaç kitap var?',
    grouping: '{r} raf, her rafta {c} kitap',
    conclusion: 'Kitaplıkta {n} kitap var.',
    buildPrompt: 'Kitaplığa {r} raf yap, her rafa {c} kitap diz.',
  ),
  MultiplicationContext(
    id: 'cikolata',
    kind: MultiplicationContextKind.dizi,
    title: 'Çikolata kareleri',
    emoji: '🟫',
    levels: _ortaZor,
    question:
        'Çikolata tabletinde {r} sıra var, her sırada {c} kare. '
        'Tablette kaç kare var?',
    grouping: '{r} sıra, her sırada {c} kare',
    conclusion: 'Tablette {n} kare çikolata var.',
    buildPrompt: 'Tablete {r} sıra yap, her sıraya {c} kare koy.',
  ),
  MultiplicationContext(
    id: 'fide',
    kind: MultiplicationContextKind.dizi,
    title: 'Domates tarlası',
    emoji: '🍅',
    levels: _ortaZor,
    question:
        'Tarlada {r} sıra domates fidesi var, her sırada {c} fide. '
        'Tarlada kaç fide var?',
    grouping: '{r} sıra, her sırada {c} fide',
    conclusion: 'Tarlada {n} fide var.',
    buildPrompt: 'Tarlaya {r} sıra aç, her sıraya {c} fide dik.',
  ),
  MultiplicationContext(
    id: 'lolipop',
    kind: MultiplicationContextKind.para,
    title: 'Lolipop fiyatı',
    emoji: '🪙',
    groupEmoji: '🍭',
    unit: ' TL',
    levels: _ortaZor,
    question:
        'Bir lolipop {c} TL. {r} lolipop almak kaç TL tutar?',
    grouping: '{r} lolipop, her biri {c} TL',
    conclusion: '{r} lolipop {n} TL tutar.',
  ),
  MultiplicationContext(
    id: 'kumbara',
    kind: MultiplicationContextKind.para,
    title: 'Kumbaraya biriktirmek',
    emoji: '🪙',
    groupEmoji: '💰',
    unit: ' TL',
    levels: _ortaZor,
    // Sahne bilerek "kumbarada {c} TL'lik {r} banknot" değil: çarpanlar
    // rastgele üretildiği için orada 6 TL, 11 TL gibi var olmayan banknotlar
    // çıkıyordu. Haftalık birikim her sayı için gerçekçi kalıyor.
    question:
        'Ayşe {r} hafta boyunca kumbarasına her hafta {c} TL attı. '
        'Kumbarada toplam kaç TL var?',
    grouping: '{r} hafta, her hafta {c} TL',
    conclusion: 'Kumbarada {n} TL birikmiş.',
  ),
  MultiplicationContext(
    id: 'hafta',
    kind: MultiplicationContextKind.zaman,
    title: 'Haftalar ve günler',
    emoji: '📆',
    groupEmoji: '📅',
    fixedColumns: 7,
    unit: ' gün',
    levels: _ortaZor,
    question:
        'Bir hafta {c} gündür. {r} hafta kaç gün eder?',
    grouping: '{r} hafta, her hafta {c} gün',
    conclusion: '{r} hafta {n} gün eder.',
  ),

  // ------------------------------------------------------------------ ZOR --
  MultiplicationContext(
    id: 'fayans',
    kind: MultiplicationContextKind.alan,
    title: 'Zemin fayansları',
    emoji: '🟦',
    levels: _zor,
    question:
        'Mutfağın zemini {r} sıra ve {c} sütun fayansla kaplanmış. '
        'Zeminde kaç fayans var?',
    grouping: '{r} sıra, her sırada {c} fayans',
    conclusion: 'Zeminde {n} fayans var.',
    buildPrompt: 'Zemini {r} sıra ve {c} sütun fayansla kapla.',
  ),
  MultiplicationContext(
    id: 'hali',
    kind: MultiplicationContextKind.alan,
    title: 'Halının alanı',
    emoji: '🟩',
    unit: ' m²',
    levels: _zor,
    question:
        'Bir halının boyu {r} metre, eni {c} metre. '
        'Halı kaç metrekaredir?',
    grouping: '{r} sıra kare, her sırada {c} metrekare',
    conclusion: 'Halının alanı {n} metrekaredir.',
    buildPrompt: 'Boyu {r} metre, eni {c} metre olan halıyı kur.',
  ),
  MultiplicationContext(
    id: 'kiyafet',
    kind: MultiplicationContextKind.kombinasyon,
    title: 'Kıyafet kombinleri',
    emoji: '🧍',
    groupEmoji: '👕',
    columnHeaderEmoji: '👖',
    levels: _zor,
    question:
        'Dolapta {r} tişört ve {c} pantolon var. '
        'Kaç farklı kıyafet kombini yapılabilir?',
    grouping: '{r} tişört, her tişörte {c} pantolon',
    conclusion: '{r} tişört ve {c} pantolon ile {n} farklı kombin olur.',
    buildPrompt: '{r} tişört ve {c} pantolonun tüm kombinlerini kur.',
  ),
  MultiplicationContext(
    id: 'dondurma',
    kind: MultiplicationContextKind.kombinasyon,
    title: 'Dondurma çeşitleri',
    emoji: '🍨',
    groupEmoji: '🍦',
    columnHeaderEmoji: '🍫',
    levels: _zor,
    question:
        'Dükkânda {r} çeşit külah ve {c} çeşit aroma var. '
        'Kaç farklı dondurma yapılabilir?',
    grouping: '{r} külah, her külaha {c} aroma',
    conclusion: '{r} külah ve {c} aroma ile {n} farklı dondurma olur.',
    buildPrompt: '{r} külah ve {c} aromanın tüm eşleşmelerini kur.',
  ),
  MultiplicationContext(
    id: 'misket',
    kind: MultiplicationContextKind.karsilastirma,
    title: 'Kat kat misket',
    emoji: '🔵',
    groupEmoji: '🧒',
    levels: _zor,
    question:
        "Ali {c} misket topladı. Ayşe'nin misketi Ali'nin {r} katı kadar. "
        'Ayşe kaç misket topladı?',
    grouping: '{c} misketin {r} katı',
    conclusion: 'Ayşe {n} misket topladı.',
  ),
  MultiplicationContext(
    id: 'kule',
    kind: MultiplicationContextKind.karsilastirma,
    title: 'Kat kat kule',
    emoji: '🧱',
    groupEmoji: '🏗️',
    levels: _zor,
    question:
        'Kısa kule {c} bloktan yapıldı. Uzun kule, kısa kulenin {r} katı '
        'yükseklikte. Uzun kule kaç blok?',
    grouping: '{c} bloğun {r} katı',
    conclusion: 'Uzun kule {n} bloktan yapılmıştır.',
  ),
];

/// Verilen seviyede geçerli sahneler.
List<MultiplicationContext> multiplicationContextsFor(
  MultiplicationDifficulty difficulty,
) => multiplicationContexts
    .where((context) => context.levels.contains(difficulty))
    .toList();
