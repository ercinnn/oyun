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

/// Çarpım Bahçesi'nde tek bir tur: [rows] sıra × [columns] sütun [emoji].
///
/// Oyunun tamamı bu "dizi (array) modeli" üzerine kurulu — çarpma, eşit
/// gruplardaki nesnelerin toplamıdır — bu yüzden turun kendisi bir sonuç
/// sayısı değil, bir *dikdörtgen* olarak tanımlanır; [answer] ondan türer.
class MultiplicationTrial {
  const MultiplicationTrial({
    required this.kind,
    required this.rows,
    required this.columns,
    required this.emoji,
    this.options = const [],
  });

  final MultiplicationTrialKind kind;

  /// İlk çarpan: kaç sıra.
  final int rows;

  /// İkinci çarpan: her sırada kaç nesne.
  final int columns;

  /// Izgarada çizilen nesne (yalnızca görsel; oyun mantığını etkilemez).
  final String emoji;

  /// Cevap butonlarının (karışık) sırası. Yalnızca [MultiplicationTrialKind.array]
  /// turlarında dolu; kurma turunda cevap ızgaranın kendisidir.
  final List<int> options;

  int get answer => rows * columns;

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
      return '$rows × $columns = $terms = $answer';
    }
    return '$rows × $columns = $columns + $columns + … ($rows kere) = $answer';
  }

  /// Izgaranın sözle okunuşu: "3 sıra, her sırada 4 tane".
  String get groupingText => '$rows sıra, her sırada $columns tane';
}
