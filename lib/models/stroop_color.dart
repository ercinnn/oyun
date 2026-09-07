import 'package:flutter/material.dart';

/// Stroop oyununda kullanılan altı renk. Her tur, bir rengin Türkçe adı
/// (kelime) bir başka rengin mürekkebiyle (ink) gösterilir; doğru cevap
/// her zaman mürekkep rengidir, kelimenin kendisi değil.
enum StroopColor { red, blue, green, yellow, purple, brown }

extension StroopColorInfo on StroopColor {
  String get label => switch (this) {
    StroopColor.red => 'Kırmızı',
    StroopColor.blue => 'Mavi',
    StroopColor.green => 'Yeşil',
    StroopColor.yellow => 'Sarı',
    StroopColor.purple => 'Mor',
    StroopColor.brown => 'Kahverengi',
  };

  /// Beyaz zemin üzerinde okunaklı olacak ve birbirinden net ayırt
  /// edilebilecek şekilde seçilmiş mürekkep rengi. Saf `Colors.yellow`
  /// düşük kontrastlı olduğu için `yellow.shade700` kullanılıyor.
  Color get inkColor => switch (this) {
    StroopColor.red => Colors.red,
    StroopColor.blue => Colors.blue,
    StroopColor.green => Colors.green,
    StroopColor.yellow => Colors.yellow.shade700,
    StroopColor.purple => Colors.purple,
    StroopColor.brown => Colors.brown,
  };
}
