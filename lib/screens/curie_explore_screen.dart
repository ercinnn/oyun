import 'dart:async';
import 'dart:math';

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
import '../widgets/science_lab/lab_guide.dart';
import '../widgets/science_lab/lab_split_layout.dart';
import '../widgets/science_lab/scientist_sound_toggle.dart';

/// Puansız Curie'nin Laboratuvarı: sayaçla numune tarama, kalkanlar,
/// ışınla tedavi planı. Her istasyonda güvenlik notu vardır.
class CurieExploreScreen extends StatelessWidget {
  const CurieExploreScreen({super.key});

  static const _stations = [
    LabStation(
      CurieStation.geiger,
      'Sayaçla Keşif',
      '📟',
      'Sayacı numunelere tut: hangisi görünmez ışın yayıyor?',
    ),
    LabStation(
      CurieStation.shield,
      'Kalkanlar',
      '🛡️',
      'Işının önüne kalkan koy: hangisi onu durduruyor?',
    ),
    LabStation(
      CurieStation.therapy,
      'Işınla Tedavi',
      '🏥',
      'Tümörü tedavi et, sağlıklı dokuyu koru.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CurieController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStationPicker<CurieStation>(
          key: const Key('curieStation'),
          stations: _stations,
          selected: controller.station,
          onSelected: controller.setStation,
        ),
        const SizedBox(height: 12),
        switch (controller.station) {
          CurieStation.geiger => _GeigerControls(controller: controller),
          CurieStation.shield => _ShieldControls(controller: controller),
          CurieStation.therapy => _TherapyControls(controller: controller),
        },
        // Sayaç istasyonunda ses açıksa gerçek bir Geiger sayacı gibi tıklar.
        if (controller.station == CurieStation.geiger && controller.soundOn)
          _GeigerClicker(controller: controller),
        LabInfoCard(
          color: Colors.red.shade50,
          icon: Icons.health_and_safety,
          title: 'Güvenlik',
          text:
              'Gerçek radyoaktif maddelere asla dokunulmaz; '
              'yalnızca uzmanlar, özel kalkanların arkasında çalışır. Marie '
              'Curie bunu bilmiyordu ve ışıma onu hasta etti — defterleri bugün '
              'bile kurşun kutularda saklanıyor. Bu laboratuvar bir benzetim.',
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curie\'nin Laboratuvarı'),
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
          child: CurieSceneView(scene: controller.scene),
        ),
        panel: controls,
      ),
    );
  }
}

// ─────────────────────────── Sayaç ───────────────────────────

/// Görünmez bir yardımcı: her [_tick]'te, modeldeki sayım hızına göre
/// (tık/sn × aralık olasılığıyla) bir Geiger tıkı çalar. Arka plan ışıması
/// da tıklar, tıpkı gerçek sayaçta olduğu gibi. Hız [_maxCps]'te kesilir
/// (çok hızlı tıklar Android'de aynı klibi sürekli baştan başlatırdı).
/// Yalnızca ses açıkken kurulur; testlerde ses servisi olmadığı için
/// zamanlayıcı hiç oluşmaz.
class _GeigerClicker extends StatefulWidget {
  const _GeigerClicker({required this.controller});

  final CurieController controller;

  @override
  State<_GeigerClicker> createState() => _GeigerClickerState();
}

class _GeigerClickerState extends State<_GeigerClicker> {
  static const _tick = Duration(milliseconds: 40);
  static const _maxCps = 22.0;

