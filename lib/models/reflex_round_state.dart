/// Tepki Süresi oyunundaki tek bir turun anlık durumu.
enum ReflexRoundState {
  /// Sinyal henüz gösterilmedi; dokunmak erken başlama sayılır.
  waiting,

  /// Sinyal gösterildi, `Stopwatch` çalışıyor; oyuncunun dokunması bekleniyor.
  ready,

  /// Oyuncu [waiting] aşamasında erken dokundu.
  tooEarly,

  /// Oyuncu [ready] aşamasında dokundu, tepki süresi kaydedildi.
  result,
}
