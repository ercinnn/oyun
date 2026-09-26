import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/galileo_controller.dart';
import '../models/galileo/galileo_scene.dart';
import '../models/galileo/jupiter.dart';
import '../models/galileo/solar.dart';
import '../models/galileo/telescope.dart';
import '../models/science/science_task.dart' show formatTr;
import '../widgets/galileo/galileo_scene_view.dart';
import '../widgets/science_lab/lab_split_layout.dart';

/// Puansız Gözlemevi: teleskobu kur ve odakla, Jüpiter'in uydularını gece
/// gece izleyip deftere çiz, Güneş sisteminde günleri ilerletip Venüs'ün
/// evrelerini gör.
class GalileoExploreScreen extends StatelessWidget {
  const GalileoExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GalileoController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<GalileoStation>(
          key: const Key('galileoStation'),
          segments: [
            for (final s in GalileoStation.values)
              ButtonSegment(value: s, label: Text(s.label)),
          ],
          selected: {controller.station},
          showSelectedIcon: false,
          onSelectionChanged: (v) => controller.setStation(v.first),
        ),
        const SizedBox(height: 12),
        switch (controller.station) {
          GalileoStation.telescope => _TelescopeControls(controller: controller),
          GalileoStation.jupiter => _JupiterControls(controller: controller),
          GalileoStation.solar => _SolarControls(controller: controller),
        },
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gözlemevi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Geri',
          onPressed: controller.backToSetup,
        ),
      ),
      body: LabSplitLayout(
        scene: KeyedSubtree(
          key: const Key('scientistScene'),
          child: GalileoSceneView(scene: controller.scene),
        ),
        panel: controls,
      ),
    );
  }
}

Widget _chips<T>({
  required List<T> values,
  required T selected,
  required String Function(T) label,
  required ValueChanged<T> onSelected,
  required String Function(T) keyOf,
}) => Wrap(
  spacing: 6,
  runSpacing: 4,
  children: [
    for (final v in values)
      ChoiceChip(
        key: Key(keyOf(v)),
        label: Text(label(v)),
        selected: v == selected,
        onSelected: (_) => onSelected(v),
        visualDensity: VisualDensity.compact,
      ),
  ],
);

// ─────────────────────────── Teleskop ───────────────────────────

class _TelescopeControls extends StatelessWidget {
  const _TelescopeControls({required this.controller});

  final GalileoController controller;

  @override
  Widget build(BuildContext context) {
    final fo = controller.objectiveCm;
    final fe = controller.eyepieceCm;
    final sharp = isSharp(fo, fe, controller.tubeCm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Neye bakalım?'),
        const SizedBox(height: 4),
        _chips<SkyTarget>(
          values: SkyTarget.values,
          selected: controller.target,
          label: (t) => t.label,
          onSelected: controller.setTarget,
          keyOf: (t) => 'galileoTarget_${t.name}',
        ),
        const SizedBox(height: 10),
        const Text('Objektif (dışbükey, öndeki mercek):'),
        const SizedBox(height: 4),
        _chips<double>(
          values: objectiveLensesCm,
          selected: fo,
          label: (v) => '${formatTr(v)} cm',
          onSelected: controller.setObjective,
          keyOf: (v) => 'galileoObjective_${v.round()}',
        ),
        const SizedBox(height: 8),
        const Text('Göz merceği (içbükey):'),
        const SizedBox(height: 4),
        _chips<double>(
          values: eyepieceLensesCm,
          selected: fe,
          label: (v) => '${formatTr(v)} cm',
          onSelected: controller.setEyepiece,
          keyOf: (v) => 'galileoEyepiece_${v.round()}',
        ),
        const SizedBox(height: 8),
        Text('Tüp boyu: ${formatTr(controller.tubeCm)} cm'),
        Slider(
          key: const Key('galileoTube'),
          value: controller.tubeCm,
          min: tubeMinCm,
          max: tubeMaxCm,
          divisions: (tubeMaxCm - tubeMinCm).round(),
          label: '${controller.tubeCm.round()} cm',
          onChanged: controller.setTube,
        ),
        LabInfoCard(
          key: const Key('galileoTelescopeInfo'),
          color: sharp ? Colors.green.shade50 : Colors.orange.shade50,
          text: 'Büyütme: ${formatTr(fo)} ÷ ${formatTr(fe)} = '
              '${formatTr(magnification(fo, fe))} kat. '
              '${sharp ? 'Görüntü net! Tüp boyu = objektif − göz merceği = ${formatTr(sharpTubeCm(fo, fe))} cm.' : 'Görüntü bulanık: tüpü kaydırarak netleştir.'}',
        ),
      ],
    );
  }
}

