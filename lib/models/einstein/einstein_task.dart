import '../science/science_task.dart';
import 'einstein_scene.dart';
import 'mass_energy.dart';
import 'spacetime.dart';
import 'time_dilation.dart';

enum EinsteinTaskKind { sheet, clock, energy }

/// Einstein görevleri: ortak [ScienceTask]'a ek olarak deneyin sorudan önceki
/// ve cevaptan sonraki sahnesini verir.
sealed class EinsteinTask extends ScienceTask {
  const EinsteinTask();

  EinsteinTaskKind get kind;
  EinsteinScene get questionScene;
  EinsteinScene resultScene(int answerIndex);
}

// ─────────────────────────── Uzay-zaman ───────────────────────────

/// Bilye ne yapar?
class FateTask extends EinsteinTask {
  const FateTask(this.center, this.speed);

  final CentralMass center;
  final LaunchSpeed speed;

  @override
  EinsteinTaskKind get kind => EinsteinTaskKind.sheet;

  @override
  String get title => 'Bilye nereye gider?';

  @override
  String get prompt =>
      'Örtünün ortasında ${center.label} var ve örtüyü çukurlaştırıyor. '
      'Kenardan bir bilyeyi ${speed.label.toLowerCase()} fırlatıyoruz. Bilye ne yapar?';

  @override
  List<String> get options => [for (final f in MarbleFate.values) f.label];

  @override
  int get correctIndex => simulateMarble(center, speed).fate.index;

  @override
  String explanation(int answerIndex) {
    final fate = simulateMarble(center, speed).fate;
    final why = switch (fate) {
      MarbleFate.fallsIn =>
        'Bilye çukurun kenarında tutunacak kadar hızlı değildi, içine yuvarlandı.',
      MarbleFate.orbits =>
        'Bilyenin hızı çukura düşmemeye yetti ama kaçmaya yetmedi: çukurun '
            'etrafında dönüyor. Ay\'ın Dünya\'nın, Dünya\'nın Güneş\'in etrafında '
            'dönmesi de böyledir.',
      MarbleFate.escapes =>
        'Bilye çok hızlıydı: çukur onu biraz büktü ama tutamadı.',
    };
    return '$why Einstein\'a göre kütleçekim, kütlenin uzay-zamanı bükmesidir; '
        'ağır kütle daha derin bir çukur açar.';
  }

  @override
  EinsteinScene get questionScene =>
      EinsteinScene(station: EinsteinStation.sheet, center: center, speed: speed);

  @override
  EinsteinScene resultScene(int answerIndex) => EinsteinScene(
    station: EinsteinStation.sheet,
    center: center,
    speed: speed,
    run: 1,
  );
}

/// Aynı hızla: hangisinin çevresinde bilye yörüngede döner?
class OrbitWhichTask extends EinsteinTask {
  const OrbitWhichTask(this.speed);

  final LaunchSpeed speed;

  @override
  EinsteinTaskKind get kind => EinsteinTaskKind.sheet;

  @override
  String get title => 'Hangi çukur?';

  @override
  String get prompt =>
      'Bilyeyi hep aynı hızla (${speed.label.toLowerCase()}) fırlatıyoruz. Örtünün '
      'ortasına hangisini koyarsak bilye düşmeden etrafında döner?';

  @override
  List<String> get options => [for (final c in CentralMass.values) c.label];

  @override
  int get correctIndex => CentralMass.values
      .indexWhere((c) => simulateMarble(c, speed).fate == MarbleFate.orbits);

  @override
  String explanation(int answerIndex) {
    final list = [
      for (final c in CentralMass.values)
        '${c.label}: ${simulateMarble(c, speed).fate.label.toLowerCase()}',
    ].join(', ');
    return '$list. Ağır kütle örtüyü daha çok çukurlaştırır; aynı hızdaki '
        'bilyeyi yakalar. Hafif kütlenin sığ çukurunda bilye dönmeye devam eder.';
  }

