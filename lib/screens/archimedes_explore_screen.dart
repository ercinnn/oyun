import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/archimedes_controller.dart';
import '../data/archimedes_objects.dart';
import '../models/archimedes/archimedes_scene.dart';
import '../models/archimedes/archimedes_screw.dart';
import '../models/science/science_task.dart' show formatTr;
import '../models/archimedes/boat.dart';
import '../models/archimedes/buoyancy.dart';
import '../widgets/archimedes/archimedes_scene_view.dart';
import '../widgets/archimedes/crank_dial.dart';
import '../widgets/science_lab/lab_split_layout.dart';

/// Puansız Keşif Atölyesi: su kabı, gemi ve Arşimet vidası istasyonları.
/// Hiçbir şey engellenmez; açıklamalar çocuğun o an yaptığı denemeye göre
/// değişir.
class ArchimedesExploreScreen extends StatelessWidget {
  const ArchimedesExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ArchimedesController>();
    final scene = ArchimedesSceneView(scene: controller.scene);
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ArchimedesStation>(
          key: const Key('archimedesStation'),
          segments: [
            for (final s in ArchimedesStation.values)
              ButtonSegment(value: s, label: Text(s.label)),
          ],
          selected: {controller.station},
          showSelectedIcon: false,
          onSelectionChanged: (v) => controller.setStation(v.first),
        ),
        const SizedBox(height: 12),
        switch (controller.station) {
          ArchimedesStation.tank => _TankControls(controller: controller),
          ArchimedesStation.boat => _BoatControls(controller: controller),
          ArchimedesStation.screw => _ScrewControls(controller: controller),
        },
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşif Atölyesi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Geri',
          onPressed: controller.backToSetup,
        ),
      ),
      body: LabSplitLayout(
        scene: KeyedSubtree(key: const Key('scientistScene'), child: scene),
        panel: controls,
      ),
    );
  }
}

// ─────────────────────────── Su kabı ───────────────────────────

class _TankControls extends StatelessWidget {
  const _TankControls({required this.controller});

  final ArchimedesController controller;

