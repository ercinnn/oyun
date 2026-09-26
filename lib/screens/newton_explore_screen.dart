import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/newton_controller.dart';
import '../data/newton_objects.dart';
import '../models/newton/cart.dart';
import '../models/newton/falling.dart';
import '../models/newton/newton_scene.dart';
import '../models/newton/prism.dart';
import '../models/science/science_task.dart' show formatTr;
import '../widgets/newton/newton_scene_view.dart';
import '../widgets/science_lab/lab_guide.dart';
import '../widgets/science_lab/lab_split_layout.dart';
import '../widgets/science_lab/scientist_sound_toggle.dart';

/// Puansız Keşif Laboratuvarı: düşme kulesi, prizma ve itme pisti. Her
/// istasyonda iki şey yan yana denenir (A/B) ki çocuk tek bir farkı
/// değiştirip sonucu karşılaştırabilsin (adil deney).
class NewtonExploreScreen extends StatelessWidget {
  const NewtonExploreScreen({super.key});

  static const _stations = [
    LabStation(
      NewtonStation.fall,
      'Düşme Kulesi',
      '🍎',
      'İki cismi aynı anda bırak: hangisi önce yere değiyor?',
    ),
    LabStation(
      NewtonStation.prism,
      'Prizma',
      '🌈',
      'Işığı camdan geçir: beyaz ışığın içinde ne saklı?',
    ),
    LabStation(
      NewtonStation.cart,
      'İtme Pisti',
      '🚗',
      'İki arabayı aynı yayla it: hangisi daha uzağa gidiyor?',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NewtonController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStationPicker<NewtonStation>(
          key: const Key('newtonStation'),
          stations: _stations,
          selected: controller.station,
          onSelected: controller.setStation,
        ),
        const SizedBox(height: 12),
        switch (controller.station) {
          NewtonStation.fall => _FallControls(controller: controller),
          NewtonStation.prism => _PrismControls(controller: controller),
          NewtonStation.cart => _CartControls(controller: controller),
        },
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşif Laboratuvarı'),
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
          child: NewtonSceneView(scene: controller.scene),
        ),
        panel: controls,
      ),
    );
  }
}

// ─────────────────────────── Düşme ───────────────────────────

class _FallControls extends StatelessWidget {
  const _FallControls({required this.controller});

  final NewtonController controller;

  Widget _objectPicker(
    String label,
    FallingObject selected,
    ValueChanged<FallingObject> onPick,
    String keyPrefix,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabSectionTitle(label),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final o in newtonFallingObjects)
              ChoiceChip(
                key: Key('${keyPrefix}_${o.id}'),
                label: Text(
                  '${o.emoji} ${o.name}',
                  style: const TextStyle(fontSize: 15),
                ),
                selected: o.id == selected.id,
                onSelected: (_) => onPick(o),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final env = controller.environment;
    final a = controller.fallA;
    final b = controller.fallB;
    final winner = fallWinner(a, b, env);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep(
              'İki cisim seç ve "Aynı anda bırak!"a bas.',
              done: controller.droppedIn.isNotEmpty,
            ),
            LabStep(
              'Düz kâğıtla buruşuk kâğıdı yarıştır.',
              done: controller.droppedPairs.contains('paper_ball+paper_flat'),
            ),
            LabStep(
              "Aynı deneyi Ay'da ya da havasız tüpte tekrarla.",
              done: controller.droppedIn.any((e) => !e.hasAir),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('newtonDrop'),
          onPressed: controller.dropObjects,
          icon: Icons.arrow_downward,
          label: controller.fallDone ? 'Yeniden bırak' : 'Aynı anda bırak!',
        ),
        if (controller.fallDone) ...[
          const SizedBox(height: 8),
          LabInfoCard(
            key: const Key('newtonFallResult'),
            color: Colors.lightBlue.shade50,
            icon: Icons.timer,
            title: switch (winner) {
              0 => 'A önce yere değdi.',
              1 => 'B önce yere değdi.',
              _ => 'İkisi aynı anda yere değdi!',
            },
            text:
                '${a.emoji} A: ${formatTr(fallTime(a, env))} sn, '
                '${b.emoji} B: ${formatTr(fallTime(b, env))} sn. '
                '${env.hasAir ? 'Havada hafif ve geniş cisimleri hava tutar.' : 'Hava yokken her şey aynı hızla düşer.'}',
          ),
        ],
        const SizedBox(height: 10),
        const LabSectionTitle('Deney nerede?'),
        Wrap(
          spacing: 6,
          children: [
            for (final e in FallEnvironment.values)
              ChoiceChip(
                key: Key('newtonEnv_${e.name}'),
                label: Text(e.label, style: const TextStyle(fontSize: 15)),
                selected: e == env,
                onSelected: (_) => controller.setEnvironment(e),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _objectPicker('A (soldaki kanca)', a, controller.setFallA, 'newtonA'),
        const SizedBox(height: 8),
        _objectPicker('B (sağdaki kanca)', b, controller.setFallB, 'newtonB'),
        if (!controller.fallDone)
          const LabInfoCard(
            text:
                'İpucu: Önce düz kâğıtla buruşuk kâğıdı dene. Sonra tüyle '
                'çekici Ay\'da bırak!',
          ),
      ],
    );
  }
}

// ─────────────────────────── Prizma ───────────────────────────

class _PrismControls extends StatelessWidget {
  const _PrismControls({required this.controller});

  final NewtonController controller;

