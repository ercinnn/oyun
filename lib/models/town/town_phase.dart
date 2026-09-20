enum TownPhase {
  setup,

  /// Serbest kasaba (dünyada gezinme).
  town,

  /// Giyim dükkânı: avatar düzenleyici + mağaza.
  wardrobe,

  /// Mobilya marketi.
  market,

  /// Evim: oda dekorasyonu.
  home,

  /// Oyun salonu: mini oyun seçimi (serbest mod).
  arcade,

  /// Bir mini oyun oynanıyor (serbest ya da yarışma).
  miniGame,

  /// Yarışmada sıra devri.
  turnTransition,

  /// Yarışma sonucu.
  finished,
}

/// Yarışma modunda bir oyuncunun durumu; toplam puanı en yüksek olan kazanır.
class TownPlayerState {
  TownPlayerState({required this.name});

  final String name;
  int totalScore = 0;
  int roundsPlayed = 0;
}
