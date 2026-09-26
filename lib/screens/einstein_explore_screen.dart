import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/einstein_controller.dart';
import '../models/einstein/einstein_scene.dart';
import '../models/einstein/mass_energy.dart';
import '../models/einstein/spacetime.dart';
import '../models/einstein/time_dilation.dart';
import '../models/science/science_task.dart' show formatTr;
import '../widgets/einstein/einstein_scene_view.dart';
import '../widgets/science_lab/lab_split_layout.dart';

/// Puansız Einstein'ın Laboratuvarı: uzay-zaman örtüsü, ışık saati, E=mc².
class EinsteinExploreScreen extends StatelessWidget {
  const EinsteinExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EinsteinController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<EinsteinStation>(
          key: const Key('einsteinStation'),
          segments: [
            for (final s in EinsteinStation.values)
              ButtonSegment(value: s, label: Text(s.label)),
          ],
          selected: {controller.station},
          showSelectedIcon: false,
          onSelectionChanged: (v) => controller.setStation(v.first),
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
        label: Text(label(v)),
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
        const Text('Örtünün ortasına ne koyalım?'),
        const SizedBox(height: 4),
        _chips<CentralMass>(
          values: CentralMass.values,
          selected: controller.center,
          label: (c) => c.label,
          onSelected: controller.setCenter,
          keyOf: (c) => 'einsteinCenter_${c.name}',
        ),
        const SizedBox(height: 8),
        const Text('Bilyeyi ne hızla fırlatalım?'),
        const SizedBox(height: 4),
        _chips<LaunchSpeed>(
          values: LaunchSpeed.values,
          selected: controller.speed,
          label: (s) => s.label,
          onSelected: controller.setSpeed,
          keyOf: (s) => 'einsteinSpeed_${s.name}',
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('einsteinLaunch'),
          onPressed: controller.launch,
          icon: const Icon(Icons.sports_baseball),
          label: Text(controller.launched ? 'Yeniden fırlat' : 'Bilyeyi fırlat'),
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('einsteinSheetInfo'),
          color: Colors.indigo.shade50,
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
        const Text('Geminin hızı (ışık hızına göre):'),
        const SizedBox(height: 4),
        _chips<double>(
          values: shipSpeeds,
          selected: v,
          label: percentOfC,
          onSelected: controller.setShipSpeed,
          keyOf: (s) => 'einsteinShip_${(s * 100).round()}',
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('einsteinVoyage'),
          onPressed: controller.startVoyage,
          icon: const Icon(Icons.rocket_launch),
          label: const Text('10 yıllık yolculuğa çık'),
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('einsteinClockInfo'),
          color: Colors.amber.shade50,
          text: 'Dünya\'da 10 yıl geçerken gemide ${formatTr(shipYears(10, v))} yıl '
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
        const Text('Hangi minik kütle?'),
        const SizedBox(height: 4),
        _chips<TinyMass>(
          values: tinyMasses,
          selected: selected,
          label: (m) => '${m.emoji} ${m.name} (${formatGrams(m.grams)} g)',
          onSelected: (m) => controller.setGrams(m.grams),
          keyOf: (m) => 'einsteinMass_${m.id}',
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('einsteinConvert'),
          onPressed: controller.convert,
          icon: const Icon(Icons.bolt),
          label: const Text('Enerjiye çevir (düşünce deneyi)'),
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('einsteinEnergyInfo'),
          color: Colors.yellow.shade50,
          text: '${selected.name}: ${friendlyNumber(homesPowered(g))} evin bir yıllık '
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
