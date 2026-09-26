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
import '../widgets/science_lab/lab_split_layout.dart';

/// Puansız Keşif Laboratuvarı: düşme kulesi, prizma ve itme pisti. Her
/// istasyonda iki şey yan yana denenir (A/B) ki çocuk tek bir farkı
/// değiştirip sonucu karşılaştırabilsin (adil deney).
class NewtonExploreScreen extends StatelessWidget {
  const NewtonExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NewtonController>();
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<NewtonStation>(
          key: const Key('newtonStation'),
          segments: [
            for (final s in NewtonStation.values)
              ButtonSegment(value: s, label: Text(s.label)),
          ],
          selected: {controller.station},
          showSelectedIcon: false,
          onSelectionChanged: (v) => controller.setStation(v.first),
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
        Text(label),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final o in newtonFallingObjects)
              ChoiceChip(
                key: Key('${keyPrefix}_${o.id}'),
                label: Text('${o.emoji} ${o.name}'),
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
        const Text('Deney nerede?'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: [
            for (final e in FallEnvironment.values)
              ChoiceChip(
                key: Key('newtonEnv_${e.name}'),
                label: Text(e.label),
                selected: e == env,
                onSelected: (_) => controller.setEnvironment(e),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _objectPicker('A (soldaki kanca):', a, controller.setFallA, 'newtonA'),
        const SizedBox(height: 8),
        _objectPicker('B (sağdaki kanca):', b, controller.setFallB, 'newtonB'),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('newtonDrop'),
          onPressed: controller.dropObjects,
          icon: const Icon(Icons.arrow_downward),
          label: Text(controller.fallDone ? 'Yeniden bırak' : 'Aynı anda bırak!'),
        ),
        if (controller.fallDone) ...[
          const SizedBox(height: 8),
          LabInfoCard(
            key: const Key('newtonFallResult'),
            color: Colors.lightBlue.shade50,
            text: '${a.emoji} A: ${formatTr(fallTime(a, env))} sn, '
                '${b.emoji} B: ${formatTr(fallTime(b, env))} sn. '
                '${switch (winner) {
                  0 => 'A önce yere değdi.',
                  1 => 'B önce yere değdi.',
                  _ => 'İkisi aynı anda yere değdi!',
                }} '
                '${env.hasAir ? 'Havada hafif ve geniş cisimleri hava tutar.' : 'Hava yokken her şey aynı hızla düşer.'}',
          ),
        ] else
          const LabInfoCard(
            text: 'İpucu: Önce düz kâğıtla buruşuk kâğıdı dene. Sonra tüyle '
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
        const Text('Fenerin önüne ne koyalım?'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final l in LightSource.values)
              ChoiceChip(
                key: Key('newtonLight_${l.name}'),
                label: Text(l.label),
                selected: l == controller.light,
                onSelected: (_) => controller.setLight(l),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('newtonSecondPrism'),
          contentPadding: EdgeInsets.zero,
          title: const Text('İkinci prizmayı ters çevirip koy'),
          value: controller.secondPrism,
          onChanged: controller.setSecondPrism,
        ),
        FilledButton.icon(
          key: const Key('newtonLamp'),
          onPressed: () => controller.setLamp(!controller.lampOn),
          icon: Icon(controller.lampOn ? Icons.lightbulb : Icons.lightbulb_outline),
          label: Text(controller.lampOn ? 'Feneri kapat' : 'Feneri yak'),
        ),
        const SizedBox(height: 8),
        if (controller.lampOn)
          LabInfoCard(
            key: const Key('newtonPrismResult'),
            color: Colors.amber.shade50,
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
            text: 'Feneri yak ve perdeye bak. Sonra süzgeçleri ve ikinci '
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
            Text(label, style: Theme.of(context).textTheme.titleSmall),
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
                const Flexible(child: Text('Kutu:')),
                IconButton(
                  key: Key('${keyPrefix}BoxMinus'),
                  onPressed: lane.boxes == 0
                      ? null
                      : () => onChanged(lane.copyWith(boxes: lane.boxes - 1)),
                  icon: const Icon(Icons.remove),
                ),
                Text('${lane.boxes}'),
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
        _lane(context, 'A (arkadaki pist)', a, controller.setLaneA, 'newtonLaneA'),
        _lane(context, 'B (öndeki pist)', b, controller.setLaneB, 'newtonLaneB'),
        const SizedBox(height: 4),
        const Text('Yayın gücü (ikisine de aynı):'),
        const SizedBox(height: 4),
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
        FilledButton.icon(
          key: const Key('newtonPush'),
          onPressed: controller.pushCarts,
          icon: const Icon(Icons.double_arrow),
          label: const Text('İt!'),
        ),
        const SizedBox(height: 8),
        if (controller.cartDone)
          LabInfoCard(
            key: const Key('newtonCartResult'),
            color: Colors.lightBlue.shade50,
            text: 'A ${formatTr(cartDistance(a, push))} m, '
                'B ${formatTr(cartDistance(b, push))} m gitti. Aynı itme, ağır '
                'arabayı daha az hızlandırır; sürtünme az olan zeminde araba '
                'daha uzağa gider.'
                '${cartStopDistance(a, push) > trackLengthM || cartStopDistance(b, push) > trackLengthM ? ' Buzdaki araba pistin sonundaki tampona kadar gitti: hiçbir şey durdurmasa sonsuza kadar giderdi!' : ''}',
          )
        else
          const LabInfoCard(
            text: 'İpucu: İki arabayı aynı zeminde bırak, yalnızca birine kutu '
                'ekle. Sonra kutuları eşitle ve zemini değiştir.',
          ),
      ],
    );
  }
}
