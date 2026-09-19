import 'dart:math';

import '../data/electric_materials.dart';
import '../data/safety_scenes.dart';
import 'circuit_simulation.dart';
import 'circuit_spec.dart';
import 'electric_task.dart';
import 'energy_city.dart';
import 'wire_puzzle.dart';

/// İki devrenin ortalama parlaklığı en az bu kadar farklı olmalı: tahmin gözle
/// ayırt edilebilsin (Bitki Laboratuvarı'ndaki boy farkı eşiğinin karşılığı).
const double minBrightnessGap = 0.15;

/// [kind] türünde rastgele bir görev üretir.
ElectricTask generateElectricTask(ElectricTaskKind kind, Random rng) =>
    switch (kind) {
      ElectricTaskKind.circuit => _circuitTask(rng),
      ElectricTaskKind.conductor => _conductorTask(rng),
      ElectricTaskKind.wire => WireTask(WirePuzzle.generate(3 + rng.nextInt(2), rng)),
      ElectricTaskKind.city => _cityTask(rng),
      ElectricTaskKind.safety => _safetyTask(rng),
    };

// ───────────────────────────── Devre tahmini ─────────────────────────────

ElectricTask _circuitTask(Random rng) {
  switch (rng.nextInt(4)) {
    case 0:
      return _lightsUpTask(rng);
    case 1:
      return _compareTask(rng);
    case 2:
      return _burntLampTask(rng);
    default:
      return _overvoltageTask(rng);
  }
}

/// "Bu devrede ampul yanar mı?" (anahtar açık/kapalı).
ChoiceTask _lightsUpTask(Random rng) {
  final spec = CircuitSpec(
    batteries: 2,
    switchClosed: rng.nextBool(),
    layout: rng.nextBool() ? LampLayout.series : LampLayout.parallel,
    lampCount: 1 + rng.nextInt(2),
  );
  final result = simulateCircuit(spec);
  return ChoiceTask(
    kind: ElectricTaskKind.circuit,
    prompt: 'Bu devrede ampul yanar mı? Anahtarın durumuna dikkat et.',
    options: const ['Yanar', 'Yanmaz'],
    correctIndex: result.anyLit ? 0 : 1,
    explanation: describeCircuit(spec, result),
    circuits: [LabeledCircuit('Devre', spec)],
  );
}

/// İki devreyi karşılaştır: yalnızca tek şey farklı (adil deney).
ChoiceTask _compareTask(Random rng) {
  final factor = rng.nextInt(3);
  for (var attempt = 0; attempt < 60; attempt++) {
    final a = 1 + rng.nextInt(3);
    final b = 1 + rng.nextInt(3);
    if (a == b && factor != 2) continue;
    late final CircuitSpec specA;
    late final CircuitSpec specB;
    late final String differing;
    switch (factor) {
      case 0:
        specA = CircuitSpec(batteries: a, lampCount: 2);
        specB = CircuitSpec(batteries: b, lampCount: 2);
        differing = 'pil sayısı';
      case 1:
        specA = CircuitSpec(batteries: 2, lampCount: a);
        specB = CircuitSpec(batteries: 2, lampCount: b);
        differing = 'ampul sayısı';
      default:
        specA = const CircuitSpec(batteries: 2, lampCount: 2, layout: LampLayout.series);
        specB = const CircuitSpec(batteries: 2, lampCount: 2, layout: LampLayout.parallel);
        differing = 'ampullerin bağlanışı';
        if (rng.nextBool()) {
          return _compareResult(specB, specA, differing);
        }
    }
    final task = _compareResult(specA, specB, differing);
    final gap =
        (simulateCircuit(specA).averageBrightness -
                simulateCircuit(specB).averageBrightness)
            .abs();
    if (gap >= minBrightnessGap) return task;
  }
  // Yedek: 1 pil ile 3 pil (seri, iki ampul) — fark her zaman büyük.
  return _compareResult(
    const CircuitSpec(batteries: 1, lampCount: 2),
    const CircuitSpec(batteries: 3, lampCount: 2),
    'pil sayısı',
  );
}

ChoiceTask _compareResult(CircuitSpec a, CircuitSpec b, String differing) {
  final brightA = simulateCircuit(a).averageBrightness;
  final brightB = simulateCircuit(b).averageBrightness;
  final int correct;
  if ((brightA - brightB).abs() < 0.02) {
    correct = 2;
  } else {
    correct = brightA > brightB ? 0 : 1;
  }
  final resultA = simulateCircuit(a);
  final resultB = simulateCircuit(b);
  return ChoiceTask(
    kind: ElectricTaskKind.circuit,
    prompt:
        'İki devrede yalnızca $differing farklı. Hangisinde ampuller daha parlak yanar?',
    options: const ['A daha parlak', 'B daha parlak', 'İkisi aynı'],
    correctIndex: correct,
    explanation:
        'A: ${_lampSummary(resultA)}. B: ${_lampSummary(resultB)}. '
        '${describeCircuit(brightA >= brightB ? a : b, brightA >= brightB ? resultA : resultB)}',
    circuits: [LabeledCircuit('A', a), LabeledCircuit('B', b)],
  );
}

