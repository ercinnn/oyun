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
import '../widgets/science_lab/lab_guide.dart';
import '../widgets/science_lab/lab_split_layout.dart';
import '../widgets/science_lab/lab_style.dart';
import '../widgets/science_lab/scientist_sound_toggle.dart';

/// Puansız Keşif Atölyesi: su kabı, gemi ve Arşimet vidası istasyonları.
/// Hiçbir şey engellenmez; açıklamalar çocuğun o an yaptığı denemeye göre
/// değişir. Her istasyonda bir adım listesi ne yapılacağını gösterir ve ana
/// eylem (Suya bırak / Sandık ekle / kol) en büyük denetimdir.
class ArchimedesExploreScreen extends StatelessWidget {
  const ArchimedesExploreScreen({super.key});

  static const _stations = [
    LabStation(
      ArchimedesStation.tank,
      'Su Kabı',
      '💧',
      'Cisimleri suya bırak: yüzüyor mu, suyu ne kadar yükseltiyor?',
    ),
    LabStation(
      ArchimedesStation.boat,
      'Gemi',
      '⛵',
      'Gemiye sandık yükle: kaç sandıkta su içeri doluyor?',
    ),
    LabStation(
      ArchimedesStation.screw,
      'Arşimet Vidası',
      '🌀',
      'Kolu çevir, nehirdeki suyu yukarıdaki tarlaya çıkar.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ArchimedesController>();
    final scene = ArchimedesSceneView(scene: controller.scene);
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStationPicker<ArchimedesStation>(
          key: const Key('archimedesStation'),
          stations: _stations,
          selected: controller.station,
          onSelected: controller.setStation,
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
        actions: [ScientistSoundToggle(controller: controller)],
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

/// Ölçüm satırı: büyük, kalın yazılı değer (su seviyesi, tarla…).
class _Reading extends StatelessWidget {
  const _Reading(this.text, {super.key, this.icon = Icons.straighten});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 22, color: Colors.blue.shade700),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      ),
    ],
  );
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
    final tried = controller.droppedIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep(
              'Bir cisim seç ve "Suya bırak"a bas.',
              done: tried.isNotEmpty,
            ),
            LabStep(
              'Bir cisim daha bırak: su yine yükseliyor mu?',
              done: tried.length >= 2,
            ),
            LabStep(
              'Oyun hamurunu önce top, sonra kase olarak dene.',
              done: tried.contains('clay_ball') && tried.contains('clay_bowl'),
            ),
            LabStep(
              'Kabı boşalt ve yeni bir deney kur.',
              done: controller.tankEmptiedOnce,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Cisimler'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in archimedesObjects)
              ChoiceChip(
                key: Key('archObj_${o.id}'),
                label: Text(
                  '${o.emoji} ${o.name}',
                  style: const TextStyle(fontSize: 15),
                ),
                selected: o.id == selected.id,
                onSelected: (_) => controller.selectObject(o),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LabActionButton(
          key: const Key('archimedesDrop'),
          icon: Icons.water_drop,
          label: alreadyIn
              ? '${selected.name} zaten suda'
              : '${selected.emoji} Suya bırak',
          onPressed: controller.tankFull || alreadyIn
              ? null
              : controller.dropSelected,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Reading(
                'Su seviyesi: ${formatTr(level)} cm (başta ${formatTr(tankStartWaterCm)} cm)',
                key: const Key('archimedesLevel'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const Key('archimedesEmpty'),
              onPressed: inTank.isEmpty ? null : controller.emptyTank,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Kabı boşalt'),
            ),
          ],
        ),
        if (controller.tankFull)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Kap doldu! Yeni deney için kabı boşalt.',
              style: TextStyle(fontSize: LabText.body, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 8),
        if (last != null)
          LabInfoCard(
            color: last.floats ? Colors.lightBlue.shade50 : Colors.brown.shade50,
            icon: last.floats ? Icons.sailing : Icons.anchor,
            title: '${last.emoji} ${last.name} ${last.floats ? 'yüzdü' : 'battı'}',
            text: 'Suyu ${formatTr(last.waterRiseCm)} cm yükseltti. ${last.note}',
          )
        else
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
        LabStepList(
          steps: [
            LabStep(
              '"Sandık ekle" ile gemiye yük koy.',
              done: controller.loadedBoats.isNotEmpty,
            ),
            LabStep(
              'Su içeri dolana kadar sandık eklemeye devam et.',
              done: controller.boatSankOnce,
            ),
            LabStep(
              'Başka bir gemi seç: o kaç sandık taşıyor?',
              done: controller.loadedBoats.length >= 2,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Gemiler'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final b in archimedesBoats)
              ChoiceChip(
                key: Key('archBoat_${b.id}'),
                label: Text(
                  '${b.emoji} ${b.name}',
                  style: const TextStyle(fontSize: 15),
                ),
                selected: b.id == boat.id,
                onSelected: (_) => controller.selectBoat(b),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton.outlined(
              key: const Key('archimedesCrateMinus'),
              tooltip: 'Sandık çıkar',
              iconSize: 28,
              onPressed: crates == 0 ? null : controller.removeCrate,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LabActionButton(
                key: const Key('archimedesCratePlus'),
                icon: Icons.add_box,
                label: 'Sandık ekle',
                onPressed: sunk ? null : controller.addCrate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '$crates sandık',
            key: const Key('archimedesCrates'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        LabInfoCard(
          color: sunk ? Colors.red.shade50 : Colors.lightBlue.shade50,
          icon: sunk ? Icons.warning_amber : Icons.sailing,
          title: sunk ? 'Battı!' : 'Gemi yüzüyor',
          text: sunk
              ? 'Gemi ve yük ${formatTr(pushed, digits: 0)} gram ama '
                    'gövde tamamen suya gömülünce bile en çok '
                    '${formatTr(boat.hullVolumeCm3, digits: 0)} gram su itebiliyor. '
                    'Bir sandık azalt.'
              : 'Gemi ve yük ${formatTr(pushed, digits: 0)} gram. Gemi, tam bu '
                    'kadar su itene kadar suya gömüldü: '
                    '${formatTr(boat.draftCm(crates))} cm. Her sandık onu biraz '
                    'daha aşağı iter.',
        ),
        LabInfoCard(
          icon: Icons.help_outline,
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
        LabStepList(
          steps: [
            LabStep(
              'Yuvarlak kolu parmağınla saat yönünde çevir.',
              done: controller.crankedAngles.isNotEmpty,
            ),
            LabStep(
              'Açıyı değiştirip yeniden çevir: tur başına kaç litre?',
              done: controller.crankedAngles.length >= 2,
            ),
            LabStep(
              'Tarlayı ${fieldNeedLitres.round()} litreye kadar sula.',
              done: progress >= 1,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabSectionTitle('Vidanın açısı: ${angle.round()}°'),
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
                  const Row(
                    children: [
                      Icon(Icons.rotate_right, size: 22),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Kolu saat yönünde çevir!',
                          style: TextStyle(
                            fontSize: LabText.body,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tur başına ${formatTr(perTurn)} litre',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      color: Colors.green.shade600,
                      backgroundColor: Colors.brown.shade100,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Reading(
                    'Tarla: ${controller.fieldLitres.round()} / '
                    '${fieldNeedLitres.round()} litre',
                    key: const Key('archimedesField'),
                    icon: Icons.grass,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          color: perTurn > 0 ? Colors.green.shade50 : Colors.orange.shade50,
          icon: perTurn > 0 ? Icons.check_circle_outline : Icons.warning_amber,
          text: screwVerdict(angle),
        ),
        if (progress >= 1)
          LabInfoCard(
            color: Colors.green.shade100,
            icon: Icons.celebration,
            title: 'Tarla sulandı!',
            text: 'Vida suyu kimse taşımadan yukarı çıkardı. '
                'Başka bir açıyla daha az turda sulayabilir misin?',
          ),
        TextButton.icon(
          key: const Key('archimedesDryField'),
          onPressed: controller.fieldLitres == 0 ? null : controller.resetField,
          icon: const Icon(Icons.refresh),
          label: const Text('Tarlayı kurut, yeniden dene'),
        ),
      ],
    );
  }
}
