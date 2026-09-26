import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/einstein_controller.dart';
import '../models/einstein/einstein_scene.dart';
import '../models/einstein/mass_energy.dart';
import '../models/einstein/spacetime.dart';
import '../models/einstein/time_dilation.dart';
import '../models/science/science_task.dart' show formatTr;
import '../widgets/einstein/einstein_scene_view.dart';
import '../widgets/science_lab/lab_guide.dart';
import '../widgets/science_lab/lab_split_layout.dart';
import '../widgets/science_lab/scientist_sound_toggle.dart';

/// Puansız Einstein'ın Laboratuvarı: uzay-zaman örtüsü, ışık saati, E=mc².
class EinsteinExploreScreen extends StatelessWidget {
  const EinsteinExploreScreen({super.key});

  static const _stations = [
    LabStation(
      EinsteinStation.sheet,
      'Uzay-Zaman',
      '🕳️',
      'Kütle örtüyü büker: bilye düşecek mi, dönecek mi, kaçacak mı?',
    ),
    LabStation(
      EinsteinStation.clock,
      'Işık Saati',
      '⏱️',
      'Çok hızlı giden gemide zaman nasıl akıyor?',
    ),
    LabStation(
      EinsteinStation.energy,
      'E=mc²',
      '⚡',
      'Minik bir kütle ne kadar enerji eder? (düşünce deneyi)',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EinsteinController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStationPicker<EinsteinStation>(
          key: const Key('einsteinStation'),
          stations: _stations,
          selected: controller.station,
          onSelected: controller.setStation,
        ),
        const SizedBox(height: 12),
        switch (controller.station) {
          EinsteinStation.sheet => _SheetControls(controller: controller),
          EinsteinStation.clock => _ClockControls(controller: controller),
          EinsteinStation.energy => _EnergyControls(controller: controller),
        },
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstein\'ın Laboratuvarı'),
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
          child: EinsteinSceneView(scene: controller.scene),
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

class _SheetControls extends StatelessWidget {
  const _SheetControls({required this.controller});

  final EinsteinController controller;

  @override
  Widget build(BuildContext context) {
    final fate = simulateMarble(controller.center, controller.speed).fate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep(
              'Bilyeyi fırlat ve yolunu izle.',
              done: controller.fatesSeen.isNotEmpty,
            ),
            LabStep(
              'Bilyeyi yörüngeye oturtan hızı bul.',
              done: controller.fatesSeen.contains(MarbleFate.orbits),
            ),
            LabStep(
              'Ortadaki kütleyi değiştirip yeniden fırlat.',
              done: controller.centersLaunched.length >= 2,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('einsteinLaunch'),
          onPressed: controller.launch,
          icon: Icons.sports_baseball,
          label: controller.launched ? 'Yeniden fırlat' : 'Bilyeyi fırlat',
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Örtünün ortasına ne koyalım?'),
        _chips<CentralMass>(
          values: CentralMass.values,
          selected: controller.center,
          label: (c) => c.label,
          onSelected: controller.setCenter,
          keyOf: (c) => 'einsteinCenter_${c.name}',
        ),
        const SizedBox(height: 6),
        const LabSectionTitle('Bilyeyi ne hızla fırlatalım?'),
        _chips<LaunchSpeed>(
          values: LaunchSpeed.values,
          selected: controller.speed,
          label: (s) => s.label,
          onSelected: controller.setSpeed,
          keyOf: (s) => 'einsteinSpeed_${s.name}',
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('einsteinSheetInfo'),
          color: Colors.indigo.shade50,
          icon: Icons.blur_circular,
          text: controller.launched
              ? 'Bilye ${fate.label.toLowerCase()}. Ağır kütle örtüyü daha derin '
                    'çukurlaştırır; bilyenin kurtulması için daha hızlı olması gerekir.'
              : 'Önce tahmin et: bilye düşecek mi, dönecek mi, kaçacak mı? Sonra fırlat!',
        ),
      ],
    );
  }
}

class _ClockControls extends StatelessWidget {
  const _ClockControls({required this.controller});

  final EinsteinController controller;

  @override
  Widget build(BuildContext context) {
    final v = controller.shipSpeed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep(
              '"Yolculuğa çık"a bas, iki saati karşılaştır.',
              done: controller.voyageSpeeds.isNotEmpty,
            ),
            LabStep(
              'Geminin hızını değiştirip yeniden yolculuğa çık.',
              done: controller.voyageSpeeds.length >= 2,
            ),
            LabStep(
              'En hızlı gemiyle yolculuk yap.',
              done: controller.voyageSpeeds.contains(shipSpeeds.last),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('einsteinVoyage'),
          onPressed: controller.startVoyage,
          icon: Icons.rocket_launch,
          label: '10 yıllık yolculuğa çık',
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Geminin hızı (ışık hızına göre)'),
        _chips<double>(
          values: shipSpeeds,
          selected: v,
          label: percentOfC,
          onSelected: controller.setShipSpeed,
          keyOf: (s) => 'einsteinShip_${(s * 100).round()}',
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('einsteinClockInfo'),
          color: Colors.amber.shade50,
          icon: Icons.timer,
          text:
              'Dünya\'da 10 yıl geçerken gemide ${formatTr(shipYears(10, v))} yıl '
              'geçer. ${v == 0 ? 'Gemi dururken iki saat aynı işler.' : 'Hızlı giden saat yavaş işler: gemideki ışık daha uzun, çapraz bir yol gider.'} '
              '(Işık hızına hiçbir şey ulaşamaz; bu yüzden en fazla %99.)',
        ),
      ],
    );
  }
}

class _EnergyControls extends StatelessWidget {
  const _EnergyControls({required this.controller});

  final EinsteinController controller;

  @override
  Widget build(BuildContext context) {
    final g = controller.grams;
    final selected = tinyMasses.firstWhere(
      (m) => m.grams == g,
      orElse: () => tinyMasses.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep(
              'Bir kütle seç ve enerjiye çevir.',
              done: controller.massesConverted.isNotEmpty,
            ),
            LabStep(
              'Başka bir kütleyle karşılaştır.',
              done: controller.massesConverted.length >= 2,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('einsteinConvert'),
          onPressed: controller.convert,
          icon: Icons.bolt,
          label: 'Enerjiye çevir',
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Hangi minik kütle?'),
        _chips<TinyMass>(
          values: tinyMasses,
          selected: selected,
          label: (m) => '${m.emoji} ${m.name} (${formatGrams(m.grams)} g)',
          onSelected: (m) => controller.setGrams(m.grams),
          keyOf: (m) => 'einsteinMass_${m.id}',
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('einsteinEnergyInfo'),
          color: Colors.yellow.shade50,
          icon: Icons.lightbulb_outline,
          title: 'Bu bir düşünce deneyi',
          text:
              '${selected.name}: ${friendlyNumber(homesPowered(g))} evin bir yıllık '
              'elektriği! Aynı kütleyi odun gibi yaksaydık yalnızca '
              '${friendlyNumber(homesFromBurning(g))} evinkini verirdi. '
              'E = m·c²: ışık hızı (c) çok büyük olduğu için minik kütle dev '
              'enerjidir. Gerçekte kütlenin çok küçük bir kısmı enerjiye '
              'dönüştürülebilir; Güneş böyle parlar.',
        ),
      ],
    );
  }
}