  EinsteinScene _scene(CentralMass c, int run) => EinsteinScene(
    station: EinsteinStation.sheet,
    center: c,
    speed: speed,
    run: run,
  );

  @override
  EinsteinScene get questionScene => _scene(CentralMass.sun, 0);

  @override
  EinsteinScene resultScene(int answerIndex) =>
      _scene(CentralMass.values[answerIndex], 1);
}

// ─────────────────────────── Işık saati ───────────────────────────

/// Gemideki astronot kaç yıl yaşlanır?
class ShipAgeTask extends EinsteinTask {
  ShipAgeTask(this.speed, this.choices);

  final double speed;
  final List<double> choices;

  static const earthYears = 10.0;

  @override
  EinsteinTaskKind get kind => EinsteinTaskKind.clock;

  @override
  String get title => 'İkizler';

  @override
  String get prompt =>
      'Ayşe ile Ali ikiz. Ayşe ışık hızının ${percentOfC(speed)}\'iyle giden bir '
      'gemiyle yolculuğa çıkıyor, Ali Dünya\'da kalıyor. Dünya\'da '
      '${formatTr(earthYears)} yıl geçtiğinde Ayşe kaç yaş büyümüş olur?';

  @override
  List<String> get options => [for (final c in choices) '${formatTr(c, digits: 0)} yıl'];

  @override
  int get correctIndex =>
      choices.indexWhere((c) => (c - shipYears(earthYears, speed)).abs() < 1e-9);

  @override
  String explanation(int answerIndex) =>
      'Ayşe ${formatTr(shipYears(earthYears, speed))} yıl, Ali ${formatTr(earthYears)} '
      'yıl büyüdü. Hızla giden gemideki saatte ışık daha uzun, çapraz bir yol '
      'gider; ışığın hızı değişmediği için her tık daha uzun sürer. Hızlı '
      'giden için zaman yavaş akar! (Bu yalnızca ışık hızına çok yakın hızlarda '
      'belirgindir; uçaklar ve roketler için fark çok çok küçüktür.)';

  EinsteinScene _scene(int run) => EinsteinScene(
    station: EinsteinStation.clock,
    shipSpeed: speed,
    earthYears: earthYears,
    run: run,
  );

  @override
  EinsteinScene get questionScene => _scene(0);

  @override
  EinsteinScene resultScene(int answerIndex) => _scene(1);
}

/// Hangi gemideki saat en yavaş işler?
class SlowestClockTask extends EinsteinTask {
  const SlowestClockTask(this.speeds);

  final List<double> speeds;

  @override
  EinsteinTaskKind get kind => EinsteinTaskKind.clock;

  @override
  String get title => 'En yavaş saat';

  @override
  String get prompt =>
      'Üç gemi farklı hızlarla gidiyor. Dünya\'dan bakınca hangisinin ışık '
      'saati en yavaş tıklar?';

  @override
  List<String> get options => [
    for (final s in speeds) 'Işık hızının ${percentOfC(s)}\'i',
  ];

  @override
  int get correctIndex {
    var best = 0;
    for (var i = 1; i < speeds.length; i++) {
      if (lorentzGamma(speeds[i]) > lorentzGamma(speeds[best])) best = i;
    }
    return best;
  }

  @override
  String explanation(int answerIndex) {
    final list = [
      for (final s in speeds)
        '${percentOfC(s)} hızda 10 yılda ${formatTr(shipYears(10, s))} yıl',
    ].join(', ');
    return '$list geçer. Gemi ne kadar hızlıysa saati o kadar yavaş işler. '
        'Einstein bunu 1905\'te hesapladı; bugün uydulardaki saatler bu yüzden '
        'düzeltilir, yoksa telefonlardaki konum bulma yanlış çalışırdı.';
  }