String _lampSummary(CircuitResult result) => result.states.first.label;

/// "Bir ampul patladı, diğerleri yanar mı?" (seri/paralel farkı).
ChoiceTask _burntLampTask(Random rng) {
  final layout = rng.nextBool() ? LampLayout.series : LampLayout.parallel;
  final spec = CircuitSpec(
    batteries: 2,
    layout: layout,
    lampCount: 2 + rng.nextInt(2),
    burntLamp: 0,
  );
  final result = simulateCircuit(spec);
  final othersLit = result.states
      .asMap()
      .entries
      .any((e) => e.key != 0 && e.value.isLit);
  return ChoiceTask(
    kind: ElectricTaskKind.circuit,
    prompt:
        'Ampullerden biri patladı (üzerinde çarpı var). Diğer ampuller ne olur?',
    options: const ['Hepsi söner', 'Diğerleri yanmaya devam eder'],
    correctIndex: othersLit ? 1 : 0,
    explanation: describeCircuit(spec, result),
    subject: '${layout.label} devre',
    circuits: [LabeledCircuit('Devre', spec)],
  );
}

/// Fazla pil ampulü patlatır.
ChoiceTask _overvoltageTask(Random rng) {
  final spec = rng.nextBool()
      ? const CircuitSpec(batteries: 3, lampCount: 1)
      : const CircuitSpec(batteries: 3, lampCount: 2, layout: LampLayout.parallel);
  final result = simulateCircuit(spec);
  final int correct;
  if (result.states.every((s) => s == LampState.burnt)) {
    correct = 1;
  } else if (result.anyLit) {
    correct = 0;
  } else {
    correct = 2;
  }
  return ChoiceTask(
    kind: ElectricTaskKind.circuit,
    prompt: 'Bu devreyi çalıştırırsak ampullere ne olur?',
    options: const ['Normal yanarlar', 'Patlarlar', 'Yanmazlar'],
    correctIndex: correct,
    explanation: describeCircuit(spec, result),
    circuits: [LabeledCircuit('Devre', spec)],
  );
}

// ───────────────────────────── İletken / yalıtkan ─────────────────────────────

ChoiceTask _conductorTask(Random rng) {
  final material = electricMaterials[rng.nextInt(electricMaterials.length)];
  final spec = CircuitSpec(batteries: 2, material: material);
  final result = simulateCircuit(spec);
  return ChoiceTask(
    kind: ElectricTaskKind.conductor,
    prompt: 'Devrenin boşluğuna bu malzemeyi takıyoruz. Ampul yanar mı?',
    subject: '${material.emoji} ${material.name}',
    options: const ['Yanar', 'Yanmaz'],
    correctIndex: material.conductive ? 0 : 1,
    explanation: describeCircuit(spec, result),
    circuits: [LabeledCircuit('Devre', spec)],
  );
}

// ───────────────────────────── Enerji şehri ─────────────────────────────

ChoiceTask _cityTask(Random rng) =>
    rng.nextBool() ? _topSourceTask(rng) : _cleanMixTask(rng);

/// "Bu havada hangi kaynak en çok elektrik üretir?"
ChoiceTask _topSourceTask(Random rng) {
  final weather = EnergyWeather.values[rng.nextInt(EnergyWeather.values.length)];
  List<EnergySource> options = const [];
  for (var attempt = 0; attempt < 50; attempt++) {
    final candidate = ([...EnergySource.values]..shuffle(rng)).take(3).toList();
    final outputs = candidate.map((s) => energyOutput(s, weather)).toList();
    final top = outputs.reduce(max);
    if (outputs.where((o) => o == top).length == 1) {
      options = candidate;
      break;
    }
  }
  if (options.isEmpty) {
    options = const [EnergySource.solar, EnergySource.wind, EnergySource.hydro];
  }
  final outputs = options.map((s) => energyOutput(s, weather)).toList();
  final topIndex = outputs.indexOf(outputs.reduce(max));
  final top = options[topIndex];
  return ChoiceTask(
    kind: ElectricTaskKind.city,
    prompt: 'Hangi kaynak en çok elektrik üretir?',
    subject: '${weather.emoji} ${weather.label}',
    options: [for (final s in options) '${s.emoji} ${s.name}'],
    correctIndex: topIndex,
    explanation:
        '${weather.label}: '
        '${[for (var i = 0; i < options.length; i++) '${options[i].name} ${outputs[i]} birim'].join(', ')}. '
        'En çok üreten: ${top.name}. ${top.note}',
  );
}

