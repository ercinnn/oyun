import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bombali_sayilar/models/town/iso_projection.dart';
import 'package:bombali_sayilar/widgets/world_input_layer.dart';

/// Tuşların oyuna (kare uzayına) düşen yönü: `TownWorld.step` girdiyi
/// `screenDirToTile` ile çevirir, test de aynısını yapar.
({double x, double y}) _tileDir(Set<LogicalKeyboardKey> keys) {
  final input = worldInputFromKeys(keys)!;
  final tile = IsoProjection.screenDirToTile(input.dx, input.dy);
  return (x: tile.dx, y: tile.dy);
}

void _expectDir(({double x, double y}) d, double x, double y) {
  expect(d.x, closeTo(x, 1e-9));
  expect(d.y, closeTo(y, 1e-9));
}

void main() {
  group('ok tuşları harita (izometrik) eksenlerine hizalı', () {
    test('her ok tuşu tek bir kare ekseninde yürütür', () {
      _expectDir(_tileDir({LogicalKeyboardKey.arrowRight}), 1, 0);
      _expectDir(_tileDir({LogicalKeyboardKey.arrowLeft}), -1, 0);
      _expectDir(_tileDir({LogicalKeyboardKey.arrowDown}), 0, 1);
      _expectDir(_tileDir({LogicalKeyboardKey.arrowUp}), 0, -1);
    });

    test(
      'ekranda: sağ sağ-aşağı, yukarı sağ-yukarı gider (yatay/dikey değil)',
      () {
        final right = worldInputFromKeys({LogicalKeyboardKey.arrowRight})!;
        expect(right.dx, greaterThan(0));
        expect(right.dy, greaterThan(0)); // aşağı da: çapraz

        final up = worldInputFromKeys({LogicalKeyboardKey.arrowUp})!;
        expect(up.dx, greaterThan(0));
        expect(up.dy, lessThan(0));
      },
    );

    test('iki tuş birlikte ekran eksenine düşer; WASD aynıdır', () {
      final upRight = worldInputFromKeys({
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowRight,
      })!;
      expect(upRight.dx, closeTo(1, 1e-9));
      expect(upRight.dy, closeTo(0, 1e-9));

      final d = worldInputFromKeys({LogicalKeyboardKey.keyD})!;
      final r = worldInputFromKeys({LogicalKeyboardKey.arrowRight})!;
      expect(d.dx, closeTo(r.dx, 1e-9));
      expect(d.dy, closeTo(r.dy, 1e-9));
    });

    test('karşıt tuşlar birbirini götürür; tuş yoksa null', () {
      expect(
        worldInputFromKeys({
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
        }),
        isNull,
      );
      expect(worldInputFromKeys({}), isNull);
    });
  });
}
