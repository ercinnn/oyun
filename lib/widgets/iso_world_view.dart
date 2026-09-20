import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../models/town/avatar_spec.dart';
import '../models/town/town_world.dart';
import 'iso_world_painter.dart';
import 'virtual_joystick.dart';

/// Dünyayı gösteren, sürekli kare döngüsü olan görünüm: [Ticker] her karede
/// [onTick]'i çağırır, çizim [frame] bildirimiyle yenilenir (widget ağacı
/// yeniden kurulmaz). Girdi üç yoldan gelir ve tek [WorldInput]'a iner:
/// sanal joystick, klavye (ok tuşları / WASD) ve fare/parmakla dokunma
/// ([onTapTile], dokun-yürü: zemine, altın/yıldız/sandığa ya da bir binaya
/// dokunmak oraya yürütür).
///
/// **Bu ekran testlerde `pumpAndSettle` ile bitmez** (ticker sürekli kare ister);
/// testler `tester.pump(Duration)` kullanmalıdır.
class IsoWorldView extends StatefulWidget {
  const IsoWorldView({
    super.key,
    required this.world,
    required this.avatar,
    required this.frame,
    required this.onTick,
    required this.onInput,
    this.onTapTile,
    this.overlay = const [],
  });

  final TownWorld world;
  final AvatarSpec avatar;

  /// Karede bir kez atılan çizim bildirimi (`TownController.frame`).
  final Listenable frame;

  /// Her karede ilerleyen süre (saniye). Ekran arka plandan dönerse dev bir
  /// süre gelmesin diye 0,1 s ile sınırlanır.
  final ValueChanged<double> onTick;
  final ValueChanged<WorldInput> onInput;
  final void Function(int x, int y)? onTapTile;

  /// Görünümün ölçeği: küçük ekranda biraz uzaklaş, büyükte yakınlaş. Çizim ve
  /// dokunma aynı değeri kullanır (testler de).
  static double zoomFor(Size size) =>
      (min(size.width, size.height) / 420).clamp(0.85, 1.5).toDouble();

  /// Dünyanın üstüne konan öğeler (HUD, düğmeler).
  final List<Widget> overlay;

  @override
  State<IsoWorldView> createState() => _IsoWorldViewState();
}

class _IsoWorldViewState extends State<IsoWorldView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  WorldInput _joystick = WorldInput.none;
  final Set<LogicalKeyboardKey> _keys = {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = min(0.1, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    if (dt <= 0) return;
    widget.onTick(dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Klavye ve joystick girdisini birleştirip iletir (klavye önceliklidir).
  void _publishInput() {
    var dx = 0.0;
    var dy = 0.0;
    if (_keys.contains(LogicalKeyboardKey.arrowRight) ||
        _keys.contains(LogicalKeyboardKey.keyD)) {
      dx += 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowLeft) ||
        _keys.contains(LogicalKeyboardKey.keyA)) {
      dx -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowDown) ||
        _keys.contains(LogicalKeyboardKey.keyS)) {
      dy += 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowUp) ||
        _keys.contains(LogicalKeyboardKey.keyW)) {
      dy -= 1;
    }
    if (dx != 0 || dy != 0) {
      final length = sqrt(dx * dx + dy * dy);
      widget.onInput(WorldInput(dx / length, dy / length));
    } else {
      widget.onInput(_joystick);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _keys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _keys.remove(event.logicalKey);
    } else {
      return KeyEventResult.ignored;
    }
    _publishInput();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final zoom = IsoWorldView.zoomFor(size);

        return Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('townWorldTap'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: widget.onTapTile == null
                      ? null
                      : (details) {
                          final tile = IsoWorldPainter.tapTarget(
                            details.localPosition,
                            size,
                            widget.world,
                            zoom,
                          );
                          widget.onTapTile!(tile.$1, tile.$2);
                        },
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: IsoWorldPainter(
                      world: widget.world,
                      avatar: widget.avatar,
                      zoom: zoom,
                      repaint: widget.frame,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: VirtualJoystick(
                  onChanged: (input) {
                    _joystick = input;
                    _publishInput();
                  },
                ),
              ),
              ...widget.overlay,
            ],
          ),
        );
      },
    );
  }
}
