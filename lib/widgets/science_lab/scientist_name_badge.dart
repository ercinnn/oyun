import 'package:flutter/material.dart';

import '../../data/scientists_catalog.dart';

/// Hangi bilim insanının oyununda olunduğunu alt ağaca taşır.
/// `ScientistGameRoot` her fazın ekranını bununla sarar; `LabSplitLayout`
/// buradan okuyup sahnenin sol üstüne [ScientistNameBadge] koyar. Böylece
/// yedi keşif ekranının her birine ayrıca eklemek gerekmez.
class ScientistIdentity extends InheritedWidget {
  const ScientistIdentity({
    super.key,
    required this.scientist,
    required super.child,
  });

  final Scientist scientist;

  static Scientist? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ScientistIdentity>()
      ?.scientist;

  @override
  bool updateShouldNotify(ScientistIdentity oldWidget) =>
      oldWidget.scientist.id != scientist.id;
}

/// Bilim insanının adı (emoji + ad), kendi renginde küçük bir etiket.
/// Deney sahnesinin sol üstünde durur (sağ üstte yakınlaştırma düğmeleri,
/// sol altta göstergeler vardır).
class ScientistNameBadge extends StatelessWidget {
  const ScientistNameBadge({super.key, required this.scientist});

  final Scientist scientist;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('scientistNameBadge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scientist.color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(scientist.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              scientist.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
