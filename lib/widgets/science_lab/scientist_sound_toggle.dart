import 'package:flutter/material.dart';

import '../../controllers/scientist_game_controller.dart';

/// `AppBar`'daki ses aç/kapa düğmesi. Tercih tüm bilim insanları için ortaktır
/// ve saklanır. Kontrolcüye ses servisi bağlanmamışsa (testler) hiç görünmez.
class ScientistSoundToggle extends StatelessWidget {
  const ScientistSoundToggle({super.key, required this.controller});

  final ScientistGameController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasSounds) return const SizedBox.shrink();
    final on = controller.soundOn;
    return IconButton(
      key: const Key('scientistSoundToggle'),
      tooltip: on ? 'Sesi kapat' : 'Sesi aç',
      icon: Icon(on ? Icons.volume_up : Icons.volume_off),
      onPressed: controller.toggleSound,
    );
  }
}
