import '../science/science_task.dart';
import 'generator.dart';
import 'tesla_scene.dart';
import 'transmission.dart';
import 'wireless.dart';

enum TeslaTaskKind { generator, transmission, wireless }

/// Tesla görevleri: ortak [ScienceTask]'a ek olarak deneyin sorudan önceki
/// ve cevaptan sonraki sahnesini verir.
sealed class TeslaTask extends ScienceTask {
  const TeslaTask();

  TeslaTaskKind get kind;
  TeslaScene get questionScene;
  TeslaScene resultScene(int answerIndex);
}

String _volts(double v) => '${formatTr(v, digits: 0)} V';

// ─────────────────────────── Jeneratör ───────────────────────────

/// Kolu daha hızlı çevirince ne olur?
class SpeedTask extends TeslaTask {
  SpeedTask(this.slow, this.fast, this.options);

  final double slow;
  final double fast;

  @override
  final List<String> options;

  static const brighter =
      'Ampul daha parlak yanar, akım daha sık yön değiştirir';
  static const dimmer = 'Ampul söner, akım durur';
  static const same = 'Hiçbir şey değişmez';
  static const optionSet = [brighter, dimmer, same];

  @override
  TeslaTaskKind get kind => TeslaTaskKind.generator;

  @override
  String get title => 'Daha hızlı çevir!';

  @override
  String get prompt =>
      'Jeneratörün kolunu saniyede ${formatTr(slow)} tur çeviriyoruz. '
      'Saniyede ${formatTr(fast)} tura çıkarsak ne olur?';

  @override
  int get correctIndex {
    final moreLight = bulbBrightness(PowerSource.generator, fast) >
        bulbBrightness(PowerSource.generator, slow);
    return options.indexOf(moreLight ? brighter : same);
  }

  @override
  String explanation(int answerIndex) =>
      'Tepe gerilimi ${_volts(peakVolts(slow))} iken '
      '${_volts(peakVolts(fast))} oldu, akım da saniyede ${formatTr(fast)} kez '
      'yön değiştiriyor. Bobin mıknatısların arasında ne kadar hızlı dönerse o '
      'kadar çok elektrik üretir. Evlerimizdeki elektrik de saniyede 50 kez yön '
      'değiştiren alternatif akımdır.';

  @override
  TeslaScene get questionScene =>
      TeslaScene(station: TeslaStation.generator, turnsPerSecond: slow);

  @override
  TeslaScene resultScene(int answerIndex) =>
      TeslaScene(station: TeslaStation.generator, turnsPerSecond: fast);
}

/// Ters bağlı iki LED: pilde mi jeneratörde mi sırayla yanar?
class LedTask extends TeslaTask {
  LedTask(this.source, this.options);

  final PowerSource source;

  @override
  final List<String> options;

  @override
  TeslaTaskKind get kind => TeslaTaskKind.generator;

  @override
  String get title => 'İki LED';

  @override
  String get prompt =>
      'LED yalnızca tek yönde akan elektrikle yanar. Kırmızı ve yeşil iki LED\'i '
      'birbirine ters yönde bağladık. Devreye '
      '${source == PowerSource.battery ? 'bir pil' : 'dönen bir jeneratör'} '
      'bağlarsak ne olur?';

  @override
  int get correctIndex => options.indexOf(ledPattern(source, 1).label);

  @override
  String explanation(int answerIndex) => source == PowerSource.battery
      ? 'Pil doğru akım verir: elektrik hep aynı yönde akar, bu yüzden yalnızca '
            'bir LED yanar ve hep yanık kalır. Edison doğru akımı savunuyordu.'
      : 'Jeneratör alternatif akım verir: akım bir bu yöne bir öbür yöne akar, '
            'bu yüzden LED\'ler sırayla yanıp söner. Tesla alternatif akımı '
            'savundu ve bugün evlerimizde onu kullanıyoruz.';

  @override
  TeslaScene get questionScene =>
      TeslaScene(station: TeslaStation.generator, source: source, turnsPerSecond: 0);

  @override
  TeslaScene resultScene(int answerIndex) =>
      TeslaScene(station: TeslaStation.generator, source: source, turnsPerSecond: 1);
}

// ─────────────────────────── Şehre elektrik ───────────────────────────

