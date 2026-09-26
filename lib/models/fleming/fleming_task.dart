import '../science/science_task.dart';
import 'fleming_scene.dart';
import 'hygiene.dart';
import 'petri.dart';
import 'resistance.dart';

enum FlemingTaskKind { petri, hygiene, medicine }

/// Fleming görevleri: ortak [ScienceTask]'a ek olarak deneyin sorudan önceki
/// ve cevaptan sonraki sahnesini verir.
sealed class FlemingTask extends ScienceTask {
  const FlemingTask();

  FlemingTaskKind get kind;
  FlemingScene get questionScene;
  FlemingScene resultScene(int answerIndex);
}

// ─────────────────────────── Petri ───────────────────────────

/// Küfün çevresinde ne olur?
class ZoneTask extends FlemingTask {
  const ZoneTask(this.options);

  @override
  final List<String> options;

  static const clear = 'Bakterisiz, temiz bir halka';
  static const covered = 'Her yeri kaplayan bakteriler';
  static const more = 'Küfün yanında daha çok bakteri';
  static const optionSet = [clear, covered, more];

  static const days = 5.0;

  @override
  FlemingTaskKind get kind => FlemingTaskKind.petri;

  @override
  String get title => 'Fleming\'in şansı';

  @override
  String get prompt =>
      '1928\'de Fleming tatile çıkarken bakteri ektiği bir kabı masada unuttu. '
      'Döndüğünde kapta mavi-yeşil bir küf üremişti. Küfün çevresinde ne '
      'gördü?';

  @override
  int get correctIndex {
    final blocked = petriColonies
        .where((c) => colonyBlocked(c, days, mold: true))
        .length;
    return options.indexOf(blocked > 0 ? clear : covered);
  }

  @override
  String explanation(int answerIndex) {
    final blocked = petriColonyCount - livingColonies(days, mold: true);
    return 'Küfün çevresindeki $blocked koloni büyüyemedi: temiz bir halka oluştu. '
        'Küf, bakterileri öldüren bir madde salgılıyordu. Fleming ona '
        '"penisilin" dedi; bu ilk antibiyotikti. İyi bir bilim insanı gibi '
        'şaşırtıcı bir şeyi çöpe atmadı, inceledi!';
  }

  FlemingScene _scene(double day) =>
      FlemingScene(station: FlemingStation.petri, day: day);

  @override
  FlemingScene get questionScene => _scene(0);

  @override
  FlemingScene resultScene(int answerIndex) => _scene(days);
}

/// Küflü kap mı, kontrol kabı mı: hangisinde daha az bakteri?
class ControlDishTask extends FlemingTask {
  const ControlDishTask(this.days);

  final double days;

  static const options3 = ['A kabı (küflü)', 'B kabı (küfsüz, kontrol)', 'İkisi aynı'];

  @override
  FlemingTaskKind get kind => FlemingTaskKind.petri;

  @override
  String get title => 'Kontrol kabı';

  @override
  String get prompt =>
      'İki kaba aynı bakteriyi ektik. A kabına küf de koyduk, B kabına '
      'koymadık. ${formatTr(days)} gün sonra hangisinde daha az bakteri '
      'kolonisi olur?';

  @override
  String? get hint => 'Soldaki kap A, sağdaki kap B.';

  @override
  List<String> get options => options3;

  @override
  int get correctIndex {
    final a = livingColonies(days, mold: true);
    final b = livingColonies(days, mold: false);
    return a < b ? 0 : (b < a ? 1 : 2);
  }

  @override
  String explanation(int answerIndex) =>
      'A kabında ${livingColonies(days, mold: true)}, B kabında '
      '${livingColonies(days, mold: false)} koloni var. B kabı "kontrol"dür: '
      'küf dışında her şey aynı olduğu için, farkı küfün yarattığını '
      'kanıtlar. Bilim insanları deneylerini hep böyle karşılaştırmalı yapar.';

  @override
  FlemingScene get questionScene =>
      const FlemingScene(station: FlemingStation.petri);

  @override
  FlemingScene resultScene(int answerIndex) =>
      FlemingScene(station: FlemingStation.petri, day: days);
}

// ─────────────────────────── Temizlik ───────────────────────────

class HygieneSetup {
  const HygieneSetup(this.lidOpen, this.hand);

  final bool lidOpen;
  final HandTouch hand;

  int get colonies => hygieneColonies(lidOpen: lidOpen, hand: hand);

  String get label =>
      '${lidOpen ? 'Kapağı açık' : 'Kapağı kapalı'}, ${hand.label.toLowerCase()}';
}

/// Hangi kapta en çok mikrop ürer?
class DirtiestDishTask extends FlemingTask {
  const DirtiestDishTask(this.setups);

  final List<HygieneSetup> setups;

  @override
  FlemingTaskKind get kind => FlemingTaskKind.hygiene;

  @override
  String get title => 'Mikrop avı';

  @override
  String get prompt =>
      'Üç temiz kabı farklı şekilde $hygieneDays gün beklettik. Hangisinde en '
      'çok mikrop kolonisi ürer?';

  @override
  List<String> get options => [for (final s in setups) s.label];

  @override
  int get correctIndex {
    var best = 0;
    for (var i = 1; i < setups.length; i++) {
      if (setups[i].colonies > setups[best].colonies) best = i;
    }
    return best;
  }

  @override
  String explanation(int answerIndex) {
    final list = [for (final s in setups) '${s.label}: ${s.colonies} koloni'].join('; ');
    return '$list. Mikroplar havada ve ellerimizde bulunur; gözle göremeyiz '
        'ama besleyici bir kapta çoğalıp görünür olurlar. Sabunla el yıkamak '
        'mikropların çoğunu uzaklaştırır.';
  }

