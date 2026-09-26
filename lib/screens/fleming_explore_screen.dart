import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/fleming_controller.dart';
import '../models/fleming/fleming_scene.dart';
import '../models/fleming/hygiene.dart';
import '../models/fleming/petri.dart';
import '../models/fleming/resistance.dart';
import '../models/science/science_task.dart' show formatTr;
import '../widgets/fleming/fleming_scene_view.dart';
import '../widgets/science_lab/lab_guide.dart';
import '../widgets/science_lab/lab_split_layout.dart';
import '../widgets/science_lab/scientist_sound_toggle.dart';

/// Puansız Fleming'in Laboratuvarı: petri kabı (küf ve kontrol), temizlik,
/// doğru ilaç kullanımı.
class FlemingExploreScreen extends StatelessWidget {
  const FlemingExploreScreen({super.key});

  static const _stations = [
    LabStation(
      FlemingStation.petri,
      'Petri Kabı',
      '🧫',
      'Küflü kapla küfsüz kabı günler boyunca karşılaştır.',
    ),
    LabStation(
      FlemingStation.hygiene,
      'Temizlik',
      '🧼',
      'Mikroplar nereden geliyor? Kapak ve eller ne değiştiriyor?',
    ),
    LabStation(
      FlemingStation.medicine,
      'Doğru İlaç',
      '💊',
      'Antibiyotiği kaç gün kullanmak gerekiyor?',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FlemingController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStationPicker<FlemingStation>(
          key: const Key('flemingStation'),
          stations: _stations,
          selected: controller.station,
          onSelected: controller.setStation,
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
        LabStepList(
          steps: [
            LabStep(
              '"Bir gün beklet"e basıp iki kabı karşılaştır.',
              done: controller.sawMoldRing,
            ),
            LabStep(
              'Küfün çevresindeki bakterisiz halkayı bul.',
              done: controller.sawMoldRing && d >= 3,
            ),
            LabStep(
              'Küfü kaldır: A kabı da B gibi mi oldu?',
              done: controller.triedNoMold,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('flemingNextDay'),
          onPressed: d >= petriMaxDays ? null : controller.nextDay,
          icon: Icons.wb_sunny,
          label: 'Bir gün beklet',
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          key: const Key('flemingMold'),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'A kabına küf (Penicillium) koy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'B kabı her zaman küfsüz: kontrol kabı',
            style: TextStyle(fontSize: 14),
          ),
          value: controller.mold,
          onChanged: controller.setMold,
        ),
        LabSectionTitle('Gün: ${formatTr(d)}'),
        Slider(
          key: const Key('flemingDay'),
          value: d,
          min: 0,
          max: petriMaxDays.toDouble(),
          divisions: petriMaxDays,
          onChanged: controller.setDay,
        ),
        const SizedBox(height: 4),
        LabInfoCard(
          key: const Key('flemingPetriInfo'),
          color: Colors.teal.shade50,
          icon: Icons.biotech,
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
        LabStepList(
          steps: [
            LabStep(
              'Kabı "$hygieneDays gün beklet" ve kolonileri say.',
              done: controller.incubatedSetups.isNotEmpty,
            ),
            LabStep(
              'Kapağı aç ya da kaba yıkanmamış elle dokun, yeniden beklet.',
              done: controller.incubatedSetups.length >= 2,
            ),
            LabStep(
              'Yıkanmış elle dene: fark ne kadar?',
              done: controller.incubatedSetups.any(
                (s) => s.endsWith('/washed'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('flemingIncubate'),
          onPressed: controller.incubate,
          icon: Icons.hourglass_bottom,
          label: '$hygieneDays gün beklet',
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          key: const Key('flemingLid'),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Kabın kapağı açık kalsın',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          value: controller.lidOpen,
          onChanged: controller.setLid,
        ),
        const LabSectionTitle('Kaba kim dokunsun?'),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final h in HandTouch.values)
              ChoiceChip(
                key: Key('flemingHand_${h.name}'),
                label: Text(h.label, style: const TextStyle(fontSize: 15)),
                selected: h == controller.hand,
                onSelected: (_) => controller.setHand(h),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('flemingHygieneInfo'),
          color: Colors.orange.shade50,
          icon: Icons.clean_hands,
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
        LabStepList(
          steps: [
            LabStep(
              '"$observedDays günü izle"ye bas ve grafiğe bak.',
              done: controller.coursesRun.isNotEmpty,
            ),
            LabStep(
              'İlacı erken bırakınca ne oluyor, dene.',
              done: controller.coursesRun.any((d) => d < fullCourseDays),
            ),
            LabStep(
              'Doktorun dediği gibi $fullCourseDays gün kullan.',
              done: controller.coursesRun.contains(fullCourseDays),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('flemingRunCourse'),
          onPressed: controller.runCourse,
          icon: Icons.medication,
          label: '$observedDays günü izle',
        ),
        const SizedBox(height: 10),
        LabSectionTitle(
          'İlaç kaç gün kullanılsın? $t gün (doktor: $fullCourseDays gün)',
        ),
        Slider(
          key: const Key('flemingTreatment'),
          value: t.toDouble(),
          min: 0,
          max: fullCourseDays.toDouble(),
          divisions: fullCourseDays,
          onChanged: (v) => controller.setTreatmentDays(v.round()),
        ),
        const SizedBox(height: 4),
        LabInfoCard(
          key: const Key('flemingMedicineInfo'),
          color: done && end.cleared
              ? Colors.green.shade50
              : Colors.red.shade50,
          icon: Icons.medication_outlined,
          text: !done
              ? 'Yeşiller ilaca duyarlı, kırmızılar dayanıklı bakteriler. İlacı '
                    'kaç gün kullanırsan bakteriler yok olur?'
              : end.cleared
              ? 'Tam süre kullanıldı: bakteri kalmadı, hastalık geçti!'
              : 'İlaç erken bırakıldı: kalan bakteriler yeniden çoğaldı ve '
                    '%${(end.resistantShare * 100).round()}\'i dayanıklı. '
                    'Hastalık geri döndü ve ilaç artık daha zor işe yarar.',
        ),
        LabInfoCard(
          color: Colors.blue.shade50,
          icon: Icons.health_and_safety,
          text:
              'Unutma: Antibiyotiği yalnızca doktor verir. Grip ve soğuk '
              'algınlığı virüslerle olur; antibiyotik virüslere işe yaramaz.',
        ),
      ],
    );
  }
}