/// Uzak şehre hangi gerilimle gönderirsek daha çok ev yanar?
class VoltageTask extends TeslaTask {
  VoltageTask(this.distanceKm, this.turnChoices);

  final double distanceKm;

  /// İkinci bobin sarımları (seçenek sırasıyla).
  final List<int> turnChoices;

  @override
  TeslaTaskKind get kind => TeslaTaskKind.transmission;

  @override
  String get title => 'Uzak şehir';

  @override
  String get prompt =>
      'Santral ${_volts(plantVolts)} üretiyor, şehir ${formatTr(distanceKm)} km '
      'uzakta. Tellerde enerjinin bir kısmı ısıya dönüşüp kayboluyor. Hangi '
      'gerilimle gönderirsek şehirde en çok ev yanar?';

  @override
  List<String> get options => [for (final t in turnChoices) _volts(lineVolts(t))];

  @override
  int get correctIndex {
    var best = 0;
    for (var i = 1; i < turnChoices.length; i++) {
      if (deliveredWatts(lineVolts(turnChoices[i]), distanceKm) >
          deliveredWatts(lineVolts(turnChoices[best]), distanceKm)) {
        best = i;
      }
    }
    return best;
  }

  @override
  String explanation(int answerIndex) {
    final list = [
      for (final t in turnChoices)
        '${_volts(lineVolts(t))} ile ${housesLit(lineVolts(t), distanceKm)} ev',
    ].join(', ');
    return '$list yandı. Gerilim yükselince aynı enerji daha küçük bir akımla '
        'taşınır ve tellerde çok daha az kaybolur. Şehre girince transformatör '
        'gerilimi evler için yeniden düşürür. Tesla\'nın alternatif akımı böylece '
        'Niagara Şelalesi\'ndeki santralden kilometrelerce uzağa taşındı.';
  }

  TeslaScene _scene(int secondary) => TeslaScene(
    station: TeslaStation.transmission,
    distanceKm: distanceKm,
    secondaryTurns: secondary,
  );

  @override
  TeslaScene get questionScene => _scene(primaryTurns);

  @override
  TeslaScene resultScene(int answerIndex) => _scene(turnChoices[answerIndex]);
}

/// Transformatör: sarım oranı gerilimi ne yapar?
class TransformerTask extends TeslaTask {
  TransformerTask({
    required this.inputVolts,
    required this.primary,
    required this.secondary,
    required this.choices,
  });

  final double inputVolts;
  final int primary;
  final int secondary;

  /// Üç gerilim seçeneği (V); biri doğru.
  final List<double> choices;

  double get output => transformerOut(inputVolts, primary, secondary);

  @override
  TeslaTaskKind get kind => TeslaTaskKind.transmission;

  @override
  String get title => 'Transformatör';

  @override
  String get prompt =>
      'Transformatörde demir bir çekirdeğe iki bobin sarılı: birincide $primary, '
      'ikincide $secondary sarım var. Birinci bobine ${_volts(inputVolts)} '
      'alternatif akım veriyoruz. İkinci bobinden kaç volt çıkar?';

  @override
  List<String> get options => [for (final c in choices) _volts(c)];

  @override
  int get correctIndex => choices.indexOf(output);

  @override
  String explanation(int answerIndex) {
    final up = secondary > primary;
    return 'Sarım sayısı ${up ? '${secondary ~/ primary} kat arttığı' : '${primary ~/ secondary} kat azaldığı'} '
        'için gerilim de ${up ? 'o kadar arttı' : 'o kadar azaldı'}: ${_volts(output)}. '
        'Transformatör yalnızca değişen, yani alternatif akımla çalışır; doğru '
        'akımla çalışmaz. AC\'nin en büyük üstünlüğü budur.';
  }

  @override
  TeslaScene get questionScene => const TeslaScene(
    station: TeslaStation.transmission,
    secondaryTurns: primaryTurns,
  );

  /// Sonuçta hat, yükseltici transformatörün bu oranıyla gösterilir
  /// (alçaltıcı soruda santralin kendi gerilimi).
  @override
  TeslaScene resultScene(int answerIndex) => TeslaScene(
    station: TeslaStation.transmission,
    secondaryTurns: secondary > primary ? secondary * primaryTurns ~/ primary : primaryTurns,
  );
}