// ─────────────────────────── Jüpiter ───────────────────────────

class _JupiterControls extends StatelessWidget {
  const _JupiterControls({required this.controller});

  final GalileoController controller;

  @override
  Widget build(BuildContext context) {
    final nights = controller.nights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Gece: ${formatTr(nights)}'),
        Slider(
          key: const Key('galileoNights'),
          value: nights.clamp(0, 30).toDouble(),
          min: 0,
          max: 30,
          divisions: 120,
          onChanged: controller.setNights,
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('galileoNextNight'),
                onPressed: controller.nextNight,
                icon: const Icon(Icons.nights_stay),
                label: const Text('Sonraki gece'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: const Key('galileoSketch'),
                onPressed: controller.sketchTonight,
                icon: const Icon(Icons.edit),
                label: const Text('Deftere çiz'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFFF3E9D2),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Gözlem defteri (O = Jüpiter, * = uydu)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (controller.notebook.isEmpty)
                  const Text('Henüz çizim yok. Birkaç gece çiz ve karşılaştır!')
                else
                  for (final (night, sketch) in controller.notebook)
                    Text(
                      '${formatTr(night).padLeft(4)}. gece  $sketch',
                      key: Key('galileoNote_${formatTr(night)}'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                if (controller.notebook.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: controller.clearNotebook,
                      child: const Text('Defteri temizle'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        LabInfoCard(
          text: controller.notebook.length >= 3
              ? 'Uydular gece gece yer değiştiriyor, bazen biri Jüpiter\'in '
                    'önüne ya da arkasına saklanıyor. Galileo buradan onların '
                    'Jüpiter\'in etrafında döndüğünü anladı: her şey Dünya\'nın '
                    'etrafında dönmüyordu!'
              : 'İpucu: En içteki ${jupiterMoons.first.name} her gece çok yer '
                    'değiştirir, en dıştaki ${jupiterMoons.last.name} ise yavaş.',
        ),
      ],
    );
  }
}

// ─────────────────────────── Güneş sistemi ───────────────────────────

class _SolarControls extends StatelessWidget {
  const _SolarControls({required this.controller});

  final GalileoController controller;

  @override
  Widget build(BuildContext context) {
    final day = controller.day;
    final view = venusOnDay(day);
    final earthTurns = day / planetById('earth').periodDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Gün: ${day.round()}  (Dünya ${formatTr(earthTurns)} tur attı)'),
        Slider(
          key: const Key('galileoDay'),
          value: day.clamp(0, 730).toDouble(),
          min: 0,
          max: 730,
          divisions: 146,
          onChanged: controller.setDay,
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('galileoPlus30'),
                onPressed: () => controller.advanceDays(30),
                child: const Text('+30 gün'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                key: const Key('galileoResetDay'),
                onPressed: () => controller.setDay(0),
                child: const Text('Başa dön'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('galileoVenusInfo'),
          color: Colors.indigo.shade50,
          text: 'Dünya\'dan Venüs: ${view.phase.label.toLowerCase()} '
              '(aydınlık kısım %${(view.litFraction * 100).round()}, '
              'boyu ${formatTr(view.relativeSize)} kat). '
              'Günleri ilerlet: Venüs yaklaştıkça büyüyüp inceliyor, '
              'uzaklaştıkça küçülüp doluyor.',
        ),
        LabInfoCard(
          text: planets
              .map((p) => '${p.name}: ${formatTr(p.periodDays, digits: 0)} gün')
              .join(' · '),
        ),
      ],
    );
  }
}
