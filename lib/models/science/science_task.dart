/// Bilim İnsanları oyunlarında bir görev turu: soru, seçenekler, **modelden
/// hesaplanan** doğru cevap ve açıklama. Her bilim insanının görev türleri
/// (`ArchimedesTask`, `NewtonTask`…) bunu uygular; ortak görev ekranı
/// (`ScientistTaskScreen`) yalnızca bu arayüzü bilir.
///
/// Cümleler elle yazılır; değişken bir kelimeye ek getirilmez (bkz. CLAUDE.md,
/// Simon/Çarpım Bahçesi kuralı).
abstract class ScienceTask {
  const ScienceTask();

  String get title;
  String get prompt;
  List<String> get options;
  int get correctIndex;

  /// Cevaptan sonra gösterilen açıklama ([answerIndex] = çocuğun seçimi).
  String explanation(int answerIndex);

  /// Soruya eklenen küçük not (örn. "Soldaki kap A, sağdaki kap B."); yoksa
  /// null.
  String? get hint => null;
}

/// Sayıyı Türkçe ondalık virgülüyle yazar (1.5 → "1,5"); tam sayıysa ondalıksız.
String formatTr(double value, {int digits = 1}) {
  final rounded = double.parse(value.toStringAsFixed(digits));
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(digits).replaceAll('.', ',');
}
