import '../science/science_task.dart';
import 'curie_scene.dart';
import 'geiger.dart';
import 'shielding.dart';
import 'therapy.dart';

enum CurieTaskKind { geiger, shield, therapy }

/// Curie görevleri: ortak [ScienceTask]'a ek olarak deneyin sorudan önceki
/// ve cevaptan sonraki sahnesini verir.
sealed class CurieTask extends ScienceTask {
  const CurieTask();

  CurieTaskKind get kind;
  CurieScene get questionScene;
  CurieScene resultScene(int answerIndex);
}

const String _safety =
    ' (Gerçek radyoaktif maddelere asla dokunulmaz; bu bir benzetim.)';

// ─────────────────────────── Sayaç ───────────────────────────

/// Üç numuneden hangisi ışıma yapıyor?
class FindSampleTask extends CurieTask {
  const FindSampleTask(this.samples);

  /// Üç numune; tam biri ışıma yapıyor.
  final List<RadioSample> samples;

  @override
  CurieTaskKind get kind => CurieTaskKind.geiger;

  @override
  String get title => 'Hangisi ışıyor?';

  @override
  String get prompt =>
      'Masada üç numune var: ${samples.map((s) => '${s.emoji} ${s.name}').join(', ')}. '
      'Görünüşleri bir şey söylemiyor. Sence Geiger sayacı hangisinin yanında '
      'hızlı hızlı tıklar?';

  @override
  List<String> get options => [for (final s in samples) s.name];

  @override
  int get correctIndex => samples.indexWhere((s) => s.radioactive);

  @override
  String explanation(int answerIndex) {
    final list = [
      for (final s in samples)
        '${s.name} ${formatCps(countsPerSecond(s, referenceDistanceCm))} tık/sn',
    ].join(', ');
    return '$list. ${samples[correctIndex].note} Işımayı gözle göremeyiz, '
        'ancak sayaçla ölçebiliriz.$_safety';
  }

  @override
  CurieScene get questionScene => const CurieScene(station: CurieStation.geiger);

  @override
  CurieScene resultScene(int answerIndex) =>
      CurieScene(station: CurieStation.geiger, sample: samples[answerIndex]);
}

/// Sayacı uzaklaştırınca tıklar ne olur?
class DistanceTask extends CurieTask {
  DistanceTask(this.sample, this.toCm, this.options);

  final RadioSample sample;
  final double toCm;

  @override
  final List<String> options;

  static const half = 'Yarısına iner';
  static const quarter = 'Dörtte birine iner';
  static const third = 'Üçte birine iner';
  static const ninth = 'Dokuzda birine iner';
  static const same = 'Değişmez';

  /// Uzaklık katına göre seçenek kümesi (karıştırılmamış).
  static List<String> optionSet(double toCm) =>
      toCm == 20 ? const [half, quarter, same] : const [third, ninth, same];

  @override
  CurieTaskKind get kind => CurieTaskKind.geiger;

  @override
  String get title => 'Uzaklaşınca';

  @override
  String get prompt =>
      '${sample.name} numunesinden ${formatTr(referenceDistanceCm)} cm '
      'uzakta sayaç çok hızlı tıklıyor. Sayacı ${formatTr(toCm)} cm\'ye '
      'çekersek (${formatTr(toCm / referenceDistanceCm)} kat uzak) tıklamalar '
      'ne olur?';

  @override
  int get correctIndex {
    final f = inverseSquareFactor(referenceDistanceCm, toCm);
    final text = (f - 0.25).abs() < 1e-9
        ? quarter
        : (f - 1 / 9).abs() < 1e-9
        ? ninth
        : same;
    return options.indexOf(text);
  }

  @override
  String explanation(int answerIndex) {
    final a = countsPerSecond(sample, referenceDistanceCm);
    final b = countsPerSecond(sample, toCm);
    return '${formatCps(a)} tık/sn iken ${formatCps(b)} tık/sn '
        'oldu. Işınlar her yöne yayılır; uzaklık ${formatTr(toCm / referenceDistanceCm)} '
        'katına çıkınca aynı ışınlar ${formatTr(toCm * toCm / (referenceDistanceCm * referenceDistanceCm))} '
        'kat büyük bir alana dağılır. Bu yüzden radyoaktif maddeden uzak '
        'durmak en iyi korunmadır.$_safety';
  }

  @override
  CurieScene get questionScene =>
      CurieScene(station: CurieStation.geiger, sample: sample);

  @override
  CurieScene resultScene(int answerIndex) =>
      CurieScene(station: CurieStation.geiger, sample: sample, distanceCm: toCm);
}

// ─────────────────────────── Kalkanlar ───────────────────────────

/// Bu ışını durdurmaya en ince hangi kalkan yeter?
class StopperTask extends CurieTask {
  const StopperTask(this.ray);

  final RayType ray;

  static const shields = [Shield.paper, Shield.aluminum, Shield.lead];

  @override
  CurieTaskKind get kind => CurieTaskKind.shield;

  @override
  String get title => 'Kalkan seç';

  @override
  String get prompt =>
      'Kaynaktan ${ray.label} ışınları çıkıyor. Sayacı susturmak için en ince '
      'hangi kalkan yeter?';

  @override
  List<String> get options => [for (final s in shields) s.label];

  @override
  int get correctIndex => shields.indexOf(thinnestStopper(ray));

  @override
  String explanation(int answerIndex) {
    final list = [
      for (final s in shields)
        '${s.label} ile ${formatCps(shieldedCps(ray, s))} tık/sn',
    ].join(', ');
    return '$list. Alfa ışını bir kâğıtta, beta ışını ince alüminyumda durur; '
        'gama ışını ancak kalın kurşunla büyük ölçüde durdurulur. Bu yüzden '
        'hastanelerde röntgen odalarının duvarlarında kurşun vardır.';
  }

