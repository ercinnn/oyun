/// Kart eşleştirme oyunundaki tek bir kart. [id] her kartta benzersizdir;
/// eşleşme kontrolü [symbol] üzerinden yapılır (her sembolden tam 2 kart).
/// Aynı sembole sahip iki karttan biri [label] olarak Türkçe adını, diğeri
/// İngilizce adını taşır — eşleştirme hâlâ [symbol] üzerinden yapılır, bu
/// etiket sadece görsel/öğretici bir katman. [languageCode] o etiketin hangi
/// dilde seslendirileceğini belirtir (bkz. `services/speech_service.dart`).
class MemoryCard {
  MemoryCard({
    required this.id,
    required this.symbol,
    required this.label,
    required this.languageCode,
  });

  final int id;
  final String symbol;
  final String label;
  final String languageCode;

  bool isFaceUp = false;
  bool isMatched = false;
}