// ─────────────────────────── Tesla bobini ───────────────────────────

/// Lambayı uzaklaştırınca / yaklaştırınca ne olur?
class LampDistanceTask extends TeslaTask {
  LampDistanceTask(this.fromM, this.toM, this.options);

  final double fromM;
  final double toM;

  @override
  final List<String> options;

  static const brighter = 'Daha parlak yanar';
  static const dimmer = 'Sönükleşir, belki hiç yanmaz';
  static const same = 'Hiç değişmez';
  static const optionSet = [brighter, dimmer, same];

  double _level(double d) => lampBrightness(
    coilOn: true,
    transmitterKHz: 200,
    receiverKHz: 200,
    distanceM: d,
  );

  @override
  TeslaTaskKind get kind => TeslaTaskKind.wireless;

  @override
  String get title => 'Kablosuz lamba';

  @override
  String get prompt =>
      'Tesla bobini çalışıyor ve ${formatTr(fromM)} metre ötedeki floresan lamba '
      'hiçbir kabloya bağlı olmadan yanıyor. Lambayı ${formatTr(toM)} metreye '
      '${toM > fromM ? 'uzaklaştırırsak' : 'yaklaştırırsak'} ne olur?';

  @override
  int get correctIndex {
    final a = _level(fromM), b = _level(toM);
    if ((a - b).abs() < 0.02) return options.indexOf(same);
    return options.indexOf(b > a ? brighter : dimmer);
  }

  @override
  String explanation(int answerIndex) =>
      'Parlaklık %${(_level(fromM) * 100).round()} iken '
      '%${(_level(toM) * 100).round()} oldu. Bobinin yaydığı alan uzaklaştıkça '
      'hızla zayıflar. Tesla enerjiyi kablosuz taşımayı hayal etti; bugün '
      'telefonları kablosuz şarj eden aletler de bu fikirle çalışır. (Tesla '
      'bobini çok yüksek gerilim üretir: evde asla denenmez!)';

  TeslaScene _scene(double d) => TeslaScene(
    station: TeslaStation.wireless,
    coilOn: true,
    lampDistanceM: d,
  );

  @override
  TeslaScene get questionScene => _scene(fromM);

  @override
  TeslaScene resultScene(int answerIndex) => _scene(toM);
}

/// Alıcıyı hangi frekansa ayarlarsak lamba en parlak yanar?
class TuningTask extends TeslaTask {
  TuningTask(this.transmitterKHz, this.choices);

  final double transmitterKHz;
  final List<double> choices;

  @override
  TeslaTaskKind get kind => TeslaTaskKind.wireless;

  @override
  String get title => 'Frekansı ayarla';

  @override
  String get prompt =>
      'Tesla bobini saniyede ${formatTr(transmitterKHz, digits: 0)} bin kez '
      'titreşiyor (${formatTr(transmitterKHz, digits: 0)} kHz). Lambanın alıcı '
      'devresini hangi frekansa ayarlarsak lamba en parlak yanar?';

  @override
  List<String> get options =>
      [for (final c in choices) '${formatTr(c, digits: 0)} kHz'];

  @override
  int get correctIndex {
    var best = 0;
    for (var i = 1; i < choices.length; i++) {
      if (resonance(transmitterKHz, choices[i]) >
          resonance(transmitterKHz, choices[best])) {
        best = i;
      }
    }
    return best;
  }

  @override
  String explanation(int answerIndex) =>
      'Alıcı vericiyle aynı frekansa ayarlanınca enerjiyi en iyi toplar: buna '
      'rezonans denir. Salıncağı tam doğru anlarda itersen yükselir; yanlış '
      'anlarda itersen durur. Radyoyu bir istasyona ayarlarken de alıcıyı o '
      'istasyonun frekansına getiririz.';

  TeslaScene _scene(double receiver) => TeslaScene(
    station: TeslaStation.wireless,
    coilOn: true,
    transmitterKHz: transmitterKHz,
    receiverKHz: receiver,
    lampDistanceM: 1,
  );

  @override
  TeslaScene get questionScene => _scene(receiverMinKHz);

  @override
  TeslaScene resultScene(int answerIndex) => _scene(choices[answerIndex]);
}