  @override
  CurieScene get questionScene =>
      CurieScene(station: CurieStation.shield, ray: ray);

  @override
  CurieScene resultScene(int answerIndex) => CurieScene(
    station: CurieStation.shield,
    ray: ray,
    shield: shields[answerIndex],
  );
}

/// Ölçümlerden ışın türünü bul.
class IdentifyRayTask extends CurieTask {
  const IdentifyRayTask(this.ray);

  final RayType ray;

  @override
  CurieTaskKind get kind => CurieTaskKind.shield;

  @override
  String get title => 'Hangi ışın?';

  @override
  String get prompt =>
      'Bilinmeyen bir kaynağın önüne sırayla kalkan koyduk. Kalkansız '
      '${formatCps(shieldedCps(ray, Shield.none))}, kâğıtla '
      '${formatCps(shieldedCps(ray, Shield.paper))}, alüminyumla '
      '${formatCps(shieldedCps(ray, Shield.aluminum))}, kurşunla '
      '${formatCps(shieldedCps(ray, Shield.lead))} tık/sn. Kaynak '
      'hangi ışını yayıyor?';

  @override
  List<String> get options => [for (final r in RayType.values) r.label];

  @override
  int get correctIndex => RayType.values.indexOf(ray);

  @override
  String explanation(int answerIndex) => switch (ray) {
    RayType.alpha =>
      'Kâğıt bile sayacı susturdu: alfa ışını. Ağır ve yavaş olduğu için çok '
          'kolay durur.',
    RayType.beta =>
      'Kâğıttan geçti ama alüminyum durdurdu: beta ışını.',
    RayType.gamma =>
      'Alüminyumdan da geçti, ancak kurşun çoğunu durdurdu: gama ışını. En '
          'içe işleyen ışın budur.',
  };

  @override
  CurieScene get questionScene =>
      CurieScene(station: CurieStation.shield, ray: ray, shield: Shield.paper);

  @override
  CurieScene resultScene(int answerIndex) =>
      CurieScene(station: CurieStation.shield, ray: ray, shield: Shield.aluminum);
}

// ─────────────────────────── Tedavi ───────────────────────────

/// Hangi plan tümörü yok edip sağlıklı dokuyu korur?
class BeamPlanTask extends CurieTask {
  BeamPlanTask(this.plans, this.labels);

  final List<List<Beam>> plans;
  final List<String> labels;

  @override
  CurieTaskKind get kind => CurieTaskKind.therapy;

  @override
  String get title => 'Tedavi planı';

  @override
  String get prompt =>
      'Tümöre ${formatTr(targetDose, digits: 0)} birim ışın vermeliyiz ama '
      'sağlıklı doku en fazla ${formatTr(safeHealthyDose)} birim alabilir. '
      'Hangi plan hem tümörü tedavi eder hem sağlıklı dokuyu korur?';

  @override
  List<String> get options => labels;

  @override
  int get correctIndex {
    for (var i = 0; i < plans.length; i++) {
      final d = computeDose(plans[i]);
      if (d.safe && d.tumorDose >= targetDose - 1e-9) return i;
    }
    return -1;
  }

  @override
  String explanation(int answerIndex) {
    final list = [
      for (var i = 0; i < plans.length; i++)
        '${labels[i]}: sağlıklı doku ${formatTr(computeDose(plans[i]).maxHealthyDose)} birim',
    ].join('; ');
    return '$list. Işınlar farklı yönlerden gelince hepsi yalnızca tümörde '
        'buluşur; her biri yolundaki sağlıklı dokuya az doz bırakır. Marie '
        'Curie\'nin radyumla çalışmaları bu tedavilerin önünü açtı.';
  }

  @override
  CurieScene get questionScene =>
      CurieScene(station: CurieStation.therapy, beams: plans.first);

  @override
  CurieScene resultScene(int answerIndex) => CurieScene(
    station: CurieStation.therapy,
    beams: plans[answerIndex],
    beamsOn: true,
  );
}

/// Kesişen ışınların dozları toplanır.
class DoseSumTask extends CurieTask {
  DoseSumTask(this.count, this.strength, this.choices);

  final int count;
  final double strength;
  final List<double> choices;

  List<Beam> get _beams => spreadBeams(count, total: count * strength);

  @override
  CurieTaskKind get kind => CurieTaskKind.therapy;

  @override
  String get title => 'Işınlar buluşunca';

  @override
  String get prompt =>
      '$count ışın farklı yönlerden geliyor, her biri ${formatTr(strength)} '
      'birim. Hepsi tümörde kesişiyor. Tümör kaç birim ışın alır?';

  @override
  List<String> get options => [for (final c in choices) '${formatTr(c)} birim'];

  @override
  int get correctIndex => choices.indexOf(computeDose(_beams).tumorDose);

  @override
  String explanation(int answerIndex) {
    final d = computeDose(_beams);
    return 'Tümör ${formatTr(d.tumorDose)} birim aldı: kesişen ışınların dozu '
        'toplanır. Tümörden uzaktaki sağlıklı doku ise en fazla '
        '${formatTr(d.maxHealthyDose)} birim aldı.';
  }

  @override
  CurieScene get questionScene =>
      CurieScene(station: CurieStation.therapy, beams: _beams);

  @override
  CurieScene resultScene(int answerIndex) =>
      CurieScene(station: CurieStation.therapy, beams: _beams, beamsOn: true);
}