  @override
  FlemingScene get questionScene => FlemingScene(
    station: FlemingStation.hygiene,
    lidOpen: setups.first.lidOpen,
    hand: setups.first.hand,
  );

  @override
  FlemingScene resultScene(int answerIndex) => FlemingScene(
    station: FlemingStation.hygiene,
    lidOpen: setups[answerIndex].lidOpen,
    hand: setups[answerIndex].hand,
    incubated: true,
  );
}

/// Bu kapta kaç koloni ürer?
class ColonyCountTask extends FlemingTask {
  ColonyCountTask(this.setup, this.choices);

  final HygieneSetup setup;
  final List<int> choices;

  @override
  FlemingTaskKind get kind => FlemingTaskKind.hygiene;

  @override
  String get title => 'Kaç koloni?';

  @override
  String get prompt =>
      'Temiz bir kap: ${setup.label.toLowerCase()}. $hygieneDays gün sonra '
      'yaklaşık kaç mikrop kolonisi görürüz?';

  @override
  List<String> get options => [for (final c in choices) '$c koloni'];

  @override
  int get correctIndex => choices.indexOf(setup.colonies);

  @override
  String explanation(int answerIndex) =>
      '${setup.colonies} koloni üredi. Kapak açıksa havadan $openLidColonies, '
      'yıkanmamış elden ${HandTouch.unwashed.colonies}, yıkanmış elden yalnızca '
      '${HandTouch.washed.colonies} koloni gelir. Kapalı ve dokunulmamış kap '
      'temiz kalır.';

  @override
  FlemingScene get questionScene => FlemingScene(
    station: FlemingStation.hygiene,
    lidOpen: setup.lidOpen,
    hand: setup.hand,
  );

  @override
  FlemingScene resultScene(int answerIndex) => FlemingScene(
    station: FlemingStation.hygiene,
    lidOpen: setup.lidOpen,
    hand: setup.hand,
    incubated: true,
  );
}

// ─────────────────────────── İlaç ───────────────────────────

/// İlacı erken bırakırsa ne olur?
class StopEarlyTask extends FlemingTask {
  const StopEarlyTask(this.stopDay, this.options);

  final int stopDay;

  @override
  final List<String> options;

  static const returns = 'Hastalık geri döner, ilaca dayanıklı bakteriler artar';
  static const healed = 'Tamamen iyileşir, bakteri kalmaz';
  static const same = 'Hiçbir şey değişmez';
  static const optionSet = [returns, healed, same];

  @override
  FlemingTaskKind get kind => FlemingTaskKind.medicine;

  @override
  String get title => 'İlacı bırakmak';

  @override
  String get prompt =>
      'Doktor antibiyotiği $fullCourseDays gün kullanmasını söyledi. Can '
      '$stopDay. gün kendini iyi hissedip ilacı bıraktı. $observedDays. günde '
      'ne olur?';

  @override
  int get correctIndex {
    final start = simulateTreatment(stopDay).first;
    final end = finalPopulation(stopDay);
    if (end.cleared) return options.indexOf(healed);
    return options.indexOf(
      end.resistantShare > start.resistantShare ? returns : same,
    );
  }

  @override
  String explanation(int answerIndex) {
    final start = simulateTreatment(stopDay).first;
    final end = finalPopulation(stopDay);
    return 'İlk başta bakterilerin %${(start.resistantShare * 100).round()}\'i '
        'dayanıklıydı; ilaç erken bırakılınca kalanlar çoğaldı ve '
        '$observedDays. günde %${(end.resistantShare * 100).round()}\'i dayanıklı. '
        'İlaç önce zayıf bakterileri öldürür; kendini iyi hissetmen hepsinin '
        'bittiği anlamına gelmez. Antibiyotiği doktorun söylediği kadar kullan.';
  }

  FlemingScene _scene(double day) => FlemingScene(
    station: FlemingStation.medicine,
    treatmentDays: stopDay,
    medicineDay: day,
  );

  @override
  FlemingScene get questionScene => _scene(0);

  @override
  FlemingScene resultScene(int answerIndex) => _scene(observedDays.toDouble());
}

/// Antibiyotik virüse işe yarar mı?
class VirusTask extends FlemingTask {
  const VirusTask(this.pathogen);

  final Pathogen pathogen;

  static const yes = 'Evet, işe yarar';
  static const no = 'Hayır, işe yaramaz';

  @override
  FlemingTaskKind get kind => FlemingTaskKind.medicine;

  @override
  String get title => 'Antibiyotik ne zaman?';

  @override
  String get prompt =>
      'Hastalığa yol açan mikrop: ${pathogen.label}. Antibiyotik bu hastalığa '
      'işe yarar mı?';

  @override
  List<String> get options => const [yes, no];

  @override
  int get correctIndex => antibioticWorks(pathogen) ? 0 : 1;

  @override
  String explanation(int answerIndex) => antibioticWorks(pathogen)
      ? 'Antibiyotik bakterileri öldürür, bakteri hastalıklarında işe yarar. '
            'Ama ne zaman ve ne kadar kullanılacağına yalnızca doktor karar verir.'
      : 'Antibiyotik yalnızca bakterilere etki eder; grip ve soğuk algınlığı '
            'virüslerle olur, antibiyotik onlara işe yaramaz. Gereksiz '
            'antibiyotik, bakterilerin dayanıklı hâle gelmesine yol açar.';

  @override
  FlemingScene get questionScene => const FlemingScene(
    station: FlemingStation.medicine,
    treatmentDays: fullCourseDays,
  );

  @override
  FlemingScene resultScene(int answerIndex) => const FlemingScene(
    station: FlemingStation.medicine,
    treatmentDays: fullCourseDays,
    medicineDay: 10,
  );
}