  final _rng = Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) {
      final c = widget.controller;
      final cps = min(_maxCps, countsPerSecond(c.sample, c.distanceCm));
      if (_rng.nextDouble() < cps * _tick.inMilliseconds / 1000) {
        c.geigerClick();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

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
        LabStepList(
          steps: [
            LabStep(
              'Bir numune seç: sayaç kaç kez tıklıyor?',
              done: controller.samplesScanned.isNotEmpty,
            ),
            LabStep(
              'Işıma yapan bir numune bul.',
              done: controller.foundRadioactive,
            ),
            LabStep(
              'Sondayı uzaklaştır: tıklar azalıyor mu?',
              done: controller.movedProbeAway,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Sayacı hangi numuneye tutalım?'),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final s in curieSamples)
              ChoiceChip(
                key: Key('curieSample_${s.id}'),
                label: Text(
                  '${s.emoji} ${s.name}',
                  style: const TextStyle(fontSize: 15),
                ),
                selected: s.id == sample?.id,
                onSelected: (_) => controller.pickSample(s),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 8),
        LabSectionTitle(
          'Sondanın uzaklığı: ${formatTr(controller.distanceCm)} cm',
        ),
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
          icon: Icons.sensors,
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
        LabStepList(
          steps: [
            LabStep(
              'Işının önüne bir kalkan koy.',
              done: controller.shieldsTried.any((s) => s != Shield.none),
            ),
            LabStep(
              'Işını durduran en ince kalkanı bul.',
              done: controller.stoppedWithThinnest,
            ),
            LabStep(
              'Başka bir ışın türüyle tekrarla.',
              done: controller.raysTried.length >= 2,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Kaynak hangi ışını yaysın?'),
        Wrap(
          spacing: 6,
          children: [
            for (final r in RayType.values)
              ChoiceChip(
                key: Key('curieRay_${r.name}'),
                label: Text(r.label, style: const TextStyle(fontSize: 15)),
                selected: r == ray,
                onSelected: (_) => controller.setRay(r),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const LabSectionTitle('Araya ne koyalım?'),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final s in Shield.values)
              ChoiceChip(
                key: Key('curieShield_${s.name}'),
                label: Text(s.label, style: const TextStyle(fontSize: 15)),
                selected: s == shield,
                onSelected: (_) => controller.setShield(s),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('curieShieldInfo'),
          color: pass < 0.1 ? Colors.green.shade50 : Colors.orange.shade50,
          icon: Icons.shield_outlined,
          text:
              '${ray.label} ışını, ${shield.label.toLowerCase()} ile: '
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
        LabStepList(
          steps: [
            LabStep(
              '"Işınları aç"a bas ve doz haritasına bak.',
              done: controller.beamsTurnedOn,
            ),
            LabStep(
              'Işın sayısını artır.',
              done: controller.beamCountsTried.length >= 2,
            ),
            LabStep(
              'Sağlıklı dokuyu koruyan bir plan bul.',
              done: controller.sawSafePlan,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('curieBeamsOn'),
          onPressed: () => controller.setBeamsOn(!controller.beamsOn),
          icon: controller.beamsOn ? Icons.stop : Icons.play_arrow,
          label: controller.beamsOn ? 'Işınları kapat' : 'Işınları aç',
        ),
        const SizedBox(height: 10),
        LabSectionTitle(
          'Işın sayısı: ${controller.beamCount} '
          '(her biri ${formatTr(targetDose / controller.beamCount)} birim)',
        ),
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
          title: const Text(
            'Işınlar farklı yönlerden gelsin',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          value: controller.spread,
          onChanged: controller.setSpread,
        ),
        const SizedBox(height: 8),
        if (controller.beamsOn)
          LabInfoCard(
            key: const Key('curieTherapyInfo'),
            color: dose.safe ? Colors.green.shade50 : Colors.red.shade50,
            icon: dose.safe ? Icons.check_circle_outline : Icons.warning_amber,
            text:
                'Tümör ${formatTr(dose.tumorDose)} birim aldı. Tümörden uzaktaki '
                'sağlıklı doku en çok ${formatTr(dose.maxHealthyDose)} birim aldı '
                '(sınır ${formatTr(safeHealthyDose)}). '
                '${dose.safe ? 'Sağlıklı doku korundu!' : 'Sağlıklı doku çok ışın aldı: ışınları farklı yönlere dağıt.'}',
          )
        else
          const LabInfoCard(
            text:
                'Tümöre 6 birim ışın gerekiyor. Tek güçlü ışın mı, birçok zayıf '
                'ışın mı? Işınları açıp doz haritasına bak.',
          ),
      ],
    );
  }
}
