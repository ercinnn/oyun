/// Çarpım Bahçesi'nde çarpanların büyüklüğünü belirleyen üç zorluk seviyesi.
///
/// **Neden iki ayrı çarpan tavanı var?** Oyunun iki tur tipi aynı ölçeği
/// kaldırmıyor:
///
/// - Okuma ("bu ızgarada kaç nesne var?") turlarında ızgara hazır çizildiği
///   için 12 × 12'ye kadar serbestçe büyüyebilir — [MultiplicationArrayView]
///   hücre boyutunu kendi hesaplayıp küçültüyor.
/// - Kurma ("3 × 5'i sen kur") turlarında ise her sıra/sütun bir dokunuş
///   demek; 12'ye çıkmak çocuk için sıkıcı bir dokunma maratonu olurdu. Bu
///   yüzden [buildMaxFactor] her seviyede daha düşük tutulur.
///
/// Alt sınır her seviyede 2'dir: `1 × n` hem düşünmeyi gerektirmiyor hem de
/// tek sıralık bir ızgara olarak çarpmanın "dikdörtgen" sezgisini vermiyor.
enum MultiplicationDifficulty {
  kolay(label: 'Kolay', hint: '1-5 tablosu', arrayMaxFactor: 5, buildMaxFactor: 4),
  orta(label: 'Orta', hint: '1-10 tablosu', arrayMaxFactor: 10, buildMaxFactor: 6),
  zor(label: 'Zor', hint: '1-12 tablosu', arrayMaxFactor: 12, buildMaxFactor: 8);

  const MultiplicationDifficulty({
    required this.label,
    required this.hint,
    required this.arrayMaxFactor,
    required this.buildMaxFactor,
  });

  final String label;

  /// Kurulum ekranında seviyenin altında gösterilen açıklama.
  final String hint;

  /// Okuma turlarındaki en büyük çarpan.
  final int arrayMaxFactor;

  /// Kurma turlarındaki en büyük çarpan.
  final int buildMaxFactor;

  /// Her iki tur tipinde de geçerli olan en küçük çarpan.
  static const int minFactor = 2;
}
