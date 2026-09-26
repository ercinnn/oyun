import 'dart:math';

import 'package:flutter/material.dart';

/// Bilim İnsanları ekranlarının yazı boyutları — tek yerde. Çocukların
/// okuyacağı hiçbir metin [caption]'dan küçük olmamalı.
abstract final class LabText {
  /// Sahne göstergesindeki büyük değer ("12 tık/sn").
  static const double insetValue = 22;

  /// Sahne göstergesindeki alt yazı ve sahne etiketleri.
  static const double caption = 14;

  /// Görev sorusu.
  static const double question = 19;

  /// Görevin bağlam metni.
  static const double prompt = 16;

  /// Seçenek düğmeleri.
  static const double option = 17;

  /// Açıklama ve bilgi kartları.
  static const double body = 16;

  static const double bodyHeight = 1.4;
}

/// Sahnenin üstündeki koyu, yarı saydam gösterge kutusu (sayaç, doz
/// haritası, ikiz sayacı…). Genişliği sahnenin ~%62'siyle sınırlıdır ki
/// telefonda deneyi kapatmasın.
class LabInset extends StatelessWidget {
  const LabInset({super.key, required this.children});

  /// Büyük değer + açıklama satırı: göstergelerin çoğu bu biçimdedir.
  LabInset.reading({
    super.key,
    required String value,
    required String caption,
    Color valueColor = Colors.white,
    List<Widget> extra = const [],
  }) : children = [
         LabInsetValue(value, color: valueColor),
         const SizedBox(height: 2),
         LabInsetCaption(caption),
         ...extra,
       ];

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max(190, min(320, width * 0.62))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xE0101418),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// Göstergedeki büyük, kalın değer.
class LabInsetValue extends StatelessWidget {
  const LabInsetValue(this.text, {super.key, this.color = Colors.white});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: LabText.insetValue,
      fontWeight: FontWeight.bold,
      height: 1.15,
    ),
  );
}

/// Göstergedeki açıklama satırı (beyaz, en az 14 px).
class LabInsetCaption extends StatelessWidget {
  const LabInsetCaption(this.text, {super.key, this.color = Colors.white});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: LabText.caption, height: 1.3),
  );
}

/// Açık renkli bir zeminin koyu, okunaklı karşılığı (kart kenarı ve ikon
/// rengi için).
Color labStrongColor(Color background) {
  final hsl = HSLColor.fromColor(background);
  return hsl
      .withLightness(min(hsl.lightness, 0.38))
      .withSaturation(max(hsl.saturation, 0.45))
      .toColor();
}
