import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/fleming_controller.dart';
import '../models/fleming/fleming_scene.dart';
import '../models/fleming/hygiene.dart';
import '../models/fleming/petri.dart';
import '../models/fleming/resistance.dart';
import '../models/science/science_task.dart' show formatTr;
import '../widgets/fleming/fleming_scene_view.dart';
import '../widgets/science_lab/lab_split_layout.dart';
import '../widgets/science_lab/scientist_sound_toggle.dart';

/// Puansız Fleming'in Laboratuvarı: petri kabı (küf ve kontrol), temizlik,
/// doğru ilaç kullanımı.
class FlemingExploreScreen extends StatelessWidget {
  const FlemingExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FlemingController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<FlemingStation>(
          key: const Key('flemingStation'),
          segments: [
            for (final s in FlemingStation.values)
              ButtonSegment(value: s, label: Text(s.label)),
          ],
          selected: {controller.station},
          showSelectedIcon: false,
          onSelectionChanged: (v) => controller.setStation(v.first),
        ),
        const SizedBox(height: 12),
        switch (controller.station) {
          FlemingStation.petri => _PetriControls(controller: controller),
          FlemingStation.hygiene => _HygieneControls(controller: controller),
          FlemingStation.medicine => _MedicineControls(controller: controller),
        },
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleming\'in Laboratuvarı'),
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
          child: FlemingSceneView(scene: controller.scene),
        ),
        panel: controls,
      ),
    );
  }
}

class _PetriControls extends StatelessWidget {
  const _PetriControls({required this.controller});

  final FlemingController controller;

  @override
  Widget build(BuildContext context) {
    final d = controller.day;
    final a = livingColonies(d, mold: controller.mold);
    final b = livingColonies(d, mold: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('flemingMold'),
          contentPadding: EdgeInsets.zero,
          title: const Text('A kabına küf (Penicillium) koy'),
          subtitle: const Text('B kabı her zaman küfsüz: kontrol kabı'),
          value: controller.mold,
          onChanged: controller.setMold,
        ),
        Text('Gün: ${formatTr(d)}'),
        Slider(
          key: const Key('flemingDay'),
          value: d,
          min: 0,
          max: petriMaxDays.toDouble(),
          divisions: petriMaxDays,
          onChanged: controller.setDay,
        ),
        OutlinedButton.icon(
          key: const Key('flemingNextDay'),
          onPressed: d >= petriMaxDays ? null : controller.nextDay,
          icon: const Icon(Icons.wb_sunny),
          label: const Text('Bir gün beklet'),
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('flemingPetriInfo'),
          color: Colors.teal.shade50,
          text: d == 0
              ? 'Bakteriler ekildi ama henüz görünmüyorlar. Günleri ilerlet!'
              : 'A kabında $a, B kabında $b koloni var. '
                    '${controller.mold && d >= 1 ? 'Küfün çevresinde bakterisiz, temiz bir halka büyüyor: küf bakterileri öldüren bir madde (penisilin) salgılıyor!' : 'Küf olmayan kapta bakteriler her yeri kaplıyor.'}',
        ),
      ],
    );
  }
}

class _HygieneControls extends StatelessWidget {
  const _HygieneControls({required this.controller});

  final FlemingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('flemingLid'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Kabın kapağı açık kalsın'),
          value: controller.lidOpen,
          onChanged: controller.setLid,
        ),
        const Text('Kaba kim dokunsun?'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final h in HandTouch.values)
              ChoiceChip(
                key: Key('flemingHand_${h.name}'),
                label: Text(h.label),
                selected: h == controller.hand,
                onSelected: (_) => controller.setHand(h),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('flemingIncubate'),
          onPressed: controller.incubate,
          icon: const Icon(Icons.hourglass_bottom),
          label: const Text('$hygieneDays gün beklet'),
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('flemingHygieneInfo'),
          color: Colors.orange.shade50,
          text: controller.incubated
              ? '${controller.scene.hygieneCount} koloni üredi. Mikroplar havada '
                    've ellerimizde bulunur; sabunla yıkanmış el çok daha az '
                    'mikrop taşır. Yemekten önce ve tuvaletten sonra elini yıka!'
              : 'Önce tahmin et: bu kapta kaç koloni ürer? Sonra beklet.',
        ),
      ],
    );
  }
}

class _MedicineControls extends StatelessWidget {
  const _MedicineControls({required this.controller});

  final FlemingController controller;

  @override
  Widget build(BuildContext context) {
    final t = controller.treatmentDays;
    final end = finalPopulation(t);
    final done = controller.medicineDay >= observedDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('İlaç kaç gün kullanılsın? $t gün (doktor: $fullCourseDays gün)'),
        Slider(
          key: const Key('flemingTreatment'),
          value: t.toDouble(),
          min: 0,
          max: fullCourseDays.toDouble(),
          divisions: fullCourseDays,
          onChanged: (v) => controller.setTreatmentDays(v.round()),
        ),
        FilledButton.icon(
          key: const Key('flemingRunCourse'),
          onPressed: controller.runCourse,
          icon: const Icon(Icons.medication),
          label: const Text('$observedDays günü izle'),
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('flemingMedicineInfo'),
          color: done && end.cleared ? Colors.green.shade50 : Colors.red.shade50,
          text: !done
              ? 'Yeşiller ilaca duyarlı, kırmızılar dayanıklı bakteriler. İlacı '
                    'kaç gün kullanırsan bakteriler yok olur?'
              : end.cleared
              ? 'Tam süre kullanıldı: bakteri kalmadı, hastalık geçti!'
              : 'İlaç erken bırakıldı: kalan bakteriler yeniden çoğaldı ve '
                    '%${(end.resistantShare * 100).round()}\'i dayanıklı. '
                    'Hastalık geri döndü ve ilaç artık daha zor işe yarar.',
        ),
        const LabInfoCard(
          text: 'Unutma: Antibiyotiği yalnızca doktor verir. Grip ve soğuk '
              'algınlığı virüslerle olur; antibiyotik virüslere işe yaramaz.',
        ),
      ],
    );
  }
}
