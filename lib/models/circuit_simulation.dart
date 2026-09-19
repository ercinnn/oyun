import 'circuit_spec.dart';

/// Bir ampulün görünen durumu.
enum LampState {
  off('Yanmıyor'),
  veryDim('Çok sönük'),
  dim('Sönük'),
  normal('Normal parlak'),
  burnt('Patlamış');

  const LampState(this.label);
  final String label;

  bool get isLit =>
      this == LampState.veryDim ||
      this == LampState.dim ||
      this == LampState.normal;
}

/// Simülasyonun sonucu.
class CircuitResult {
  const CircuitResult({
    required this.closed,
    required this.brightness,
    required this.states,
    required this.current,
  });

  /// Devreden akım geçiyor mu.
  final bool closed;

  /// Ampul başına parlaklık, 0-1.
  final List<double> brightness;
  final List<LampState> states;

  /// Bataryadan çekilen toplam akım (birimsiz; ampul direnci 1).
  final double current;

  bool get anyLit => states.any((s) => s.isLit);

  /// Yanan ampullerin ortalama parlaklığı (yanmayanlar 0 sayılır).
  double get averageBrightness => brightness.isEmpty
      ? 0
      : brightness.reduce((a, b) => a + b) / brightness.length;
}

const double batteryVolts = 1.5;

/// Ampulün anma gerilimi. Bu gerilimde tam parlak yanar.
const double lampRatedVolts = 3.0;

/// Ampul bu gerilimin üstünde patlar (tek ampule 3 pil = 4,5 V gibi).
const double lampBurnVolts = 3.9;

/// Devreyi ilkokul düzeyinde sadeleştirilmiş fizikle hesaplar (saf ve
/// deterministik). Pil 1,5 V, ampul direnci 1. Seri devrede gerilim ampuller
/// arasında paylaşılır, paralelde her ampul pilin tamamını alır. Ampul
/// `min(1, (v/3)²)` parlaklıkta yanar; gerilim [lampBurnVolts]'u aşarsa patlar.
CircuitResult simulateCircuit(CircuitSpec spec) {
  final n = spec.lampCount;
  final volts = spec.batteries * batteryVolts;
  final brightness = List<double>.filled(n, 0);
  final states = List<LampState>.filled(n, LampState.off);
  if (spec.burntLamp != null) states[spec.burntLamp!] = LampState.burnt;

  CircuitResult open() => CircuitResult(
    closed: false,
    brightness: brightness,
    states: states,
    current: 0,
  );

  final material = spec.material;
  final gapOpen = material != null && !material.conductive;
  if (!spec.switchClosed || gapOpen) return open();

  LampState stateOf(double b) {
    if (b >= 0.5) return LampState.normal;
    if (b >= 0.15) return LampState.dim;
    return LampState.veryDim;
  }

  double brightnessAt(double v) => (v / lampRatedVolts) * (v / lampRatedVolts) > 1
      ? 1
      : (v / lampRatedVolts) * (v / lampRatedVolts);

  if (spec.layout == LampLayout.series) {
    // Tek yol: bir ampul patlamışsa devre kesilir.
    if (spec.burntLamp != null) return open();
    final v = volts / n;
    if (v > lampBurnVolts) {
      for (var i = 0; i < n; i++) {
        states[i] = LampState.burnt;
      }
      return open();
    }
    final b = brightnessAt(v);
    for (var i = 0; i < n; i++) {
      brightness[i] = b;
      states[i] = stateOf(b);
    }
    return CircuitResult(
      closed: true,
      brightness: brightness,
      states: states,
      current: volts / n,
    );
  }

  // Paralel: her ampulün kendi kolu vardır; patlak kol akım geçirmez.
  if (volts > lampBurnVolts) {
    for (var i = 0; i < n; i++) {
      states[i] = LampState.burnt;
    }
    return open();
  }
  final b = brightnessAt(volts);
  var working = 0;
  for (var i = 0; i < n; i++) {
    if (i == spec.burntLamp) continue;
    brightness[i] = b;
    states[i] = stateOf(b);
    working++;
  }
  return CircuitResult(
    closed: working > 0,
    brightness: brightness,
    states: states,
    current: volts * working,
  );
}

/// Devreyi ve sonucunu anlatan, elle yazılmış açıklama cümleleri.
String describeCircuit(CircuitSpec spec, CircuitResult result) {
  final parts = <String>[];
  final material = spec.material;

  if (material != null) parts.add(material.note);

  if (!spec.switchClosed) {
    parts.add('Anahtar açık olduğu için akım geçemez ve ampul yanmaz.');
    return parts.join(' ');
  }
  if (material != null && !material.conductive) {
    parts.add('Yalıtkan malzeme devreyi kesti; akım geçemediği için ampul yanmaz.');
    return parts.join(' ');
  }

  final overvoltage =
      spec.burntLamp == null &&
      result.states.every((s) => s == LampState.burnt);
  if (overvoltage) {
    parts.add(
      'Ampule fazla pil bağlanınca gerilim çok yükseldi ve ampul patladı. '
      'Her ampulün dayanabileceği bir sınır vardır.',
    );
    return parts.join(' ');
  }

  if (spec.burntLamp != null) {
    parts.add(
      spec.layout == LampLayout.series
          ? 'Seri devrede akımın tek bir yolu vardır. Bir ampul patlayınca yol kesilir ve hepsi söner.'
          : 'Paralel devrede her ampulün kendi yolu vardır. Biri patlasa da diğerleri yanmaya devam eder.',
    );
    return parts.join(' ');
  }

  if (material != null) {
    parts.add('Malzeme iletken olduğu için devre kapandı ve ampul yandı.');
  } else if (spec.lampCount == 1) {
    parts.add(
      'Devre kapalı: akım pilden çıkıp ampulden geçerek pile döner ve ampul yanar.',
    );
  }

  if (spec.lampCount > 1) {
    parts.add(
      spec.layout == LampLayout.series
          ? 'Seri devrede pilin gücü ampuller arasında paylaşılır; ampul sayısı arttıkça ampuller daha sönük yanar.'
          : 'Paralel devrede her ampul pilin tüm gücünü alır; ampul sayısı artınca ampuller sönmez ama pil daha çabuk biter.',
    );
  }
  if (spec.batteries > 1 && spec.lampCount == 1 && material == null) {
    parts.add('Pil sayısı arttıkça ampule giden güç artar ve ampul daha parlak yanar.');
  }
  return parts.join(' ');
}
