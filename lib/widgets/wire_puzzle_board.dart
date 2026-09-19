import 'dart:math';

import 'package:flutter/material.dart';

import '../models/wire_puzzle.dart';

/// Kablo bulmacasının karo ızgarası. Karoya dokununca [onTap] çağrılır
/// (denetleyici karoyu döndürür). Akım ulaşan karolar sarı çizilir; çözülünce
/// ampul yanar. Karo boyutu `LayoutBuilder` ile ölçeklenir.
class WirePuzzleBoard extends StatelessWidget {
  const WirePuzzleBoard({
    super.key,
    required this.puzzle,
    required this.onTap,
    this.enabled = true,
  });

  final WirePuzzle puzzle;
  final ValueChanged<int> onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final powered = puzzle.poweredCells;
    final solved = powered.contains(puzzle.bulbIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, 360.0);
        final tile = side / puzzle.size;
        return Center(
          child: SizedBox(
            width: tile * puzzle.size,
            height: tile * puzzle.size,
            child: Column(
              children: [
                for (var row = 0; row < puzzle.size; row++)
                  Expanded(
                    // stretch: Row aksi halde çocuklara gevşek yükseklik verir ve
                    // boyutsuz CustomPaint karoları çökertir.
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var col = 0; col < puzzle.size; col++)
                          Expanded(
                            child: _Tile(
                              key: Key('wireTile_${row * puzzle.size + col}'),
                              tile: puzzle.tiles[row * puzzle.size + col],
                              powered: powered.contains(row * puzzle.size + col),
                              solved: solved,
                              onTap: enabled
                                  ? () => onTap(row * puzzle.size + col)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.tile,
    required this.powered,
    required this.solved,
    required this.onTap,
  });

  final WireTile tile;
  final bool powered;
  final bool solved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: InkWell(
        onTap: tile.rotatable ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _TilePainter(tile, powered, solved),
          ),
        ),
      ),
    );
  }
}

class _TilePainter extends CustomPainter {
  _TilePainter(this.tile, this.powered, this.solved);

  final WireTile tile;
  final bool powered;
  final bool solved;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.width * 0.16;
    final color = powered ? const Color(0xFFF9A825) : const Color(0xFF90A4AE);
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final mask = tile.mask;
    void arm(int bit, Offset end) {
      if (mask & bit != 0) canvas.drawLine(center, end, paint);
    }

    arm(1, Offset(center.dx, 0));
    arm(2, Offset(size.width, center.dy));
    arm(4, Offset(center.dx, size.height));
    arm(8, Offset(0, center.dy));

    if (tile.kind == WireKind.empty) return;
    canvas.drawCircle(center, stroke * 0.7, Paint()..color = color);

    if (tile.kind == WireKind.battery) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: size.width * 0.5,
            height: size.height * 0.36,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF455A64),
      );
      _label(canvas, size, '+', Colors.white);
    } else if (tile.kind == WireKind.bulb) {
      final r = size.width * 0.26;
      if (solved) {
        canvas.drawCircle(
          center,
          r + size.width * 0.12,
          Paint()..color = const Color.fromRGBO(255, 193, 7, 0.5),
        );
      }
      canvas.drawCircle(
        center,
        r,
        Paint()..color = solved ? const Color(0xFFFFD54F) : const Color(0xFFEEEEEE),
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = const Color(0xFF616161)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _label(Canvas canvas, Size size, String text, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size.width * 0.28,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      size.center(Offset.zero) - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TilePainter oldDelegate) => true;
}
