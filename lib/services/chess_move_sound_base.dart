/// Satranç hamle sesleri: boş kareye oynama, taş yeme ve şah. Sesler dosyadan
/// yüklenmez, çalındığı anda üretilir (bkz. `chess_move_sound_recipe.dart`).
abstract class ChessMoveSounds {
  /// Boş kareye oynama (yumuşak ahşap teması).
  void playNormalMove();

  /// Taş yeme (sert, gür çift darbe).
  void playCaptureSound();

  /// Şah çekme (uyarıcı ama doğal ahşap çınlaması).
  void playCheckSound();

  /// Ses bağlamını/çalıcıları kapatır; bir kez çağrılır.
  void dispose();
}
