import 'package:flutter/material.dart';

import '../screens/scientists_hub_screen.dart';

/// "Bilim İnsanları" route'u: posterdeki bilim insanlarından birini seçme
/// ekranı. Her bilim insanının oyunu **ayrı bir route**'tur (örn.
/// `ArchimedesGame`) ve kendi controller'ını kurar; bu route'un kendine ait
/// bir state'i yoktur.
class ScientistsGame extends StatelessWidget {
  const ScientistsGame({super.key});

  static const routeName = '/games/bilim-insanlari';

  @override
  Widget build(BuildContext context) => const ScientistsHubScreen();
}
