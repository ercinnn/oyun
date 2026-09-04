import 'package:flutter/material.dart';

/// Ana menünün (oyun kataloğu) kendine ait koyu "konsol paneli" paleti.
///
/// Platformun `MaterialApp.theme`'i (indigo seed, açık tema) oyun ekranları
/// için olduğu gibi kalır; katalog ekranı bu paleti kendi alt ağacında yerel
/// bir [Theme] ile uygular — Bombalı Sayılar'ın kendi `Theme(...)`
/// sarmalayıcısıyla aynı desen (bkz. CLAUDE.md, "Theming"). Bu yüzden buradaki
/// renkler bilerek sabittir: hiçbir oyunun tema seçicisine bağlı değil.
abstract final class HomePalette {
  /// Arka plan gradyanının üç durağı (sol üstten sağ alta).
  static const backdropTop = Color(0xFF070B16);
  static const backdropMid = Color(0xFF0C1425);
  static const backdropBottom = Color(0xFF121C35);

  /// Kart yüzeyi; [surfaceRaised] kartın alt kenarına doğru açılan tonu.
  static const surface = Color(0xFF141D31);
  static const surfaceRaised = Color(0xFF1A2440);

  /// İnce çerçeve/ayırıcı çizgileri (beyazın düşük alfası).
  static const outline = Color(0x1FFFFFFF);
  static const outlineStrong = Color(0x33FFFFFF);

  static const textPrimary = Color(0xFFEEF3FB);
  static const textSecondary = Color(0xFF97A5BF);
  static const textMuted = Color(0xFF6B7A96);

  /// Platformun kendi vurgu rengi (oyun renklerinden bağımsız).
  static const accent = Color(0xFF6C8CFF);
}

/// Katalog ekranının yerel [ThemeData]'sı: koyu, düşük kontrastlı yüzeyler ve
/// [HomePalette] metin renkleri.
ThemeData homeThemeData() {
  final scheme = ColorScheme.fromSeed(
    seedColor: HomePalette.accent,
    brightness: Brightness.dark,
    surface: HomePalette.surface,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: HomePalette.backdropTop,
    textTheme: base.textTheme.apply(
      bodyColor: HomePalette.textPrimary,
      displayColor: HomePalette.textPrimary,
    ),
  );
}

/// Bir oyunun katalogdaki temel rengini koyu zeminde okunur bir vurgu rengine
/// çevirir. Katalogdaki renklerin bir kısmı (kahverengi, mavi-gri, indigo)
/// koyu arka planda olduğu gibi kullanıldığında kaybolduğu için parlaklık ve
/// doygunluk bir miktar yukarı çekilir; hangi oyunun hangi renk olduğu bilgisi
/// korunur.
Color homeAccentOf(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + 0.20).clamp(0.0, 0.74))
      .withSaturation((hsl.saturation + 0.10).clamp(0.0, 1.0))
      .toColor();
}
