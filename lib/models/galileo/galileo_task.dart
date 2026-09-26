import 'dart:math';

import '../science/science_task.dart';
import 'galileo_scene.dart';
import 'jupiter.dart';
import 'solar.dart';
import 'telescope.dart';

enum GalileoTaskKind { telescope, jupiter, solar }

/// Galileo görevleri: ortak [ScienceTask]'a ek olarak deneyin sorudan önceki
/// ve cevaptan sonraki sahnesini verir.
sealed class GalileoTask extends ScienceTask {
  const GalileoTask();

  GalileoTaskKind get kind;
  GalileoScene get questionScene;
  GalileoScene resultScene(int answerIndex);
}

String _lens(double fo, double fe) =>
    'Objektif ${formatTr(fo)} cm + göz merceği ${formatTr(fe)} cm';

// ─────────────────────────── Teleskop ───────────────────────────

/// Hangi mercek çifti en çok büyütür?
class MagnifyTask extends GalileoTask {
  const MagnifyTask(this.pairs);

  /// Üç (objektif, göz merceği) çifti; büyütmeleri birbirinden farklı.
  final List<(double, double)> pairs;

  @override
  GalileoTaskKind get kind => GalileoTaskKind.telescope;

  @override
  String get title => 'En güçlü teleskop';

  @override
  String get prompt =>
      'Galileo mercekleri kendisi taşlayıp parlatırdı. Uzak odaklı objektif '
      'uzağı toplar, kısa odaklı göz merceği görüntüyü büyütür. Hangi çift '
      'Jüpiter\'i en büyük gösterir?';

  @override
  List<String> get options => [for (final (fo, fe) in pairs) _lens(fo, fe)];

  @override
  int get correctIndex {
    var best = 0;
    for (var i = 1; i < pairs.length; i++) {
      if (magnification(pairs[i].$1, pairs[i].$2) >
          magnification(pairs[best].$1, pairs[best].$2)) {
        best = i;
      }
    }
    return best;
  }

  @override
  String explanation(int answerIndex) {
    final list = [
      for (final (fo, fe) in pairs)
        '${formatTr(fo)} ÷ ${formatTr(fe)} = ${formatTr(magnification(fo, fe))} kat',
    ].join(', ');
    return 'Büyütme, objektifin odak uzaklığının göz merceğininkine bölümüdür: '
        '$list. Galileo\'nun en iyi teleskobu yaklaşık 30 kat büyütüyordu; o '
        'güne kadar kimse gökyüzünü bu kadar yakından görmemişti.';
  }

  @override
  GalileoScene get questionScene => GalileoScene(
    station: GalileoStation.telescope,
    objectiveCm: pairs.first.$1,
    eyepieceCm: pairs.first.$2,
    tubeCm: sharpTubeCm(pairs.first.$1, pairs.first.$2),
  );

  @override
  GalileoScene resultScene(int answerIndex) {
    final (fo, fe) = pairs[answerIndex];
    return GalileoScene(
      station: GalileoStation.telescope,
      objectiveCm: fo,
      eyepieceCm: fe,
      tubeCm: sharpTubeCm(fo, fe),
    );
  }
}

/// Görüntü bulanık: tüp kaç cm olmalı?
class FocusTask extends GalileoTask {
  const FocusTask(this.objectiveCm, this.eyepieceCm, this.choices);

  final double objectiveCm;
  final double eyepieceCm;

  /// Üç tüp boyu (cm); biri objektif − göz merceği.
  final List<double> choices;

  @override
  GalileoTaskKind get kind => GalileoTaskKind.telescope;

  @override
  String get title => 'Odaklama';

  @override
  String get prompt =>
      'Objektif ${formatTr(objectiveCm)} cm, içbükey göz merceği '
      '${formatTr(eyepieceCm)} cm. Galileo\'nun teleskobunda görüntü, tüp boyu '
      'objektiften göz merceği kadar kısa olunca netleşir. Tüp kaç cm olmalı?';

  @override
  List<String> get options => [for (final c in choices) '${formatTr(c)} cm'];

  @override
  int get correctIndex =>
      choices.indexWhere((c) => isSharp(objectiveCm, eyepieceCm, c));

  @override
  String explanation(int answerIndex) =>
      '${formatTr(objectiveCm)} − ${formatTr(eyepieceCm)} = '
      '${formatTr(sharpTubeCm(objectiveCm, eyepieceCm))} cm. İçbükey göz merceği '
      'ışığı biraz dağıtır, bu yüzden objektifin toplayacağı noktadan önce '
      'durmalıdır. Tüp çok uzun ya da kısa olursa görüntü bulanıklaşır.';

