/// Satrancın oynanma biçimi: [vsAi] tek insan oyuncunun bilgisayara karşı
/// oynadığı mod, [twoPlayer] aynı cihazda karşılıklı oynanan yerel mod,
/// [online] internet üzerinden oda koduyla eşleşen iki farklı cihazın
/// oynadığı mod (her cihaz kendi rengini [ChessController.humanColor]'da
/// tutar, tıpkı [vsAi]'daki insan oyuncu gibi).
enum ChessMode { vsAi, twoPlayer, online }
