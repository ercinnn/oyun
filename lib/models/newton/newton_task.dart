import '../science/science_task.dart';
import 'cart.dart';
import 'falling.dart';
import 'newton_scene.dart';
import 'prism.dart';

/// Görev türleri; oyuncunun turları bu sırayla dönüşümlü gelir.
enum NewtonTaskKind { fall, prism, cart }

/// Newton görevleri: ortak [ScienceTask]'a ek olarak deneyin sorudan önceki
/// ve cevaptan sonraki sahnesini verir.
sealed class NewtonTask extends ScienceTask {
  const NewtonTask();

  NewtonTaskKind get kind;
  NewtonScene get questionScene;
  NewtonScene resultScene(int answerIndex);
}

// ─────────────────────────── Düşme ───────────────────────────

/// "Hangisi önce yere değer?"
class FallTask extends NewtonTask {
  const FallTask(this.a, this.b, this.environment);

  final FallingObject a;
  final FallingObject b;
  final FallEnvironment environment;

  @override
  NewtonTaskKind get kind => NewtonTaskKind.fall;

  @override
  String? get hint => 'A soldaki kancada, B sağdaki kancada.';

  @override
  String get title => 'Hangisi önce düşer?';

  String get _where => switch (environment) {
    FallEnvironment.air => 'Deney Dünya\'da, havada yapılıyor.',
    FallEnvironment.vacuum =>
      'Kulenin çevresindeki tüpün havasını pompayla boşalttık.',
    FallEnvironment.moon => 'Deney Ay\'da yapılıyor; Ay\'da hava yoktur.',
  };

  @override
  String get prompt =>
      'Kule ${formatTr(towerHeightM)} metre. $_where A: ${a.emoji} ${a.name} '
      've B: ${b.emoji} ${b.name} aynı anda bırakılıyor. Hangisi önce yere '
      'değer?';

  @override
  List<String> get options => const ['A önce', 'B önce', 'Aynı anda'];

  @override
  int get correctIndex => fallWinner(a, b, environment);

  @override
  String explanation(int answerIndex) {
    final ta = formatTr(fallTime(a, environment));
    final tb = formatTr(fallTime(b, environment));
    final times = 'A $ta saniyede, B $tb saniyede yere değdi. ';
    if (!environment.hasAir) {
      return '${times}Hava olmayınca her şey aynı hızla düşer: Dünya da Ay da '
          'hafif ve ağır her cismi aynı ivmeyle çeker. 1971\'de astronot '
          'David Scott Ay\'da bir çekiçle bir tüyü bıraktı; ikisi aynı anda '
          'yere değdi!';
    }
    if (correctIndex == 2) {
      final heavy = a.massG >= b.massG ? a : b;
      return '$times${heavy.note}';
    }
    final slow = correctIndex == 0 ? b : a;
    return '${times}Aradaki farkı yapan ağırlık değil, hava. ${slow.note}';
  }

  @override
  NewtonScene get questionScene => NewtonScene(
    station: NewtonStation.fall,
    fallA: a,
    fallB: b,
    environment: environment,
  );

  @override
  NewtonScene resultScene(int answerIndex) => NewtonScene(
    station: NewtonStation.fall,
    fallA: a,
    fallB: b,
    environment: environment,
    run: 1,
  );
}

// ─────────────────────────── Prizma ───────────────────────────

enum PrismQuestion { whiteSplits, mostBent, onlyRed, recombine }

/// Prizma soruları. Seçenek sırası üretimde karıştırılır ([options]); doğru
/// seçenek **modelden** ([prismOutcome], [deviationDeg]) bulunur.
class PrismTask extends NewtonTask {
  PrismTask(this.question, this.options, {this.colorChoices = const []});

  final PrismQuestion question;

  @override
  final List<String> options;

  /// [PrismQuestion.mostBent] için seçenekteki renkler (options ile aynı
  /// sırada).
  final List<SpectrumColor> colorChoices;

  static const rainbow = 'Gökkuşağı renkleri';
  static const whiteSpot = 'Beyaz bir ışık lekesi';
  static const nothing = 'Hiçbir şey, ışık prizmada kaybolur';
  static const onlyRedText = 'Yalnızca kırmızı';
  static const recombinedWhite = 'Yeniden beyaz ışık olur';
  static const spreadMore = 'Renkler daha da çok açılır';
  static const goesDark = 'Işık söner';

  /// Soru için seçenek kümesi (karıştırılmamış).
  static List<String> optionSet(PrismQuestion q) => switch (q) {
    PrismQuestion.whiteSplits => const [whiteSpot, rainbow, nothing],
    PrismQuestion.onlyRed => const [rainbow, onlyRedText, whiteSpot],
    PrismQuestion.recombine => const [spreadMore, recombinedWhite, goesDark],
    PrismQuestion.mostBent => const [],
  };

  @override
  NewtonTaskKind get kind => NewtonTaskKind.prism;

  @override
  String get title => 'Newton\'un prizması';

  LightSource get _light =>
      question == PrismQuestion.onlyRed ? LightSource.red : LightSource.white;

  bool get _secondPrism => question == PrismQuestion.recombine;