  @override
  GalileoScene get questionScene => GalileoScene(
    station: GalileoStation.telescope,
    objectiveCm: objectiveCm,
    eyepieceCm: eyepieceCm,
    // Soru bulanık bir görüntüyle başlar.
    tubeCm: objectiveCm + eyepieceCm,
  );

  @override
  GalileoScene resultScene(int answerIndex) => GalileoScene(
    station: GalileoStation.telescope,
    objectiveCm: objectiveCm,
    eyepieceCm: eyepieceCm,
    tubeCm: choices[answerIndex],
  );
}

// ─────────────────────────── Jüpiter ───────────────────────────

/// Hangi uydu Jüpiter'in etrafını en hızlı dolanır?
class FastestMoonTask extends GalileoTask {
  const FastestMoonTask(this.moons);

  final List<JupiterMoon> moons;

  @override
  GalileoTaskKind get kind => GalileoTaskKind.jupiter;

  @override
  String get title => 'En hızlı uydu';

  @override
  String get prompt =>
      'Jüpiter\'in etrafında dönen uyduların uzaklıkları: '
      '${moons.map((m) => '${m.name} ${formatTr(m.distance)}').join(', ')} '
      '(Jüpiter yarıçapı). Hangisi bir turunu en kısa sürede tamamlar?';

  @override
  List<String> get options => [for (final m in moons) m.name];

  @override
  int get correctIndex {
    var best = 0;
    for (var i = 1; i < moons.length; i++) {
      if (moons[i].periodDays < moons[best].periodDays) best = i;
    }
    return best;
  }

  @override
  String explanation(int answerIndex) =>
      '${moons.map((m) => '${m.name} ${formatTr(m.periodDays)} günde').join(', ')} '
      'bir tur atar. Jüpiter\'e yakın olan uydu hem daha kısa yolda hem daha '
      'hızlı döner. Galileo dört uydunun geceden geceye yer değiştirdiğini '
      'defterine çizdi.';

  @override
  GalileoScene get questionScene =>
      const GalileoScene(station: GalileoStation.jupiter);

  @override
  GalileoScene resultScene(int answerIndex) => GalileoScene(
    station: GalileoStation.jupiter,
    nights: 2,
    highlightMoonId: moons[correctIndex].id,
  );
}

/// Bu gece sağda en uçta duran uydu, birkaç gece sonra nerede görünür?
class MoonWhereTask extends GalileoTask {
  MoonWhereTask(this.moon, this.nightsLater)
    : startNight = _maxEastNight(moon);

  final JupiterMoon moon;
  final int nightsLater;

  /// Uydunun teleskopta Jüpiter'in en sağında göründüğü ilk gece.
  final double startNight;

  static double _maxEastNight(JupiterMoon m) {
    final start = m.startAngleDeg / 360;
    final turns = (1 - start) % 1;
    return turns * m.periodDays;
  }

  static const _options = [
    'Jüpiter\'in solunda',
    'Jüpiter\'in sağında',
    'Jüpiter\'in önünde ya da arkasında (görünmez)',
  ];

  @override
  GalileoTaskKind get kind => GalileoTaskKind.jupiter;

  @override
  String get title => 'Uydu nereye gitti?';

  @override
  String get prompt =>
      'Bu gece ${moon.name} Jüpiter\'in en sağında görünüyor. ${moon.name} '
      'Jüpiter\'in etrafını yaklaşık ${formatTr(moon.periodDays, digits: 0)} '
      'günde bir dolanır. $nightsLater gece sonra nerede görünür?';

  @override
  List<String> get options => _options;

  @override
  int get correctIndex => switch (moonSide(moon, startNight + nightsLater)) {
    MoonSide.left => 0,
    MoonSide.right => 1,
    MoonSide.hidden => 2,
  };

  @override
  String explanation(int answerIndex) {
    final turns = nightsLater / moon.periodDays;
    final half = (turns % 1 - 0.5).abs() < 0.2;
    return '$nightsLater gecede ${moon.name} yaklaşık ${formatTr(turns)} tur attı. '
        '${half ? 'Yarım tur atınca Jüpiter\'in öbür yanına geçer.' : 'Tam tura yakın dönünce yine aynı yana gelir.'} '
        'Uydular Jüpiter\'in etrafında döndüğü için teleskopta bir sağa, bir '
        'sola gidip gelir gibi görünürler.';
  }

  @override
  GalileoScene get questionScene => GalileoScene(
    station: GalileoStation.jupiter,
    nights: startNight,
    highlightMoonId: moon.id,
  );

  @override
  GalileoScene resultScene(int answerIndex) => GalileoScene(
    station: GalileoStation.jupiter,
    nights: startNight + nightsLater,
    highlightMoonId: moon.id,
  );
}

