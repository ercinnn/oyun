import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/electricity_controller.dart';
import '../data/electric_materials.dart';
import '../models/circuit_simulation.dart';
import '../models/circuit_spec.dart';
import '../widgets/circuit_diagram.dart';

/// Serbest devre atölyesi: pil, anahtar, ampul dizilimi ve sayısı, boşluğa
/// malzeme ve "ampulü patlat" ile istediğin devreyi kur; şema ve ampuller
/// canlı güncellenir. Puan yok; amaç merak edip denemek.
class ElectricityFreeCircuitScreen extends StatelessWidget {
  const ElectricityFreeCircuitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ElectricityController>();
    final spec = controller.freeSpec;
    final result = simulateCircuit(spec);
    final textTheme = Theme.of(context).textTheme;

    void update(CircuitSpec next) => controller.setFreeSpec(next);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serbest Devre Atölyesi'),
        // Geri oku oyundan çıkmak yerine kurulum ekranına döner.
        leading: BackButton(onPressed: controller.restart),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        CircuitDiagram(spec: spec, result: result),
                        LampStateList(result: result),
                        const SizedBox(height: 8),
                        BatteryDrainBar(result: result),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  describeCircuit(spec, result),
                  key: const Key('freeCircuitExplanation'),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text('Pil sayısı', style: textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var n = 1; n <= maxBatteries; n++)
                      ChoiceChip(
                        key: Key('freeBatteries_$n'),
                        label: Text('$n pil (${(n * batteryVolts).toStringAsFixed(1).replaceAll('.', ',')} V)'),
                        selected: spec.batteries == n,
                        onSelected: (_) => update(spec.copyWith(batteries: n)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Ampul sayısı', style: textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var n = 1; n <= maxLamps; n++)
                      ChoiceChip(
                        key: Key('freeLamps_$n'),
                        label: Text('$n ampul'),
                        selected: spec.lampCount == n,
                        onSelected: (_) => update(spec.copyWith(lampCount: n)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Ampullerin bağlanışı', style: textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final layout in LampLayout.values)
                      ChoiceChip(
                        key: Key('freeLayout_${layout.name}'),
                        label: Text(layout.label),
                        selected: spec.layout == layout,
                        onSelected: (_) => update(spec.copyWith(layout: layout)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  key: const Key('freeSwitch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Anahtar kapalı (akım geçer)'),
                  value: spec.switchClosed,
                  onChanged: (value) => update(spec.copyWith(switchClosed: value)),
                ),
                SwitchListTile(
                  key: const Key('freeBurnt'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('İlk ampulü patlat'),
                  value: spec.burntLamp != null,
                  onChanged: (value) => update(
                    value ? spec.copyWith(burntLamp: 0) : spec.copyWith(clearBurnt: true),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Boşluğa takılan malzeme', style: textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      key: const Key('freeMaterial_none'),
                      label: const Text('Düz tel'),
                      selected: spec.material == null,
                      onSelected: (_) => update(spec.copyWith(clearMaterial: true)),
                    ),
                    for (final material in electricMaterials)
                      ChoiceChip(
                        key: Key('freeMaterial_${material.id}'),
                        label: Text('${material.emoji} ${material.name}'),
                        selected: spec.material?.id == material.id,
                        onSelected: (_) => update(spec.copyWith(material: material)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
