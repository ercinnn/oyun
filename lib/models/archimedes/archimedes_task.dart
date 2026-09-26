import 'archimedes_scene.dart';
import 'archimedes_screw.dart';
import 'boat.dart';
import 'buoyancy.dart';
import 'crown.dart';
import '../science/science_task.dart';

export '../science/science_task.dart' show formatTr;

/// Görev türleri; oyuncunun turları bu sırayla dönüşümlü gelir.
enum ArchimedesTaskKind { floatSink, displacement, boat, screw }

/// Arşimet görevleri: ortak [ScienceTask]'a ek olarak deneyin sorudan önceki
/// ve cevaptan sonraki sahnesini verir.
sealed class ArchimedesTask extends ScienceTask {
  const ArchimedesTask();

  ArchimedesTaskKind get kind;

  /// Soru sorulurken sahne (cisim henüz kabın üstünde tutuluyor).
  ArchimedesScene get questionScene;

  /// Cevaptan sonra oynayan deney.
  ArchimedesScene resultScene(int answerIndex);
}

/// "Yüzer mi batar mı?"
class FloatSinkTask extends ArchimedesTask {
  const FloatSinkTask(this.object);

  final BuoyancyObject object;

  @override
  ArchimedesTaskKind get kind => ArchimedesTaskKind.floatSink;

  @override
  String get title => 'Yüzer mi, batar mı?';

  @override
  String get prompt => 'Arşimet bu cismi suya bırakacak: ${object.emoji} '
      '${object.name} (${formatTr(object.massG, digits: 0)} gram). '
      'Sence ne olacak?';

  @override
  List<String> get options => const ['Yüzer', 'Batar'];

  @override
  int get correctIndex => object.floats ? 0 : 1;

  @override
  String explanation(int answerIndex) {
    final what = object.floats
        ? 'Yüzdü! Kapladığı yer kadar su, kendisinden daha ağır.'
        : 'Battı! Kapladığı yer kadar su, kendisinden daha hafif.';
    return '$what ${object.note} Su seviyesi '
        '${formatTr(object.waterRiseCm)} cm yükseldi.';
  }

  @override
  ArchimedesScene get questionScene => ArchimedesScene(
    station: ArchimedesStation.tank,
    tanks: [TankState(held: object)],
  );

  @override
  ArchimedesScene resultScene(int answerIndex) => ArchimedesScene(
    station: ArchimedesStation.tank,
    tanks: [TankState(dropped: [object])],
    revision: 1,
  );
}

/// İki batan cisimden hangisi suyu daha çok yükseltir?
class DisplacementTask extends ArchimedesTask {
  const DisplacementTask(this.a, this.b);

  @override
  String? get hint => 'Soldaki kap A, sağdaki kap B.';

  final BuoyancyObject a;
  final BuoyancyObject b;

  @override
  ArchimedesTaskKind get kind => ArchimedesTaskKind.displacement;

  @override
  String get title => 'Su ne kadar yükselir?';

  @override
  String get prompt => 'İki cisim de dibe batar. A kabına ${a.emoji} '
      '${a.name} (${formatTr(a.massG, digits: 0)} g), B kabına ${b.emoji} '
      '${b.name} (${formatTr(b.massG, digits: 0)} g) bırakılacak. Hangi '
      'kaptaki su daha çok yükselir?';

  @override
  List<String> get options => const ['A kabı', 'B kabı', 'İkisi aynı'];

  @override
  int get correctIndex => a.displacedCm3 > b.displacedCm3 ? 0 : 1;

  @override
  String explanation(int answerIndex) =>
      'A kabındaki su ${formatTr(a.waterRiseCm)} cm, B kabındaki su '
      '${formatTr(b.waterRiseCm)} cm yükseldi. Batan bir cisim, kendi '
      'büyüklüğü kadar suyu yerinden iter. Önemli olan ağırlık değil, '
      'kapladığı yer!';

  @override
  ArchimedesScene get questionScene => ArchimedesScene(
    station: ArchimedesStation.tank,
    tanks: [
      TankState(held: a, label: 'A'),
      TankState(held: b, label: 'B'),
    ],
  );

  @override
  ArchimedesScene resultScene(int answerIndex) => ArchimedesScene(
    station: ArchimedesStation.tank,
    tanks: [
      TankState(dropped: [a], label: 'A'),
      TankState(dropped: [b], label: 'B'),
    ],
    revision: 1,
  );
}

/// Kralın tacı: aynı ağırlıkta iki taçtan sahtesi dolu kaptan daha çok su
/// taşırır.
class CrownTask extends ArchimedesTask {
  const CrownTask({required this.fakeIsA});

  @override
  String? get hint => 'Soldaki kap A, sağdaki kap B.';

  final bool fakeIsA;

  BuoyancyObject get crownA => fakeIsA ? fakeCrown : goldCrown;
  BuoyancyObject get crownB => fakeIsA ? goldCrown : fakeCrown;

  @override
  ArchimedesTaskKind get kind => ArchimedesTaskKind.displacement;

  @override
  String get title => 'Kralın tacı';

  @override
  String get prompt => 'Kralın iki tacı var, ikisi de tam 1000 gram. '
      '${fakeIsA ? 'A tacına gümüş karıştırılmış, B tacı saf altın' : 'A tacı saf altın, B tacına gümüş karıştırılmış'}. '
      'Arşimet ikisini de ağzına kadar dolu kaplara batıracak. Hangi kap '
      'daha çok su taşırır?';

  @override
  List<String> get options => const ['A kabı', 'B kabı', 'İkisi aynı'];

  @override
  int get correctIndex => fakeIsA ? 0 : 1;

