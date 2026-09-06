import 'multiplication_context.dart';

/// Çarpım Bahçesi'ndeki bir turun tipi.
///
/// Turlar rastgele değil, [MultiplicationTrialKind.array] ile
/// [MultiplicationTrialKind.build] arasında dönüşümlü ilerler: her oyuncu iki
/// tipten de eşit sayıda görsün (biri mantığı *gösterir*, diğeri
/// *uygulatır*) ve tur tipi testlerde öngörülebilir olsun diye.
enum MultiplicationTrialKind {
  /// Hazır bir nesne ızgarası verilir, oyuncu toplam sayıyı seçeneklerden bulur.
  array,

  /// Bir çarpma verilir, oyuncu ızgarayı sıra/sütun sayısını ayarlayarak kurar.
  build,
}

/// Çarpım Bahçesi'nde tek bir tur: [rows] sıra × [columns] sütun, bir gerçek
/// hayat sahnesi ([context]) içinde.
///
/// Oyunun tamamı bu "dizi (array) modeli" üzerine kurulu — çarpma, eşit
/// gruplardaki nesnelerin toplamıdır — bu yüzden turun kendisi bir sonuç
/// sayısı değil, bir *dikdörtgen* olarak tanımlanır; [answer] ondan türer.
///
/// Turun bir de sahnesi vardır: aynı 3 × 4 dikdörtgeni bir kez yumurta
/// kolisi, bir kez bisiklet tekerlekleri, bir kez de kıyafet kombinleri
/// olarak karşımıza çıkar. Sayısal iş her sahnede birebir aynı — çocuğun
/// göreceği şey de tam olarak bu.
class MultiplicationTrial {
  const MultiplicationTrial({
    required this.kind,
    required this.rows,
    required this.columns,
    required this.context,
    this.options = const [],
  });

  final MultiplicationTrialKind kind;

  /// İlk çarpan: kaç sıra / kaç grup.
  final int rows;

  /// İkinci çarpan: her sırada (grupta) kaç nesne.
  final int columns;

  /// Turun geçtiği gerçek hayat sahnesi: hem ızgarada çizilen nesneyi hem de
  /// ekrandaki bütün cümleleri o belirler.
  final MultiplicationContext context;

  /// Cevap butonlarının (karışık) sırası. Yalnızca [MultiplicationTrialKind.array]
  /// turlarında dolu; kurma turunda cevap ızgaranın kendisidir.
  final List<int> options;

  int get answer => rows * columns;

  /// Izgarada çizilen nesne (yalnızca görsel; oyun mantığını etkilemez).
  String get emoji => context.emoji;

  /// Toplamın birimi (" TL", " gün", " m²") — sahnesizse boş.
  String get unit => context.unit;

  /// Sıra sıra birikimli toplamlar (3 × 4 için 4, 8, 12). Açıklama paneli her
  /// sıranın sağına bunu yazarak "toplaya toplaya gidiyoruz" fikrini gösterir.
  List<int> get runningTotals => List.generate(rows, (i) => (i + 1) * columns);

  /// Bunun üzerindeki sıra sayılarında tekrarlı toplama satırı ekrana
  /// sığmayacak kadar uzuyor; kısaltılmış biçime geçilir.
  static const int _maxExpandedRows = 6;

  /// Çarpmayı tekrarlı toplama olarak yazan satır — oyunun öğrettiği asıl
  /// cümle. Örn. "3 × 4 = 4 + 4 + 4 = 12".
  String get repeatedAdditionText {
    if (rows <= _maxExpandedRows) {
      final terms = List.filled(rows, '$columns').join(' + ');
      return '$rows × $columns = $terms = $answer$unit';
    }
    return '$rows × $columns = $columns + $columns + … ($rows kere) '
        '= $answer$unit';
  }

  /// Okuma turunun soru cümlesi ("Kolide toplam kaç yumurta var?").
  String get sceneQuestion => context.questionFor(rows, columns);

  /// Kurma turunun yönergesi. Sahne kurma turuna uygun değilse `null` —
  /// [MultiplicationController] zaten böyle bir sahneyi kurma turunda seçmez,
  /// bu yüzden ekran tarafında yalnızca güvenlik ağı olarak yedeği vardır.
  String? get buildPrompt => context.buildPromptFor(rows, columns);

  /// Izgaranın sözle okunuşu: "3 sıra, her sırada 4 yumurta".
  String get groupingText => context.groupingFor(rows, columns);

  /// Açıklama panelinin kapanış cümlesi: "Kolide 12 yumurta var."
  String get sceneConclusion => context.conclusionFor(rows, columns);
}