/// "Şehrin ihtiyacını hangi karışım temiz biçimde karşılar?"
ChoiceTask _cleanMixTask(Random rng) {
  final weather = EnergyWeather.values[rng.nextInt(EnergyWeather.values.length)];
  const demands = [60, 80, 100, 120, 140];

  // Tüm ikili karışımlar.
  final mixes = <List<EnergySource>>[];
  for (var i = 0; i < EnergySource.values.length; i++) {
    for (var j = i + 1; j < EnergySource.values.length; j++) {
      mixes.add([EnergySource.values[i], EnergySource.values[j]]);
    }
  }
  int total(List<EnergySource> mix) =>
      mix.fold(0, (sum, s) => sum + energyOutput(s, weather));
  bool clean(List<EnergySource> mix) => mix.every((s) => s.clean);

  final orderedDemands = [...demands]..shuffle(rng);
  for (final demand in orderedDemands) {
    final correct = [
      for (final m in mixes)
        if (clean(m) && total(m) >= demand) m,
    ];
    final wrong = [
      for (final m in mixes)
        if (!(clean(m) && total(m) >= demand)) m,
    ];
    if (correct.isEmpty || wrong.length < 2) continue;

    final right = correct[rng.nextInt(correct.length)];
    final chosenWrong = ([...wrong]..shuffle(rng)).take(2).toList();
    final options = [right, ...chosenWrong]..shuffle(rng);
    final correctIndex = options.indexOf(right);

    String describe(List<EnergySource> mix) =>
        '${mix.map((s) => s.name).join(' + ')}: ${total(mix)} birim'
        '${clean(mix) ? '' : ' (havayı kirletir)'}';

    return ChoiceTask(
      kind: ElectricTaskKind.city,
      prompt:
          'Şehrin ihtiyacı $demand birim. Hangi karışım ihtiyacı karşılar ve havayı kirletmez?',
      subject:
          '${weather.emoji} ${weather.label}. Üretimler: '
          '${[for (final s in EnergySource.values) '${s.name} ${energyOutput(s, weather)}'].join(', ')}',
      options: [for (final m in options) m.map((s) => '${s.emoji} ${s.name}').join(' + ')],
      correctIndex: correctIndex,
      explanation:
          '${[for (final m in options) describe(m)].join('. ')}. '
          'Doğru karışım hem $demand birimi karşılıyor hem de temiz kaynaklardan oluşuyor.',
    );
  }
  // Yedek (her hava için bir talep bulunur; buraya gelinmemesi beklenir).
  return _topSourceTask(rng);
}

// ───────────────────────────── Güvenlik ─────────────────────────────

ChoiceTask _safetyTask(Random rng) =>
    rng.nextBool() ? _sceneTask(rng) : _wattsTask(rng);

ChoiceTask _sceneTask(Random rng) {
  final scene = safetyScenes[rng.nextInt(safetyScenes.length)];
  return ChoiceTask(
    kind: ElectricTaskKind.safety,
    prompt: 'Bu davranış güvenli mi?',
    subject: '${scene.emoji} ${scene.text}',
    options: const ['Güvenli', 'Tehlikeli'],
    correctIndex: scene.safe ? 0 : 1,
    explanation: scene.explanation,
  );
}

ChoiceTask _wattsTask(Random rng) {
  for (var attempt = 0; attempt < 60; attempt++) {
    final a = appliances[rng.nextInt(appliances.length)];
    final b = appliances[rng.nextInt(appliances.length)];
    if (a == b) continue;
    final high = max(a.watts, b.watts);
    final low = min(a.watts, b.watts);
    if (high < low * 1.5) continue;
    return ChoiceTask(
      kind: ElectricTaskKind.safety,
      prompt: 'Hangi cihaz çalışırken daha çok elektrik harcar?',
      options: ['${a.emoji} ${a.name}', '${b.emoji} ${b.name}'],
      correctIndex: a.watts > b.watts ? 0 : 1,
      explanation:
          '${a.name}: ${a.watts} watt. ${b.name}: ${b.watts} watt. '
          'Watt sayısı büyük olan cihaz daha çok elektrik harcar; '
          'kullanmadığın cihazları kapatmak tasarruf sağlar.',
    );
  }
  return _sceneTask(rng);
}