// ─────────────────────────── Güneş sistemi ───────────────────────────

/// Hangi gezegen Güneş'in etrafını en hızlı dolanır?
class FastestPlanetTask extends GalileoTask {
  const FastestPlanetTask(this.options3);

  final List<Planet> options3;

  @override
  GalileoTaskKind get kind => GalileoTaskKind.solar;

  @override
  String get title => 'Güneş\'in etrafında';

  @override
  String get prompt =>
      'Galileo, Dünya\'nın ve gezegenlerin Güneş\'in etrafında döndüğünü '
      'savundu. Bu gezegenlerden hangisi Güneş\'in etrafını en kısa sürede '
      'dolanır?';

  @override
  List<String> get options => [for (final p in options3) p.name];

  @override
  int get correctIndex {
    var best = 0;
    for (var i = 1; i < options3.length; i++) {
      if (options3[i].periodDays < options3[best].periodDays) best = i;
    }
    return best;
  }

  @override
  String explanation(int answerIndex) =>
      '${options3.map((p) => '${p.name} ${formatTr(p.periodDays, digits: 0)} günde').join(', ')} '
      'bir tur atar. Güneş\'e yakın gezegen daha kısa yolda ve daha hızlı '
      'dolanır. Dünya\'nın bir turu bir yıldır: 365 gün.';

  @override
  GalileoScene get questionScene => GalileoScene(
    station: GalileoStation.solar,
    highlightPlanetIds: [for (final p in options3) p.id],
  );

  @override
  GalileoScene resultScene(int answerIndex) => GalileoScene(
    station: GalileoStation.solar,
    day: 120,
    highlightPlanetIds: [for (final p in options3) p.id],
  );
}

/// Dünya'dan bakınca Venüs nasıl görünür?
class VenusPhaseTask extends GalileoTask {
  const VenusPhaseTask(this.offsetDeg);

  /// Venüs, Dünya'nın açısından bu kadar ileride (derece).
  final double offsetDeg;

  VenusView get _view => venusFromEarth(0, offsetDeg * pi / 180);

  bool get _near => _view.relativeSize > 1;

  @override
  GalileoTaskKind get kind => GalileoTaskKind.solar;

  @override
  String get title => 'Venüs\'ün evreleri';

  @override
  String get prompt => _near
      ? 'Venüs şu an Dünya\'ya çok yakın, neredeyse Güneş ile Dünya\'nın '
            'arasında. Galileo teleskopla bakınca Venüs\'ü nasıl gördü?'
      : 'Venüs şu an Güneş\'in öbür yanında, Dünya\'dan çok uzakta. Galileo '
            'teleskopla bakınca Venüs\'ü nasıl gördü?';

  @override
  List<String> get options => [for (final p in VenusPhase.values) p.label];

  @override
  int get correctIndex => VenusPhase.values.indexOf(_view.phase);

  @override
  String explanation(int answerIndex) =>
      'Venüs\'ün yalnızca Güneş\'e bakan yüzü aydınlıktır. '
      '${_near ? 'Dünya\'ya yakınken aydınlık yüzünün çoğu bize dönük değildir: ince bir hilal görürüz, ama yakın olduğu için büyüktür.' : 'Güneş\'in öbür yanındayken aydınlık yüzü bize döner: neredeyse dolunay gibi görünür ama uzak olduğu için küçüktür.'} '
      'Venüs Dünya\'nın etrafında dönseydi hiç dolunay gibi görünemezdi. '
      'Galileo bu evreleri görünce Güneş merkezli modelin doğru olduğunu anladı.';

  GalileoScene _scene({required bool reveal}) => GalileoScene(
    station: GalileoStation.solar,
    venusOffsetDeg: offsetDeg,
    highlightPlanetIds: const ['venus', 'earth'],
    showVenusView: reveal,
  );

  @override
  GalileoScene get questionScene => _scene(reveal: false);

  @override
  GalileoScene resultScene(int answerIndex) => _scene(reveal: true);
}
