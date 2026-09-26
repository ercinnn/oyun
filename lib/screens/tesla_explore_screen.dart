import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/tesla_controller.dart';
import '../models/science/science_task.dart' show formatTr;
import '../models/tesla/generator.dart';
import '../models/tesla/tesla_scene.dart';
import '../models/tesla/transmission.dart';
import '../models/tesla/wireless.dart';
import '../widgets/science_lab/lab_guide.dart';
import '../widgets/science_lab/lab_split_layout.dart';
import '../widgets/science_lab/scientist_sound_toggle.dart';
import '../widgets/tesla/tesla_scene_view.dart';

/// Puansız Tesla'nın Laboratuvarı: jeneratör (AC/DC), şehre elektrik
/// (transformatör ve kayıp), Tesla bobini (kablosuz lamba, rezonans).
class TeslaExploreScreen extends StatelessWidget {
  const TeslaExploreScreen({super.key});

  static const _stations = [
    LabStation(
      TeslaStation.generator,
      'Jeneratör',
      '🧲',
      'Mıknatısın yanında bobini döndür: elektrik nasıl üretiliyor?',
    ),
    LabStation(
      TeslaStation.transmission,
      'Şehre Elektrik',
      '🏙️',
      'Elektriği uzak bir şehre gönder: kaç ev yanıyor?',
    ),
    LabStation(
      TeslaStation.wireless,
      'Tesla Bobini',
      '⚡',
      'Kablosuz lambayı yak: alıcıyı vericiye ayarla.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TeslaController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStationPicker<TeslaStation>(
          key: const Key('teslaStation'),
          stations: _stations,
          selected: controller.station,
          onSelected: controller.setStation,
        ),
        const SizedBox(height: 12),
        switch (controller.station) {
          TeslaStation.generator => _GeneratorControls(controller: controller),
          TeslaStation.transmission => _CityControls(controller: controller),
          TeslaStation.wireless => _CoilControls(controller: controller),
        },
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tesla\'nın Laboratuvarı'),
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
          child: TeslaSceneView(scene: controller.scene),
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

// ─────────────────────────── Jeneratör ───────────────────────────

class _GeneratorControls extends StatelessWidget {
  const _GeneratorControls({required this.controller});

  final TeslaController controller;

  @override
  Widget build(BuildContext context) {
    final source = controller.source;
    final speed = controller.turnsPerSecond;
    final pattern = ledPattern(source, speed);
    final ac = source == PowerSource.generator;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep(
              'Hız kaydırıcısını sürükle: ampul ne kadar parlıyor?',
              done: controller.speedsTried.length >= 2,
            ),
            LabStep(
              'Kolu durdur (hız 0): ampule ne oldu?',
              done: controller.sawStopped,
            ),
            LabStep(
              "Devreye pili bağla, LED'leri karşılaştır.",
              done: controller.sourcesTried.contains(PowerSource.battery),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Devreye ne bağlayalım?'),
        _chips<PowerSource>(
          values: PowerSource.values,
          selected: source,
          label: (p) => p.label,
          onSelected: controller.setSource,
          keyOf: (p) => 'teslaSource_${p.name}',
        ),
        if (ac) ...[
          const SizedBox(height: 8),
          LabSectionTitle('Kolu çevirme hızı: saniyede ${formatTr(speed)} tur'),
          Slider(
            key: const Key('teslaSpeed'),
            value: speed,
            min: 0,
            max: maxTurnsPerSecond,
            divisions: 12,
            label: formatTr(speed),
            onChanged: controller.setSpeed,
          ),
        ],
        LabInfoCard(
          key: const Key('teslaGeneratorInfo'),
          color: ac ? Colors.amber.shade50 : Colors.blueGrey.shade50,
          icon: ac ? Icons.waves : Icons.battery_full,
          text: ac
              ? (speed == 0
                    ? 'Bobin durunca elektrik de durur: ampul ve LED\'ler söner.'
                    : 'Alternatif akım: gerilim bir artı bir eksi oluyor, LED\'ler '
                          '${pattern == LedPattern.alternating ? 'sırayla yanıp sönüyor' : 'yanmıyor (gerilim az)'}. '
                          'Ampul parlaklığı %${(bulbBrightness(source, speed) * 100).round()}. '
                          'Hızlı çevir: dalgalar sıklaşır ve yükselir.')
              : 'Doğru akım: pil hep aynı yönde ${formatTr(batteryVolts)} V verir; '
                    'yalnızca kırmızı LED yanar ve hep yanık kalır. Edison doğru '
                    'akımı savunuyordu, Tesla alternatif akımı.',
        ),
      ],
    );
  }
}

// ─────────────────────────── Şehre elektrik ───────────────────────────

class _CityControls extends StatelessWidget {
  const _CityControls({required this.controller});

  final TeslaController controller;

