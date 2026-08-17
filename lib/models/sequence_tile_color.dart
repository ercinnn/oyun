import 'package:flutter/material.dart';

/// Dizi Hafızası oyunundaki 4 kutu rengi. Sıra tamamen görsel/konumsal
/// olduğu için (klasik Simon gibi) bir metin etiketi yok — [StroopColor]'ın
/// aksine burada kelimeyle değil, renk ve konumla hafıza test ediliyor.
enum SequenceTileColor { red, blue, green, yellow }

extension SequenceTileColorInfo on SequenceTileColor {
  /// Kutunun bekleme (yanmamış) hâlindeki soluk rengi.
  Color get idleColor => switch (this) {
    SequenceTileColor.red => Colors.red.shade200,
    SequenceTileColor.blue => Colors.blue.shade200,
    SequenceTileColor.green => Colors.green.shade200,
    SequenceTileColor.yellow => Colors.yellow.shade200,
  };

  /// Kutunun yanmış (aktif/lit) hâlindeki parlak rengi.
  Color get litColor => switch (this) {
    SequenceTileColor.red => Colors.red.shade600,
    SequenceTileColor.blue => Colors.blue.shade600,
    SequenceTileColor.green => Colors.green.shade600,
    SequenceTileColor.yellow => Colors.yellow.shade700,
  };
}
