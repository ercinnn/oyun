import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/curie_controller.dart';
import '../data/curie_samples.dart';
import '../models/curie/curie_scene.dart';
import '../models/curie/geiger.dart';
import '../models/curie/shielding.dart';
import '../models/curie/therapy.dart';
import '../models/science/science_task.dart' show formatTr;
import '../widgets/curie/curie_scene_view.dart';
import '../widgets/science_lab/lab_split_layout.dart';

/// Puansız Curie'nin Laboratuvarı: sayaçla numune tarama, kalkanlar,
/// ışınla tedavi planı. Her istasyonda güvenlik notu vardır.
class CurieExploreScreen extends StatelessWidget {
  const CurieExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CurieController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<CurieStation>(
          key: const Key('curieStation'),
          segments: [
            for (final s in CurieStation.values)
              ButtonSegment(value: s, label: Text(s.label)),
          ],
          selected: {controller.station},
          showSelectedIcon: false,
          onSelectionChanged: (v) => controller.setStation(v.first),
        ),
        const SizedBox(height: 12),
        switch (controller.station) {
          CurieStation.geiger => _GeigerControls(controller: controller),
          CurieStation.shield => _ShieldControls(controller: controller),
          CurieStation.therapy => _TherapyControls(controller: controller),
        },
        const LabInfoCard(
          text: 'Güvenlik: Gerçek radyoaktif maddelere asla dokunulmaz; '
              'yalnızca uzmanlar, özel kalkanların arkasında çalışır. Marie '
              'Curie bunu bilmiyordu ve ışıma onu hasta etti — defterleri bugün '
              'bile kurşun kutularda saklanıyor. Bu laboratuvar bir benzetim.',
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curie\'nin Laboratuvarı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Geri',
          onPressed: controller.backToSetup,
        ),
      ),
      body: LabSplitLayout(
        scene: KeyedSubtree(
          key: const Key('scientistScene'),
          child: CurieSceneView(scene: controller.scene),
        ),
        panel: controls,
      ),
    );
  }
}

// ─────────────────────────── Sayaç ───────────────────────────

class _GeigerControls extends StatelessWidget {
  const _GeigerControls({required this.controller});

  final CurieController controller;

  @override
  Widget build(BuildContext context) {
    final sample = controller.sample;
    final cps = countsPerSecond(sample, controller.distanceCm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sayacı hangi numuneye tutalım?'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final s in curieSamples)
              ChoiceChip(
                key: Key('curieSample_${s.id}'),
                label: Text('${s.emoji} ${s.name}'),
                selected: s.id == sample?.id,
                onSelected: (_) => controller.pickSample(s),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Uzaklık: ${formatTr(controller.distanceCm)} cm'),
        Slider(
          key: const Key('curieDistance'),
          value: controller.distanceCm,
          min: counterMinCm,
          max: counterMaxCm,
          divisions: 9,
          onChanged: controller.setDistance,
        ),
        LabInfoCard(
          key: const Key('curieGeigerInfo'),
          color: sample != null && sample.radioactive
              ? Colors.red.shade50
              : Colors.blueGrey.shade50,
          text: sample == null
              ? 'Sayaç boşta bile ${formatTr(backgroundCps)} tık/sn sayar: '
                    'doğadan gelen zayıf arka plan. Bir numune seç!'
              : '${sample.name}: ${formatCps(cps)} tık/sn. '
                    '${sample.radioactive ? 'Işıma yapıyor!' : 'Arka plandan pek farkı yok.'} '
                    '${sample.note} Uzaklığı iki katına çıkar: tıklar dörtte '
                    'birine iner.',
        ),
      ],
    );
  }
}

// ─────────────────────────── Kalkanlar ───────────────────────────

class _ShieldControls extends StatelessWidget {
  const _ShieldControls({required this.controller});

  final CurieController controller;

  @override
  Widget build(BuildContext context) {
    final ray = controller.ray;
    final shield = controller.shield;
    final pass = transmission(ray, shield);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Kaynak hangi ışını yaysın?'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: [
            for (final r in RayType.values)
              ChoiceChip(
                key: Key('curieRay_${r.name}'),
                label: Text(r.label),
                selected: r == ray,
                onSelected: (_) => controller.setRay(r),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Araya ne koyalım?'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final s in Shield.values)
              ChoiceChip(
                key: Key('curieShield_${s.name}'),
                label: Text(s.label),
                selected: s == shield,
                onSelected: (_) => controller.setShield(s),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('curieShieldInfo'),
          color: pass < 0.1 ? Colors.green.shade50 : Colors.orange.shade50,
          text: '${ray.label} ışını, ${shield.label.toLowerCase()} ile: '
              '${formatCps(shieldedCps(ray, shield))} tık/sn '
              '(%${(pass * 100).round()} geçiyor). '
              '${pass < 0.1 ? 'Kalkan ışını durdurdu!' : 'Işın geçiyor; daha kalın bir kalkan dene.'}',
        ),
      ],
    );
  }
}

// ─────────────────────────── Tedavi ───────────────────────────

class _TherapyControls extends StatelessWidget {
  const _TherapyControls({required this.controller});

  final CurieController controller;

  @override
  Widget build(BuildContext context) {
    final dose = computeDose(controller.plan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Işın sayısı: ${controller.beamCount} '
            '(her biri ${formatTr(targetDose / controller.beamCount)} birim)'),
        Slider(
          key: const Key('curieBeams'),
          value: controller.beamCount.toDouble(),
          min: 1,
          max: curieMaxBeams.toDouble(),
          divisions: curieMaxBeams - 1,
          onChanged: (v) => controller.setBeamCount(v.round()),
        ),
        SwitchListTile(
          key: const Key('curieSpread'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Işınlar farklı yönlerden gelsin'),
          value: controller.spread,
          onChanged: controller.setSpread,
        ),
        FilledButton.icon(
          key: const Key('curieBeamsOn'),
          onPressed: () => controller.setBeamsOn(!controller.beamsOn),
          icon: Icon(controller.beamsOn ? Icons.stop : Icons.play_arrow),
          label: Text(controller.beamsOn ? 'Işınları kapat' : 'Işınları aç'),
        ),
        const SizedBox(height: 8),
        if (controller.beamsOn)
          LabInfoCard(
            key: const Key('curieTherapyInfo'),
            color: dose.safe ? Colors.green.shade50 : Colors.red.shade50,
            text: 'Tümör ${formatTr(dose.tumorDose)} birim aldı. Tümörden uzaktaki '
                'sağlıklı doku en çok ${formatTr(dose.maxHealthyDose)} birim aldı '
                '(sınır ${formatTr(safeHealthyDose)}). '
                '${dose.safe ? 'Sağlıklı doku korundu!' : 'Sağlıklı doku çok ışın aldı: ışınları farklı yönlere dağıt.'}',
          )
        else
          const LabInfoCard(
            text: 'Tümöre 6 birim ışın gerekiyor. Tek güçlü ışın mı, birçok zayıf '
                'ışın mı? Işınları açıp doz haritasına bak.',
          ),
      ],
    );
  }
}