  @override
  EinsteinScene get questionScene =>
      EinsteinScene(station: EinsteinStation.clock, shipSpeed: speeds.first);

  @override
  EinsteinScene resultScene(int answerIndex) => EinsteinScene(
    station: EinsteinStation.clock,
    shipSpeed: speeds[answerIndex],
    run: 1,
  );
}

// ─────────────────────────── E=mc² ───────────────────────────

/// 1 gram kütle mi, 1 ton odun mu?
class MassVsWoodTask extends EinsteinTask {
  const MassVsWoodTask(this.options);

  @override
  final List<String> options;

  static const mass = '1 gram kütlenin tamamı enerjiye dönüşse';
  static const wood = '1 ton odun yakılsa';
  static const equal = 'İkisi eşit';
  static const optionSet = [mass, wood, equal];

  static const woodGrams = 1000000.0;

  @override
  EinsteinTaskKind get kind => EinsteinTaskKind.energy;

  @override
  String get title => 'Minik kütle, dev enerji';

  @override
  String get prompt =>
      'E = m·c²: enerji, kütle çarpı ışık hızının karesi. Hangisi daha çok '
      'enerji verir?';

  @override
  int get correctIndex {
    final m = massEnergyJoules(1);
    final w = woodGrams * woodJoulesPerGram;
    return options.indexOf(m > w ? mass : (w > m ? wood : equal));
  }

  @override
  String explanation(int answerIndex) {
    final ratio = massEnergyJoules(1) / (woodGrams * woodJoulesPerGram);
    return '1 gram kütle ${friendlyNumber(homesPowered(1))} evin bir yıllık '
        'elektriğine eşit; 1 ton odun ise yalnızca '
        '${friendlyNumber(homesFromBurning(woodGrams))} evinkine. Kütle yaklaşık '
        '${friendlyNumber(ratio)} kat daha güçlü! Işık hızı çok büyük olduğu için '
        'minicik bir kütle dev bir enerjidir. Güneş de böyle parlar: her saniye '
        'kütlesinin bir kısmını ışığa çevirir.';
  }

  @override
  EinsteinScene get questionScene =>
      const EinsteinScene(station: EinsteinStation.energy, grams: 1);

  @override
  EinsteinScene resultScene(int answerIndex) =>
      const EinsteinScene(station: EinsteinStation.energy, grams: 1, run: 1);
}

/// Kütle k katına çıkarsa enerji kaç katına çıkar?
class ScaleMassTask extends EinsteinTask {
  ScaleMassTask(this.factor, this.options);

  final int factor;

  @override
  final List<String> options;

  static List<String> optionSet(int k) => ['$k katına', '${k * k} katına', 'Değişmez'];

  @override
  EinsteinTaskKind get kind => EinsteinTaskKind.energy;

  @override
  String get title => 'Kütleyi artır';

  @override
  String get prompt =>
      'E = m·c² formülünde kütleyi $factor katına çıkarırsak (ışık hızı hep aynı) '
      'enerji kaç katına çıkar?';

  @override
  int get correctIndex {
    final ratio = massEnergyJoules(factor * 0.5) / massEnergyJoules(0.5);
    return options.indexOf(
      (ratio - factor).abs() < 1e-9 ? '$factor katına' : '${factor * factor} katına',
    );
  }

  @override
  String explanation(int answerIndex) =>
      'Enerji kütleyle doğru orantılıdır: kütle $factor katına çıkınca enerji de '
      '$factor katına çıkar. Kare olan kütle değil, ışık hızıdır (c²) — onun '
      'için sayı bu kadar büyük.';

  @override
  EinsteinScene get questionScene =>
      const EinsteinScene(station: EinsteinStation.energy, grams: 0.5, run: 1);

  @override
  EinsteinScene resultScene(int answerIndex) => EinsteinScene(
    station: EinsteinStation.energy,
    grams: 0.5 * factor,
    run: 2,
  );
}
