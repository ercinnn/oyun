import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';

enum CellVisualState { cleared, active, locked }

class GridCell extends StatefulWidget {
  const GridCell({
    super.key,
    required this.number,
    required this.state,
    this.onTap,
    this.exploding = false,
  });

  final int number;
  final CellVisualState state;
  final VoidCallback? onTap;

  /// Bu hücrede az önce bombaya basıldığını belirtir; true olduğu anda kısa
  /// süreli bir sarsıntı + çukurlaşma animasyonu tetiklenir.
  final bool exploding;

  @override
  State<GridCell> createState() => _GridCellState();
}

/// Patlama efektinin toplam ekranda kalma süresi.
const Duration _explodeDuration = Duration(milliseconds: 2000);
// Süreç bu kesire kadar "çarpma" (batma + sarsıntı + kızarma), sonra
// [_explodeRecoveryFrac]'a kadar kızarmış/çökmüş halde sabit bekleme,
// son kesimde de normale yumuşak dönüş.
const double _explodeImpactFrac = 0.22;
const double _explodeRecoveryFrac = 0.85;

class _GridCellState extends State<GridCell>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _explodeController = AnimationController(
    vsync: this,
    duration: _explodeDuration,
  );

  @override
  void didUpdateWidget(covariant GridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exploding && !oldWidget.exploding) {
      _explodeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _explodeController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final Color face;
    final Color depthColor;
    final Color foreground;
    switch (widget.state) {
      case CellVisualState.cleared:
        face = Colors.green.shade400;
        depthColor = Colors.green.shade800;
        foreground = Colors.white;
        break;
      case CellVisualState.active:
        final theme = context.watch<AppThemeController>().current;
        face = theme.boxColor;
        depthColor = Color.lerp(theme.boxColor, Colors.black, 0.45)!;
        foreground = theme.numberColor;
        break;
      case CellVisualState.locked:
        face = Colors.grey.shade300;
        depthColor = Colors.grey.shade300;
        foreground = Colors.grey.shade500;
        break;
    }

    final bool interactive = widget.onTap != null;

    return GestureDetector(
      onTapDown: interactive ? (_) => _setPressed(true) : null,
      onTapCancel: interactive ? () => _setPressed(false) : null,
      onTapUp: interactive
          ? (_) {
              _setPressed(false);
              widget.onTap!();
            }
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Yalnızca tıklanabilir (active) hücreler kabartma derinliği alır;
          // cleared/locked hücreler düz kalarak geçmiş turlara ait olduklarını
          // ve artık etkileşimsiz olduklarını gösterir.
          final double depth = interactive
              ? (constraints.biggest.shortestSide * 0.14).clamp(3.0, 9.0)
              : 0.0;

          return AnimatedBuilder(
            animation: _explodeController,
            builder: (context, _) {
              final double t = _explodeController.value;
              final bool exploding = t > 0 && t < 1;
              final bool showDamage = exploding && t < _explodeRecoveryFrac;

              // Üç aşama: hızlı çarpma (batma + sarsıntı + kızarma), ardından
              // kızarmış/çökmüş halde sabit bekleme, son olarak kendi hedef
              // derinliğine (locked ise düz, aktifse kabarık) yumuşak dönüş.
              double inset;
              double redAmount;
              double shakeDx = 0;
              double scale = 1.0;
              if (!exploding) {
                inset = _pressed ? 0 : depth;
                redAmount = 0;
              } else if (t < _explodeImpactFrac) {
                final local = t / _explodeImpactFrac;
                inset = depth * (1 - Curves.easeIn.transform(local));
                redAmount = Curves.easeOut.transform(local);
                shakeDx = math.sin(local * math.pi * 8) * (1 - local) * 6;
                scale = 1 + (1 - local) * 0.1;
              } else if (t < _explodeRecoveryFrac) {
                inset = 0;
                redAmount = 1;
              } else {
                final local =
                    (t - _explodeRecoveryFrac) / (1 - _explodeRecoveryFrac);
                inset = depth * Curves.easeOutBack.transform(local);
                redAmount = 1 - local;
              }
              final Color effectiveFace = redAmount > 0
                  ? Color.lerp(face, Colors.red.shade700, redAmount)!
                  : face;
              final Color effectiveDepth = redAmount > 0
                  ? Color.lerp(depthColor, Colors.red.shade900, redAmount)!
                  : depthColor;

              return Transform.translate(
                offset: Offset(shakeDx, 0),
                child: Transform.scale(
                  scale: scale,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Derinlik katmanı: hücrenin tamamını kaplayan koyu taban.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: effectiveDepth,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Ön yüz: basılı değilken sağ/alttan içeri kayarak 3D
                      // kabartma hissi verir, basılınca tabana kadar
                      // genişleyip "batar".
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 90),
                        curve: Curves.easeOut,
                        top: 0,
                        left: 0,
                        right: inset,
                        bottom: inset,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(effectiveFace, Colors.white, 0.18)!,
                                effectiveFace,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              showDamage ? '💥' : '${widget.number}',
                              style: TextStyle(
                                color: foreground,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