  @override
  String get prompt => switch (question) {
    PrismQuestion.whiteSplits =>
      'Newton karanlık odasında, perdedeki küçük bir delikten gelen beyaz '
          'güneş ışığını cam bir prizmadan geçirdi. Karşı duvarda ne gördü?',
    PrismQuestion.mostBent =>
      'Prizma her rengi biraz farklı büker. Bu üç renkten hangisi yolundan '
          'en çok sapar (en çok bükülür)?',
    PrismQuestion.onlyRed =>
      'Lambanın önüne kırmızı bir cam koyduk: prizmaya yalnızca kırmızı ışık '
          'giriyor. Duvarda ne görürüz?',
    PrismQuestion.recombine =>
      'Prizmadan çıkan renklerin önüne ikinci bir prizmayı ters çevirip '
          'koyuyoruz. Ne olur?',
  };

  @override
  int get correctIndex {
    final outcome = prismOutcome(_light, secondPrism: _secondPrism);
    return switch (question) {
      PrismQuestion.mostBent => _mostBentIndex,
      PrismQuestion.recombine => options.indexOf(
        outcome.isWhite ? recombinedWhite : spreadMore,
      ),
      _ => options.indexOf(
        outcome.isRainbow
            ? rainbow
            : outcome.colors.length == 1
            ? onlyRedText
            : whiteSpot,
      ),
    };
  }

  int get _mostBentIndex {
    var best = 0;
    for (var i = 1; i < colorChoices.length; i++) {
      if (deviationDeg(colorChoices[i]) > deviationDeg(colorChoices[best])) {
        best = i;
      }
    }
    return best;
  }

  @override
  String explanation(int answerIndex) => switch (question) {
    PrismQuestion.whiteSplits =>
      'Beyaz ışık aslında renklerin karışımıdır! Prizma her rengi farklı '
          'büktüğü için renkler yelpaze gibi açılır: kırmızı, turuncu, sarı, '
          'yeşil, mavi, lacivert, mor. Gökkuşağı da yağmur damlalarının '
          'güneş ışığını böyle ayırmasıyla oluşur.',
    PrismQuestion.mostBent =>
      '${colorChoices.map((c) => '${c.name} ${formatTr(deviationDeg(c))}°').join(', ')}. '
          'Mor en çok, kırmızı en az bükülür; bu yüzden gökkuşağında kırmızı '
          'bir kenarda, mor öbür kenardadır.',
    PrismQuestion.onlyRed =>
      'Yalnızca kırmızı çıktı! Prizma renk üretmez, beyaz ışığın içinde zaten '
          'olan renkleri birbirinden ayırır. Tek bir rengi ayıracak başka bir '
          'şey yoktur. Newton buna "belirleyici deney" dedi.',
    PrismQuestion.recombine =>
      'Ters prizma renkleri geri büker ve hepsi yeniden üst üste gelir: '
          'duvarda yine beyaz ışık görünür. Renkler birleşince beyaz olur!',
  };

  @override
  NewtonScene get questionScene => NewtonScene(
    station: NewtonStation.prism,
    light: _light,
    secondPrism: _secondPrism,
  );

  @override
  NewtonScene resultScene(int answerIndex) => NewtonScene(
    station: NewtonStation.prism,
    light: _light,
    secondPrism: _secondPrism,
    run: 1,
  );
}

// ─────────────────────────── Araba ───────────────────────────

enum CartQuestion { load, surface }

/// Aynı yayla itilen iki arabadan hangisi daha uzağa gider?
class CartTask extends NewtonTask {
  const CartTask(this.question, this.laneA, this.laneB, this.push);

  final CartQuestion question;
  final CartLane laneA;
  final CartLane laneB;
  final PushStrength push;

  @override
  String? get hint => 'A arkadaki pistte, B öndeki pistte.';

  /// Bu farktan küçük yollar "aynı" sayılır (m).
  static const sameDistanceM = 0.2;

  @override
  NewtonTaskKind get kind => NewtonTaskKind.cart;

  @override
  String get title => 'Aynı itme, farklı yol';

  String _describe(CartLane lane) =>
      '${lane.surface.label} zeminde, ${lane.boxes == 0 ? 'boş' : '${lane.boxes} kutu yüklü'}';

  @override
  String get prompt =>
      'İki araba da aynı yayla, aynı kuvvetle itiliyor. A arabası '
      '${_describe(laneA)}; B arabası ${_describe(laneB)}. Hangisi daha '
      'uzağa gider?';

  @override
  List<String> get options => const ['A arabası', 'B arabası', 'İkisi aynı'];

  @override
  int get correctIndex {
    final da = cartDistance(laneA, push);
    final db = cartDistance(laneB, push);
    if ((da - db).abs() < sameDistanceM) return 2;
    return da > db ? 0 : 1;
  }

  @override
  String explanation(int answerIndex) {
    final da = formatTr(cartDistance(laneA, push));
    final db = formatTr(cartDistance(laneB, push));
    final distances = 'A arabası $da metre, B arabası $db metre gitti. ';
    return switch (question) {
      CartQuestion.load =>
        '${distances}Aynı itme, ağır arabayı daha az hızlandırır: kütle arttıkça '
            'hızlanmak zorlaşır. Bu, Newton\'un 2. hareket yasasıdır.',
      CartQuestion.surface =>
        '${distances}Arabayı durduran sürtünmedir. Buzda sürtünme çok az olduğu '
            'için araba neredeyse durmadan gider. Hiçbir şey durdurmasa '
            'sonsuza kadar giderdi: Newton\'un 1. yasası (eylemsizlik).',
    };
  }

  NewtonScene _scene(int run) => NewtonScene(
    station: NewtonStation.cart,
    laneA: laneA,
    laneB: laneB,
    push: push,
    run: run,
  );

  @override
  NewtonScene get questionScene => _scene(0);

  @override
  NewtonScene resultScene(int answerIndex) => _scene(1);
}