  @override
  Widget build(BuildContext context) {
    final outcome = prismOutcome(
      controller.light,
      secondPrism: controller.secondPrism,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep(
              'Feneri yak ve perdeye bak.',
              done: controller.litWith.isNotEmpty,
            ),
            LabStep(
              'Fenerin önüne renkli bir süzgeç koy.',
              done: controller.litWith.any((l) => l != LightSource.white),
            ),
            LabStep(
              'İkinci prizmayı ters çevirip koy.',
              done: controller.sawRecombine,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('newtonLamp'),
          onPressed: () => controller.setLamp(!controller.lampOn),
          icon: controller.lampOn ? Icons.lightbulb : Icons.lightbulb_outline,
          label: controller.lampOn ? 'Feneri kapat' : 'Feneri yak',
        ),
        const SizedBox(height: 10),
        const LabSectionTitle('Fenerin önüne ne koyalım?'),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final l in LightSource.values)
              ChoiceChip(
                key: Key('newtonLight_${l.name}'),
                label: Text(l.label, style: const TextStyle(fontSize: 15)),
                selected: l == controller.light,
                onSelected: (_) => controller.setLight(l),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('newtonSecondPrism'),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Ters prizma ekle',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          value: controller.secondPrism,
          onChanged: controller.setSecondPrism,
        ),
        const SizedBox(height: 4),
        if (controller.lampOn)
          LabInfoCard(
            key: const Key('newtonPrismResult'),
            color: Colors.amber.shade50,
            icon: Icons.wb_sunny_outlined,
            text: outcome.isRainbow
                ? 'Perdede ${outcome.colors.length} renk var: '
                      '${outcome.colors.map((c) => c.name).join(', ')}. Beyaz ışık '
                      'renklerin karışımıymış! Mor en çok, kırmızı en az bükülür.'
                : outcome.isWhite
                ? 'Ters prizma renkleri yeniden birleştirdi: perdede beyaz ışık '
                      'var. Renkler birleşince beyaz olur.'
                : 'Perdede yalnızca ${outcome.colors.single.name.toLowerCase()} '
                      'var. Prizma renk üretmez, beyaz ışığın içindeki renkleri '
                      'ayırır; tek renk tek kalır.',
          )
        else
          const LabInfoCard(
            text:
                'Feneri yak ve perdeye bak. Sonra süzgeçleri ve ikinci '
                'prizmayı dene.',
          ),
      ],
    );
  }
}

// ─────────────────────────── Araba ───────────────────────────

class _CartControls extends StatelessWidget {
  const _CartControls({required this.controller});

  final NewtonController controller;

  Widget _lane(
    BuildContext context,
    String label,
    CartLane lane,
    ValueChanged<CartLane> onChanged,
    String keyPrefix,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                for (final s in CartSurface.values)
                  ChoiceChip(
                    key: Key('${keyPrefix}Surface_${s.name}'),
                    label: Text(s.label),
                    selected: s == lane.surface,
                    onSelected: (_) => onChanged(lane.copyWith(surface: s)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Row(
              children: [
                const Flexible(
                  child: Text('Kutu:', style: TextStyle(fontSize: 15)),
                ),
                IconButton(
                  key: Key('${keyPrefix}BoxMinus'),
                  onPressed: lane.boxes == 0
                      ? null
                      : () => onChanged(lane.copyWith(boxes: lane.boxes - 1)),
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '${lane.boxes}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  key: Key('${keyPrefix}BoxPlus'),
                  onPressed: lane.boxes >= maxBoxes
                      ? null
                      : () => onChanged(lane.copyWith(boxes: lane.boxes + 1)),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = controller.laneA;
    final b = controller.laneB;
    final push = controller.push;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabStepList(
          steps: [
            LabStep(
              '"İt!"e bas: iki araba nereye kadar gidiyor?',
              done: controller.pushes > 0,
            ),
            LabStep(
              'Aynı zeminde yalnızca birine kutu ekle, yeniden it.',
              done: controller.pushedLoadCompare,
            ),
            LabStep(
              'Bir pistin zeminini buz yap ve yeniden it.',
              done: controller.pushedOnIce,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LabActionButton(
          key: const Key('newtonPush'),
          onPressed: controller.pushCarts,
          icon: Icons.double_arrow,
          label: 'İt!',
        ),
        if (controller.cartDone) ...[
          const SizedBox(height: 8),
          LabInfoCard(
            key: const Key('newtonCartResult'),
            color: Colors.lightBlue.shade50,
            icon: Icons.straighten,
            title:
                'A ${formatTr(cartDistance(a, push))} m, '
                'B ${formatTr(cartDistance(b, push))} m gitti.',
            text:
                'Aynı itme, ağır arabayı daha az hızlandırır; sürtünme az '
                'olan zeminde araba daha uzağa gider.'
                '${cartStopDistance(a, push) > trackLengthM || cartStopDistance(b, push) > trackLengthM ? ' Buzdaki araba pistin sonundaki tampona kadar gitti: hiçbir şey durdurmasa sonsuza kadar giderdi!' : ''}',
          ),
        ],
        const SizedBox(height: 8),
        _lane(
          context,
          'A (arkadaki pist)',
          a,
          controller.setLaneA,
          'newtonLaneA',
        ),
        _lane(
          context,
          'B (öndeki pist)',
          b,
          controller.setLaneB,
          'newtonLaneB',
        ),
        const SizedBox(height: 4),
        const LabSectionTitle('Yayın gücü (ikisine de aynı)'),
        SegmentedButton<PushStrength>(
          segments: [
            for (final p in PushStrength.values)
              ButtonSegment(value: p, label: Text(p.label)),
          ],
          selected: {push},
          showSelectedIcon: false,
          onSelectionChanged: (v) => controller.setPush(v.first),
        ),
        const SizedBox(height: 10),
        if (!controller.cartDone)
          const LabInfoCard(
            text:
                'İpucu: İki arabayı aynı zeminde bırak, yalnızca birine kutu '
                'ekle. Sonra kutuları eşitle ve zemini değiştir.',
          ),
      ],
    );
  }
}
