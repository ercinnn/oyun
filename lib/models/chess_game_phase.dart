/// Diğer çok-oyunculu oyunların aksine bir [turnTransition] fazı yok:
/// satrançta oyuncular arasında gizli bilgi olmadığı (tahta her an her iki
/// tarafa da açık) ve hamleler çok sık gerçekleştiği için her yarı-hamlede
/// bir "cihazı devret" ekranı göstermek oyunun akışını bozardı — tahtanın
/// otomatik dönmesi (`ChessController.boardFlipped`) devretme ihtiyacını
/// zaten karşılıyor. Bkz. CLAUDE.md, Kart Eşleştirme'nin aynı gerekçeyle
/// `turnTransition`'ı atlaması.
enum ChessGamePhase { setup, playing, finished }
