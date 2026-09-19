import 'package:flutter/material.dart';

import '../models/plant_conditions.dart';
import '../models/plant_growth.dart';
import '../models/plant_species.dart';
import 'plant_growth_chart.dart';
import 'plant_view.dart';

/// İki saksının zaman atlamalı karşılaştırması: iki bitki yan yana, altında
/// gün kaydırıcısı, boy bilgisi ve grafik. Açılınca 0. günden 10. güne kendi
/// kendine oynar (sonlu animasyon, `pumpAndSettle` bunu bekleyip biter);
/// çocuk kaydırıcıya dokununca animasyon durur ve günü elle seçer — bir günden
/// ötekine bakıp boyları kendi gözüyle karşılaştırabilir.
class PlantComparisonPanel extends StatefulWidget {
  const PlantComparisonPanel({
    super.key,
    required this.species,
    required this.potA,
    required this.potB,
    this.labelA = 'A',
    this.labelB = 'B',
  });

  final PlantSpecies species;
  final PlantConditions potA;
  final PlantConditions potB;
  final String labelA;
  final String labelB;

  @override
  State<PlantComparisonPanel> createState() => _PlantComparisonPanelState();
}

class _PlantComparisonPanelState extends State<PlantComparisonPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Çocuk kaydırıcıyı tuttuysa seçtiği gün; null ise animasyon günü belirler.
  double? _manualDay;

  double get _day =>
      _manualDay ?? _controller.value * plantExperimentDays.toDouble();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 3500),
          )
          ..addListener(() => setState(() {}))
          ..forward();
  }

  @override
  void didUpdateWidget(covariant PlantComparisonPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species ||
        oldWidget.potA != widget.potA ||
        oldWidget.potB != widget.potB) {
      _manualDay = null;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final snapshotA = simulatePlant(widget.species, widget.potA, day);
    final snapshotB = simulatePlant(widget.species, widget.potB, day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PotColumn(
                label: widget.labelA,
                color: PlantGrowthChart.colorA,
                conditions: widget.potA,
                species: widget.species,
                snapshot: snapshotA,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PotColumn(
                label: widget.labelB,
                color: PlantGrowthChart.colorB,
                conditions: widget.potB,
                species: widget.species,
                snapshot: snapshotB,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Gün: ${day.round()} / $plantExperimentDays',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          key: const Key('plantDaySlider'),
          value: day,
          min: 0,
          max: plantExperimentDays.toDouble(),
          divisions: plantExperimentDays,
          onChanged: (value) {
            _controller.stop();
            setState(() => _manualDay = value);
          },
        ),
        PlantGrowthChart(
          species: widget.species,
          potA: widget.potA,
          potB: widget.potB,
          day: day,
        ),
        const SizedBox(height: 4),
        Text(
          'Grafik: bitkilerin boyu günlere göre. Mavi ${widget.labelA}, turuncu ${widget.labelB}.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PotColumn extends StatelessWidget {
  const _PotColumn({
    required this.label,
    required this.color,
    required this.conditions,
    required this.species,
    required this.snapshot,
  });

  final String label;
  final Color color;
  final PlantConditions conditions;
  final PlantSpecies species;
  final PlantSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(color: color),
        ),
        Text(
          conditions.summary,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        PlantView(species: species, snapshot: snapshot),
        Text(
          'Boy: ${formatCm(snapshot.heightCm)} cm',
          style: textTheme.titleSmall,
        ),
        Text(
          snapshot.health.label,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
