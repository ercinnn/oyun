import 'dart:math';

import 'package:flutter/material.dart';

import '../models/town/town_world.dart';

/// Ekrandaki sanal joystick: parmağı sürükledikçe [onChanged] birim çember
/// içinde bir [WorldInput] verir (yön ekrana göredir, dünya bunu izometrik
/// kare yönüne çevirir). Bırakınca sıfır girdi gönderir.
class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({
    super.key,
    required this.onChanged,
    this.size = 116,
  });

  final ValueChanged<WorldInput> onChanged;
  final double size;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _thumb = Offset.zero; // -1..1

  void _update(Offset local) {
    final radius = widget.size / 2;
    var vector = (local - Offset(radius, radius)) / radius;
    final length = sqrt(vector.dx * vector.dx + vector.dy * vector.dy);
    if (length > 1) vector = vector / length;
    // Küçük bir ölü bölge: parmak merkeze yakınken titreme olmasın.
    final dead = length < 0.12;
    setState(() => _thumb = dead ? Offset.zero : vector);
    widget.onChanged(dead ? WorldInput.none : WorldInput(vector.dx, vector.dy));
  }

  void _release() {
    setState(() => _thumb = Offset.zero);
    widget.onChanged(WorldInput.none);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final radius = size / 2;
    return GestureDetector(
      key: const Key('townJoystick'),
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x33000000),
                border: Border.all(color: const Color(0x66FFFFFF), width: 2),
              ),
            ),
            Transform.translate(
              offset: _thumb * (radius * 0.55),
              child: Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