  @override
  Widget build(BuildContext context) {
    final inTank = controller.tankObjects;
    final selected = controller.selectedObject;
    final alreadyIn = inTank.any((o) => o.id == selected.id);
    final last = inTank.isEmpty ? null : inTank.last;
    final level = tankWaterLevelCm(inTank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Bir cisim seç, sonra suya bırak:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in archimedesObjects)
              ChoiceChip(
                key: Key('archObj_${o.id}'),
                label: Text('${o.emoji} ${o.name}'),
                selected: o.id == selected.id,
                onSelected: (_) => controller.selectObject(o),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('archimedesDrop'),
                onPressed: controller.tankFull || alreadyIn
                    ? null
                    : controller.dropSelected,
                icon: const Icon(Icons.water_drop),
                label: const Text('Suya bırak'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              key: const Key('archimedesEmpty'),
              onPressed: inTank.isEmpty ? null : controller.emptyTank,
              child: const Text('Kabı boşalt'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Su seviyesi: ${formatTr(level)} cm (başta ${formatTr(tankStartWaterCm)} cm)',
          key: const Key('archimedesLevel'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (controller.tankFull)
          const Text('Kap doldu! Yeni deney için kabı boşalt.'),
        if (last != null) ...[
          const SizedBox(height: 8),
          LabInfoCard(
            color: last.floats ? Colors.lightBlue.shade50 : Colors.brown.shade50,
            text: '${last.emoji} ${last.name}: '
                '${last.floats ? 'yüzdü' : 'battı'}. '
                'Suyu ${formatTr(last.waterRiseCm)} cm yükseltti. ${last.note}',
          ),
        ] else
          const LabInfoCard(
            text: 'İpucu: Oyun hamurunu önce top, sonra kase olarak dene. '
                'Aynı hamur, aynı ağırlık... sonuç aynı mı?',
          ),
      ],
    );
  }
}

// ─────────────────────────── Gemi ───────────────────────────

class _BoatControls extends StatelessWidget {
  const _BoatControls({required this.controller});

  final ArchimedesController controller;

  @override
  Widget build(BuildContext context) {
    final boat = controller.exploreBoat;
    final crates = controller.exploreCrates;
    final sunk = boat.sinks(crates);
    final pushed = boat.totalMassG(crates);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          children: [
            for (final b in archimedesBoats)
              ChoiceChip(
                key: Key('archBoat_${b.id}'),
                label: Text('${b.emoji} ${b.name}'),
                selected: b.id == boat.id,
                onSelected: (_) => controller.selectBoat(b),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              key: const Key('archimedesCrateMinus'),
              onPressed: crates == 0 ? null : controller.removeCrate,
              icon: const Icon(Icons.remove),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$crates sandık',
                  key: const Key('archimedesCrates'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            IconButton.filled(
              key: const Key('archimedesCratePlus'),
              onPressed: sunk ? null : controller.addCrate,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          color: sunk ? Colors.red.shade50 : Colors.lightBlue.shade50,
          text: sunk
              ? 'Battı! Gemi ve yük ${formatTr(pushed, digits: 0)} gram ama '
                    'gövde tamamen suya gömülünce bile en çok '
                    '${formatTr(boat.hullVolumeCm3, digits: 0)} gram su itebiliyor. '
                    'Bir sandık azalt.'
              : 'Gemi ve yük ${formatTr(pushed, digits: 0)} gram. Gemi, tam bu '
                    'kadar su itene kadar suya gömüldü: '
                    '${formatTr(boat.draftCm(crates))} cm. Her sandık onu biraz '
                    'daha aşağı iter.',
        ),
        LabInfoCard(
          text: 'Her sandık ${formatTr(crateMassG, digits: 0)} gram. '
              '${boat.name} en çok ${boat.maxCrates} sandık taşıyabilir. '
              'Bulabildin mi?',
        ),
      ],
    );
  }
}

// ─────────────────────────── Vida ───────────────────────────

class _ScrewControls extends StatelessWidget {
  const _ScrewControls({required this.controller});

  final ArchimedesController controller;

  @override
  Widget build(BuildContext context) {
    final angle = controller.screwAngle;
    final perTurn = screwLitresPerTurn(angle);
    final progress = controller.fieldLitres / fieldNeedLitres;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Vidanın açısı: ${angle.round()}°'),
        Slider(
          key: const Key('archimedesAngle'),
          value: angle,
          min: screwMinAngle,
          max: screwMaxAngle,
          divisions: ((screwMaxAngle - screwMinAngle) / 5).round(),
          label: '${angle.round()}°',
          onChanged: controller.setScrewAngle,
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CrankDial(
              key: const Key('archimedesCrank'),
              onTurn: controller.turnCrank,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kolu saat yönünde çevir!'),
                  const SizedBox(height: 6),
                  Text(
                    'Tur başına ${formatTr(perTurn)} litre',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 4),
                  Text(
                    'Tarla: ${controller.fieldLitres.round()} / '
                    '${fieldNeedLitres.round()} litre',
                    key: const Key('archimedesField'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          color: perTurn > 0 ? Colors.green.shade50 : Colors.orange.shade50,
          text: screwVerdict(angle),
        ),
        if (progress >= 1)
          LabInfoCard(
            color: Colors.green.shade100,
            text: 'Tarla sulandı! Vida suyu kimse taşımadan yukarı çıkardı. '
                'Başka bir açıyla daha az turda sulayabilir misin?',
          ),
        TextButton(
          key: const Key('archimedesDryField'),
          onPressed: controller.fieldLitres == 0 ? null : controller.resetField,
          child: const Text('Tarlayı kurut, yeniden dene'),
        ),
      ],
    );
  }
}
