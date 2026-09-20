import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/town/town_world.dart';
import 'virtual_joystick.dart';

/// Klavye (ok tuşları / WASD) ve sanal joystick girdisini tek [WorldInput]'a
/// indirip [onInput]'a iletir; [child]'ın üstüne joystick'i koyar. Klavye
/// önceliklidir. Girdi **ekran uzayındadır** (sağ = +x, aşağı = +y):
/// `TownWorld.step` bunu kare uzayına kendisi çevirir.
class WorldInputLayer extends StatefulWidget {
  const WorldInputLayer({
    super.key,
    required this.onInput,
    required this.child,
  });

  final ValueChanged<WorldInput> onInput;
  final Widget child;

  @override
  State<WorldInputLayer> createState() => _WorldInputLayerState();
}

class _WorldInputLayerState extends State<WorldInputLayer> {
  WorldInput _joystick = WorldInput.none;
  final Set<LogicalKeyboardKey> _keys = {};

  void _publish() {
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
    _publish();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            left: 16,
            bottom: 16,
            child: VirtualJoystick(
              onChanged: (input) {
                _joystick = input;
                _publish();
              },
            ),
          ),
        ],
      ),
    );
  }
}