  @override
  Widget build(BuildContext context) {
    final lineV = lineVolts(controller.secondaryTurns);
    final d = controller.distanceKm;
    final lit = housesLit(lineV, d);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep(
              'Şehrin uzaklığını değiştir: kaç ev yanıyor?',
              done: controller.distancesTried.length >= 2,
            ),
            LabStep(
              'İkinci bobinin sarım sayısını artır.',
              done: controller.turnsTried.length >= 2,
            ),
            LabStep(
              'Şehirdeki bütün evleri yakmayı başar.',
              done: controller.sawAllLit,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Şehir ne kadar uzakta?'),
        _chips<double>(
          values: cityDistancesKm,
          selected: d,
          label: (v) => '${formatTr(v)} km',
          onSelected: controller.setDistance,
          keyOf: (v) => 'teslaDistance_${v.round()}',
        ),
        const SizedBox(height: 10),
        LabSectionTitle(
          'Yükseltici transformatör: birinci bobin $primaryTurns '
          'sarım, ikinci bobin kaç sarım?',
        ),
        _chips<int>(
          values: secondaryTurnsOptions,
          selected: controller.secondaryTurns,
          label: (t) => '$t sarım → ${formatTr(lineVolts(t), digits: 0)} V',
          onSelected: controller.setSecondaryTurns,
          keyOf: (t) => 'teslaTurns_$t',
        ),
        const SizedBox(height: 8),
        LabInfoCard(
          key: const Key('teslaCityInfo'),
          color: lit == cityHouses
              ? Colors.green.shade50
              : Colors.orange.shade50,
          icon: Icons.bolt,
          text:
              'Hat gerilimi ${formatTr(lineV, digits: 0)} V. Şehre enerjinin '
              '%${formatTr(deliveredPercent(lineV, d), digits: 0)}\'i ulaştı, '
              '$lit/$cityHouses ev yandı; gerisi tellerde ısıya dönüştü (kızaran '
              'teller). Gerilimi yükselt: aynı enerji daha küçük akımla taşınır, '
              'kayıp azalır.',
        ),
      ],
    );
  }
}

// ─────────────────────────── Tesla bobini ───────────────────────────

class _CoilControls extends StatelessWidget {
  const _CoilControls({required this.controller});

  final TeslaController controller;

  @override
  Widget build(BuildContext context) {
    final level = controller.scene.lampLevel;
    final tuned = resonance(controller.transmitterKHz, controller.receiverKHz);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep('Tesla bobinini çalıştır.', done: controller.coilStarted),
            LabStep(
              'Alıcı ayarını vericiyle aynı frekansa getir.',
              done: controller.sawTuned,
            ),
            LabStep(
              'Lambayı uzaklaştırıp yaklaştır: ışık nasıl değişiyor?',
              done: controller.lampMovedWhileOn,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('teslaCoilSwitch'),
          onPressed: () => controller.setCoil(!controller.coilOn),
          icon: controller.coilOn ? Icons.power_settings_new : Icons.bolt,
          label: controller.coilOn ? 'Bobini durdur' : 'Bobini çalıştır',
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Verici frekansı'),
        _chips<double>(
          values: transmitterFrequenciesKHz,
          selected: controller.transmitterKHz,
          label: (v) => '${formatTr(v, digits: 0)} kHz',
          onSelected: controller.setTransmitter,
          keyOf: (v) => 'teslaTx_${v.round()}',
        ),
        const SizedBox(height: 8),
        LabSectionTitle(
          'Lambanın alıcı ayarı: ${formatTr(controller.receiverKHz, digits: 0)} kHz',
        ),
        Slider(
          key: const Key('teslaReceiver'),
          value: controller.receiverKHz,
          min: receiverMinKHz,
          max: receiverMaxKHz,
          divisions: 60,
          onChanged: controller.setReceiver,
        ),
        LabSectionTitle(
          'Lambanın uzaklığı: ${formatTr(controller.lampDistanceM)} m',
        ),
        Slider(
          key: const Key('teslaLampDistance'),
          value: controller.lampDistanceM,
          min: lampMinM,
          max: lampMaxM,
          divisions: 14,
          onChanged: controller.setLampDistance,
        ),
        LabInfoCard(
          key: const Key('teslaCoilInfo'),
          color: lampLit(level) ? Colors.cyan.shade50 : Colors.blueGrey.shade50,
          icon: Icons.light,
          text: !controller.coilOn
              ? 'Bobini çalıştır: lamba hiçbir kabloya bağlı değil!'
              : 'Lamba ${lampLit(level) ? 'yanıyor' : 'sönük'} (%${(level * 100).round()}). '
                    'Ayar uyumu %${(tuned * 100).round()}: alıcıyı vericiyle aynı '
                    'frekansa getir (rezonans). Lambayı yaklaştırınca alan güçlenir.',
        ),
        LabInfoCard(
          color: Colors.red.shade50,
          icon: Icons.warning_amber,
          text:
              'Dikkat: Gerçek Tesla bobini çok yüksek gerilim üretir ve '
              'tehlikelidir. Bu deneyi yalnızca burada, oyunda yap!',
        ),
      ],
    );
  }
}
