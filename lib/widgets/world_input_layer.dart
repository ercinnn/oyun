import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/town/iso_projection.dart';
import '../models/town/town_world.dart';
import 'virtual_joystick.dart';

/// Ok tuşları / WASD → hareket girdisi, **harita eksenlerine hizalı**: oyun
/// izometrik olduğu için "sağ" ekranda yatay değil, ızgaranın `+x` yönüdür
/// (sağ-aşağı çapraz). Eşleme klasik izometrik düzendir:
///
/// - Sağ  = `+x` (ekranda sağ-aşağı),  Sol = `-x` (sol-yukarı)
/// - Aşağı = `+y` (ekranda sol-aşağı), Yukarı = `-y` (sağ-yukarı)
///
/// İki tuş birlikte basılınca ekran eksenine düşer (Yukarı+Sağ = düz sağa).
/// Girdi `TownWorld.step`'in beklediği **ekran uzayında** döner; oradaki
/// `screenDirToTile` bunu tekrar kare yönüne çevirir. Tuş yoksa null.
WorldInput? worldInputFromKeys(Set<LogicalKeyboardKey> keys) {
  var tx = 0.0; // kare x ekseni
  var ty = 0.0; // kare y ekseni
  if (keys.contains(LogicalKeyboardKey.arrowRight) ||
      keys.contains(LogicalKeyboardKey.keyD)) {
    tx += 1;
  }
  if (keys.contains(LogicalKeyboardKey.arrowLeft) ||
      keys.contains(LogicalKeyboardKey.keyA)) {
    tx -= 1;
  }
  if (keys.contains(LogicalKeyboardKey.arrowDown) ||
      keys.contains(LogicalKeyboardKey.keyS)) {
    ty += 1;
  }
  if (keys.contains(LogicalKeyboardKey.arrowUp) ||
      keys.contains(LogicalKeyboardKey.keyW)) {
    ty -= 1;
  }
  if (tx == 0 && ty == 0) return null;
  final screen = IsoProjection.toScreen(tx, ty);
  final length = sqrt(screen.dx * screen.dx + screen.dy * screen.dy);
  if (length == 0) return null;
  return WorldInput(screen.dx / length, screen.dy / length);
}

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
    widget.onInput(worldInputFromKeys(_keys) ?? _joystick);
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
