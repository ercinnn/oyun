import 'dart:math';
import 'dart:ui';

/// İzometrik (2:1) izdüşüm: kare koordinatları (x, y) ↔ ekran koordinatları.
///
/// x ekranda sağ-aşağı, y sol-aşağı gider. Karo genişliği [tileW], yüksekliği
/// [tileH] piksel (dünya birimi; zoom ayrıca uygulanır). Hepsi saf hesaptır.
class IsoProjection {
  const IsoProjection._();

  static const double tileW = 64;
  static const double tileH = 32;

  /// Kare koordinatını ekran koordinatına çevirir.
  static Offset toScreen(double x, double y) =>
      Offset((x - y) * tileW / 2, (x + y) * tileH / 2);

  /// [toScreen]'in tersi.
  static Offset toTile(double screenX, double screenY) {
    final a = screenX / (tileW / 2);
    final b = screenY / (tileH / 2);
    return Offset((a + b) / 2, (b - a) / 2);
  }

  /// Ekrandaki bir yönü (joystick / ok tuşları) kare uzayında birim yöne
  /// çevirir; böylece "sağa" basınca karakter ekranda gerçekten sağa gider
  /// (kare uzayında çapraz). Sıfır girdi sıfır döner.
  static Offset screenDirToTile(double dx, double dy) {
    if (dx == 0 && dy == 0) return Offset.zero;
    final tile = toTile(dx, dy);
    final length = sqrt(tile.dx * tile.dx + tile.dy * tile.dy);
    if (length == 0) return Offset.zero;
    return Offset(tile.dx / length, tile.dy / length);
  }
}
