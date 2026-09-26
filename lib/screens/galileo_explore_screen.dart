import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/galileo_controller.dart';
import '../models/galileo/galileo_scene.dart';
import '../models/galileo/jupiter.dart';
import '../models/galileo/solar.dart';
import '../models/galileo/telescope.dart';
import '../models/science/science_task.dart' show formatTr;
import '../widgets/galileo/galileo_scene_view.dart';
import '../widgets/science_lab/lab_guide.dart';
import '../widgets/science_lab/lab_split_layout.dart';
import '../widgets/science_lab/scientist_sound_toggle.dart';

/// Puansız Gözlemevi: teleskobu kur ve odakla, Jüpiter'in uydularını gece
/// gece izleyip deftere çiz, Güneş sisteminde günleri ilerletip Venüs'ün
/// evrelerini gör.
class GalileoExploreScreen extends StatelessWidget {
  const GalileoExploreScreen({super.key});

  static const _stations = [
    LabStation(
      GalileoStation.telescope,
      'Teleskop',
      '🔭',
      'Mercekleri seç, tüpü kaydır ve gökyüzünü netleştir.',
    ),
    LabStation(
      GalileoStation.jupiter,
      "Jüpiter'in Uyduları",
      '🪐',
      'Geceleri ilerlet: uydular Jüpiter\'in çevresinde nasıl dolanıyor?',
    ),
    LabStation(
      GalileoStation.solar,
      'Güneş Sistemi',
      '☀️',
      "Günleri ilerlet ve Dünya'dan bakınca Venüs'ün şeklini izle.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GalileoController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStationPicker<GalileoStation>(
          key: const Key('galileoStation'),
          stations: _stations,
          selected: controller.station,
          onSelected: controller.setStation,
        ),
        const SizedBox(height: 12),
        switch (controller.station) {
          GalileoStation.telescope => _TelescopeControls(
            controller: controller,
          ),
          GalileoStation.jupiter => _JupiterControls(controller: controller),
          GalileoStation.solar => _SolarControls(controller: controller),
        },
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gözlemevi'),
        actions: [ScientistSoundToggle(controller: controller)],
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
        label: Text(label(v), style: const TextStyle(fontSize: 15)),
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
        LabStepList(
          steps: [
            LabStep(
              'Tüp boyu kaydırıcısıyla görüntüyü netleştir.',
              done: controller.sawSharp,
            ),
            LabStep(
              'Göz merceğini değiştir: görüntü büyüdü mü?',
              done: controller.eyepiecesTried.length >= 2,
            ),
            LabStep(
              "Ay'a, Jüpiter'e ve Venüs'e sırayla bak.",
              done: controller.targetsViewed.length >= SkyTarget.values.length,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabSectionTitle('Tüp boyu: ${formatTr(controller.tubeCm)} cm'),
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
          icon: sharp ? Icons.check_circle_outline : Icons.blur_on,
          title: 'Büyütme: ${formatTr(magnification(fo, fe))} kat',
          text:
              '${formatTr(fo)} ÷ ${formatTr(fe)} = '
              '${formatTr(magnification(fo, fe))}. '
              '${sharp ? 'Görüntü net! Tüp boyu = objektif − göz merceği = ${formatTr(sharpTubeCm(fo, fe))} cm.' : 'Görüntü bulanık: tüpü kaydırarak netleştir.'}',
        ),
        const SizedBox(height: 6),
        const LabSectionTitle('Neye bakalım?'),
        _chips<SkyTarget>(
          values: SkyTarget.values,
          selected: controller.target,
          label: (t) => t.label,
          onSelected: controller.setTarget,
          keyOf: (t) => 'galileoTarget_${t.name}',
        ),
        const SizedBox(height: 6),
        const LabSectionTitle('Objektif (dışbükey, öndeki mercek)'),
        _chips<double>(
          values: objectiveLensesCm,
          selected: fo,
          label: (v) => '${formatTr(v)} cm',
          onSelected: controller.setObjective,
          keyOf: (v) => 'galileoObjective_${v.round()}',
        ),
        const SizedBox(height: 6),
        const LabSectionTitle('Göz merceği (içbükey)'),
        _chips<double>(
          values: eyepieceLensesCm,
          selected: fe,
          label: (v) => '${formatTr(v)} cm',
          onSelected: controller.setEyepiece,
          keyOf: (v) => 'galileoEyepiece_${v.round()}',
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
        LabStepList(
          steps: [
            LabStep(
              '"Sonraki gece"ye bas ve uyduların yerini izle.',
              done: controller.nightsAdvanced,
            ),
            LabStep(
              'Bu geceyi deftere çiz.',
              done: controller.notebook.isNotEmpty,
            ),
            LabStep(
              'En az 3 gece çiz, çizimleri karşılaştır.',
              done: controller.notebook.length >= 3,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: LabActionButton(
                key: const Key('galileoNextNight'),
                onPressed: controller.nextNight,
                icon: Icons.nights_stay,
                label: 'Sonraki gece',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('galileoSketch'),
                onPressed: controller.sketchTonight,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Deftere çiz'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LabSectionTitle('Gece: ${formatTr(nights)}'),
        Slider(
          key: const Key('galileoNights'),
          value: nights.clamp(0, 30).toDouble(),
          min: 0,
          max: 30,
          divisions: 120,
          onChanged: controller.setNights,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                if (controller.notebook.isEmpty)
                  const Text('Henüz çizim yok. Birkaç gece çiz ve karşılaştır!')
                else
                  for (final (night, sketch) in controller.notebook)
                    Text(
                      '${formatTr(night).padLeft(4)}. gece  $sketch',
                      key: Key('galileoNote_${formatTr(night)}'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                      ),
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
        LabStepList(
          steps: [
            LabStep(
              '"+30 gün" ile zamanı ilerlet.',
              done: controller.daysAdvanced,
            ),
            LabStep(
              "Venüs'ün ince hilal olduğu günü bul.",
              done: controller.venusPhasesSeen.contains(VenusPhase.crescent),
            ),
            LabStep(
              "Venüs'ün dolunay gibi göründüğü günü bul.",
              done: controller.venusPhasesSeen.contains(VenusPhase.full),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: LabActionButton(
                key: const Key('galileoPlus30'),
                onPressed: () => controller.advanceDays(30),
                icon: Icons.fast_forward,
                label: '+30 gün',
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const Key('galileoResetDay'),
              onPressed: () => controller.setDay(0),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
              ),
              icon: const Icon(Icons.replay),
              label: const Text('Başa dön'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LabSectionTitle(
          'Gün: ${day.round()}  (Dünya ${formatTr(earthTurns)} tur attı)',
        ),
        Slider(
          key: const Key('galileoDay'),
          value: day.clamp(0, 730).toDouble(),
          min: 0,
          max: 730,
          divisions: 146,
          onChanged: controller.setDay,
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('galileoVenusInfo'),
          color: Colors.indigo.shade50,
          icon: Icons.brightness_3,
          title: "Dünya'dan Venüs: ${view.phase.label.toLowerCase()}",
          text:
              'Aydınlık kısım %${(view.litFraction * 100).round()}, '
              'boyu ${formatTr(view.relativeSize)} kat. '
              'Günleri ilerlet: Venüs yaklaştıkça büyüyüp inceliyor, '
              'uzaklaştıkça küçülüp doluyor.',
        ),
        LabInfoCard(
          icon: Icons.public,
          title: "Güneş'in etrafında bir tur",
          text: planets
              .map((p) => '${p.name}: ${formatTr(p.periodDays, digits: 0)} gün')
              .join(' · '),
        ),
      ],
    );
  }
}