  @override
  String explanation(int answerIndex) {
    final fake = fakeIsA ? 'A' : 'B';
    final gold = fakeIsA ? 'B' : 'A';
    final same = answerIndex == 2
        ? 'Ağırlıkları aynı ama bu yetmez! '
        : '';
    return '$same$fake kabından ${formatTr(fakeCrown.displacedCm3, digits: 0)} '
        'mL, $gold kabından ${formatTr(goldCrown.displacedCm3, digits: 0)} mL '
        'su taştı. Gümüş altından hafif olduğu için, aynı ağırlığa ulaşmak '
        'daha çok yer kaplar. Böylece Arşimet tacı eritmeden sahte olduğunu '
        'buldu ve "Evreka!" (Buldum!) diye bağırdı.';
  }

  TankState _tank(BuoyancyObject crown, String label, {required bool dipped}) =>
      TankState(
        held: dipped ? null : crown,
        dropped: dipped ? [crown] : const [],
        brimFull: true,
        label: label,
      );

  @override
  ArchimedesScene get questionScene => ArchimedesScene(
    station: ArchimedesStation.tank,
    tanks: [
      _tank(crownA, 'A', dipped: false),
      _tank(crownB, 'B', dipped: false),
    ],
  );

  @override
  ArchimedesScene resultScene(int answerIndex) => ArchimedesScene(
    station: ArchimedesStation.tank,
    tanks: [
      _tank(crownA, 'A', dipped: true),
      _tank(crownB, 'B', dipped: true),
    ],
    revision: 1,
  );
}

/// Gemi batmadan en çok kaç sandık taşır?
class BoatTask extends ArchimedesTask {
  const BoatTask(this.boat, this.choices);

  final BoatSpec boat;

  /// Üç sandık sayısı; biri [BoatSpec.maxCrates].
  final List<int> choices;

  @override
  ArchimedesTaskKind get kind => ArchimedesTaskKind.boat;

  @override
  String get title => 'Gemiye yük';

  @override
  String get prompt => '${boat.emoji} ${boat.name} ${formatTr(boat.massG, digits: 0)} '
      'gram. Gövdesi tamamen suya gömülünce ${formatTr(boat.hullVolumeCm3, digits: 0)} '
      'gram su iter. Her sandık ${formatTr(crateMassG, digits: 0)} gram. Batmadan '
      'en çok kaç sandık taşır?';

  @override
  List<String> get options => [for (final c in choices) '$c sandık'];

  @override
  int get correctIndex => choices.indexOf(boat.maxCrates);

  @override
  String explanation(int answerIndex) {
    final loaded = choices[answerIndex];
    final spare = boat.hullVolumeCm3 - boat.massG;
    final result = boat.sinks(loaded)
        ? '$loaded sandıkla su küpeşteden içeri doldu ve gemi battı. '
        : '$loaded sandıkla gemi yüzmeye devam etti. ';
    return '${result}Gemi en çok ${formatTr(boat.hullVolumeCm3, digits: 0)} '
        'gram su itebilir; ${formatTr(boat.massG, digits: 0)} gramı geminin '
        'kendisi. Geriye ${formatTr(spare, digits: 0)} gram kalır, bu da '
        '${boat.maxCrates} sandık eder. Gemi yük aldıkça suya daha çok gömülür '
        've daha çok su iter.';
  }

  @override
  ArchimedesScene get questionScene =>
      ArchimedesScene(station: ArchimedesStation.boat, boat: boat);

  @override
  ArchimedesScene resultScene(int answerIndex) => ArchimedesScene(
    station: ArchimedesStation.boat,
    boat: boat,
    crates: choices[answerIndex],
    revision: 1,
  );
}

/// Vida hangi açıyla tarlayı en az turda sular?
class ScrewTask extends ArchimedesTask {
  const ScrewTask(this.angles);

  /// Üç açı (derece); tam biri en az turda sular.
  final List<double> angles;

  /// Sonuç sahnesinde vida bu kadar döner.
  static const demoTurns = 6.0;

  @override
  ArchimedesTaskKind get kind => ArchimedesTaskKind.screw;

  @override
  String get title => 'Arşimet vidası';

  @override
  String get prompt => 'Tarla nehirden ${formatTr(fieldHeightM)} metre yüksekte, '
      'vidanın boyu ${formatTr(screwLengthM)} metre. Vidayı hangi açıyla '
      'kurarsan tarla en az turda sulanır?';

  @override
  List<String> get options => [for (final a in angles) '${a.round()}°'];

  @override
  int get correctIndex {
    var best = -1;
    int? bestTurns;
    for (var i = 0; i < angles.length; i++) {
      final turns = screwTurnsToFill(angles[i]);
      if (turns != null && (bestTurns == null || turns < bestTurns)) {
        best = i;
        bestTurns = turns;
      }
    }
    return best;
  }

  @override
  String explanation(int answerIndex) {
    final lines = [
      for (final a in angles)
        screwTurnsToFill(a) == null
            ? '${a.round()}°: su tarlaya ulaşmıyor.'
            : '${a.round()}°: ${screwTurnsToFill(a)} turda sulanır.',
    ].join(' ');
    return '${screwVerdict(angles[answerIndex])} $lines En iyi açı, tarlaya '
        'yetişen en yatık açıdır.';
  }

  @override
  ArchimedesScene get questionScene => ArchimedesScene(
    station: ArchimedesStation.screw,
    screwAngle: angles.first,
  );

  @override
  ArchimedesScene resultScene(int answerIndex) {
    final angle = angles[answerIndex];
    final litres = screwLitresPerTurn(angle) * demoTurns;
    return ArchimedesScene(
      station: ArchimedesStation.screw,
      screwAngle: angle,
      screwTurns: demoTurns,
      fieldLitres: litres > fieldNeedLitres ? fieldNeedLitres : litres,
      revision: 1,
    );
  }
}
