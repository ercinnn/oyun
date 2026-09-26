/// Bir bilim insanı oyununun ortak ekranlarda görünen metinleri.
class ScientistGameConfig {
  const ScientistGameConfig({
    required this.title,
    required this.banner,
    required this.intro,
    required this.exploreTitle,
    required this.exploreHint,
    required this.moral,
  });

  /// Kurulum ekranının başlığı ("Arşimet'in Atölyesi").
  final String title;

  /// Kurulum ekranının üstündeki emoji şeridi.
  final String banner;

  /// Buluşun hikâyesini çocuk diliyle anlatan giriş paragrafı.
  final String intro;

  /// Keşif atölyesinin adı (kurulum düğmesi ve AppBar).
  final String exploreTitle;

  /// Keşif düğmesinin altındaki açıklama.
  final String exploreHint;

  /// Sonuç ekranında akılda kalsın diye tek cümlelik özet.
  final String moral;
}
