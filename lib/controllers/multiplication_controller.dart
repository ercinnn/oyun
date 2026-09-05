import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/multiplication_difficulty.dart';
import '../models/multiplication_game_phase.dart';
import '../models/multiplication_player_state.dart';
import '../models/multiplication_trial.dart';

/// Her oyuncunun oynadığı tur sayısı. Stroop'un `roundsPerPlayer`,
/// Desen Tamamlama'nın `patternRoundsPerPlayer` gibi sabitleriyle aynı adı
/// kullanmıyoruz: hepsi test/widget_test.dart içinde birlikte import
/// edildiğinde Dart bunu "ambiguous import" hatası sayar.
const int multiplicationRoundsPerPlayer = 8;

/// Izgarada çizilen nesneler. Tamamen kozmetik — hangi emoji seçildiği oyun
/// mantığını hiç etkilemez, sadece her tur farklı görünsün diye var.
const List<String> multiplicationEmojis = [
  '🍎',
  '🍓',
  '⭐',
  '🐞',
  '🎈',
  '🐟',
  '🌸',
  '🍇',
];

/// Çarpım Bahçesi'nin durum makinesi.
///
/// **Bu kontrolcüde hiç Future.delayed yok** — dolayısıyla platformdaki diğer
/// tur tabanlı oyunların (`StroopController`, `PatternController`,
/// `SimonController`) 350 ms'lik geri bildirim parlamasını koruyan
/// `_generation`/`_resolving` çiftine de gerek yok. Cevaptan sonra tur kendi
/// kendine ilerlemez: [showingExplanation] true olur, açıklama paneli ekranda
/// kalır ve oyuncu "Devam"a basana kadar ([continueAfterExplanation]) hiçbir
/// şey değişmez. Bu bilinçli bir sapma — oyunun asıl öğretici parçası o panel
/// ve onu okumak zaman ister; bir zamanlayıcı bu zamanı çocuğun elinden alırdı.
/// Aynı gerekçeyle tamamen senkron olan bir başka kontrolcü için bkz.
/// `PuzzleController`.
class MultiplicationController extends ChangeNotifier {
  MultiplicationController({Random? random}) : _rng = random ?? Random();

  MultiplicationGamePhase phase = MultiplicationGamePhase.setup;
  List<MultiplicationPlayerState> players = [];
  int currentPlayerIndex = 0;
  MultiplicationDifficulty difficulty = MultiplicationDifficulty.orta;
  late MultiplicationTrial currentTrial;

  /// Kurma turunda oyuncunun o an kurmuş olduğu ızgaranın boyutu.
  int buildRows = 1;
  int buildColumns = 1;

  /// Cevap verildikten sonra açıklama paneli gösterilirken true.
  bool showingExplanation = false;

  /// Açıklama panelini besleyen son cevap bilgileri.
  bool lastAnswerCorrect = false;
  bool lastAnswerCommuted = false;
  int lastGivenValue = 0;

  final Random _rng;

  MultiplicationPlayerState get currentPlayer => players[currentPlayerIndex];

  /// Kurma turunda o an kurulmuş ızgaranın toplam nesne sayısı.
  int get buildValue => buildRows * buildColumns;

  List<MultiplicationPlayerState> get rankedByCorrect {
    final sorted = List<MultiplicationPlayerState>.from(players);
    sorted.sort((a, b) => b.correctCount.compareTo(a.correctCount));
    return sorted;
  }

  void startGame(
    List<String> names, {
    required MultiplicationDifficulty difficulty,
  }) {
    this.difficulty = difficulty;
    players = names
        .map((name) => MultiplicationPlayerState(name: name))
        .toList();
    currentPlayerIndex = 0;
    showingExplanation = false;
    lastAnswerCorrect = false;
    lastAnswerCommuted = false;
    lastGivenValue = 0;
    currentTrial = _generateTrial();
    _resetBuild();
    phase = MultiplicationGamePhase.playing;
    notifyListeners();
  }

  /// Okuma turunda bir seçeneğe basıldı.
  void answerArray(int selected) {
    if (phase != MultiplicationGamePhase.playing) return;
    if (showingExplanation) return;
    if (currentTrial.kind != MultiplicationTrialKind.array) return;

    _recordAnswer(correct: selected == currentTrial.answer, given: selected);
  }

  void adjustBuildRows(int delta) => _adjustBuild(rowDelta: delta);

  void adjustBuildColumns(int delta) => _adjustBuild(columnDelta: delta);

  /// Kurma turunda "Onayla"ya basıldı.
  void submitBuild() {
    if (phase != MultiplicationGamePhase.playing) return;
    if (showingExplanation) return;
    if (currentTrial.kind != MultiplicationTrialKind.build) return;

    final exact =
        buildRows == currentTrial.rows && buildColumns == currentTrial.columns;
    // Değişme özelliği kasıtlı olarak doğru sayılır: 3 × 4 istenirken 4 × 3
    // kurmak matematiksel olarak doğrudur. Bunu yanlış saymak hem haksız
    // olurdu hem de öğretilecek asıl şeyi — çarpmada sıra değişse de sonuç
    // değişmez — kaçırırdı. Açıklama paneli bunu bir ders olarak kullanıyor.
    final commuted =
        !exact &&
        buildRows == currentTrial.columns &&
        buildColumns == currentTrial.rows;

    _recordAnswer(
      correct: exact || commuted,
      given: buildValue,
      commuted: commuted,
    );
  }

  /// Açıklama panelindeki "Devam"a basıldı: sıradaki tura, sıra devrine ya da
  /// sonuç ekranına geçilir.
  void continueAfterExplanation() {
    if (!showingExplanation) return;
    showingExplanation = false;

    if (currentPlayer.roundsPlayed >= multiplicationRoundsPerPlayer) {
      final nextIndex = _findNextUnfinishedPlayerIndex();
      if (nextIndex == null) {
        phase = MultiplicationGamePhase.finished;
        notifyListeners();
        return;
      }
      currentPlayerIndex = nextIndex;
      phase = MultiplicationGamePhase.turnTransition;
    }

    currentTrial = _generateTrial();
    _resetBuild();
    notifyListeners();
  }

  void acknowledgeTurnTransition() {
    phase = MultiplicationGamePhase.playing;
    notifyListeners();
  }

  void restart() {
    players = [];
    currentPlayerIndex = 0;
    showingExplanation = false;
    lastAnswerCorrect = false;
    lastAnswerCommuted = false;
    lastGivenValue = 0;
    _resetBuild();
    phase = MultiplicationGamePhase.setup;
    notifyListeners();
  }

  void _adjustBuild({int rowDelta = 0, int columnDelta = 0}) {
    if (showingExplanation) return;
    final max = difficulty.buildMaxFactor;
    buildRows = (buildRows + rowDelta).clamp(1, max);
    buildColumns = (buildColumns + columnDelta).clamp(1, max);
    notifyListeners();
  }

  void _resetBuild() {
    buildRows = 1;
    buildColumns = 1;
  }

  void _recordAnswer({
    required bool correct,
    required int given,
    bool commuted = false,
  }) {
    lastAnswerCorrect = correct;
    lastAnswerCommuted = commuted;
    lastGivenValue = given;
    if (correct) currentPlayer.correctCount++;
    currentPlayer.roundsPlayed++;
    showingExplanation = true;
    notifyListeners();
  }

  MultiplicationTrial _generateTrial() {
    // Tur tipi rastgele değil, dönüşümlü: 1./3./5./7. tur okuma, 2./4./6./8.
    // tur kurma. Böylece her oyuncu iki tipten de dörder tane görür.
    final kind = currentPlayer.roundsPlayed.isEven
        ? MultiplicationTrialKind.array
        : MultiplicationTrialKind.build;
    final maxFactor = kind == MultiplicationTrialKind.array
        ? difficulty.arrayMaxFactor
        : difficulty.buildMaxFactor;

    final rows = _factor(maxFactor);
    final columns = _factor(maxFactor);

    return MultiplicationTrial(
      kind: kind,
      rows: rows,
      columns: columns,
      emoji: multiplicationEmojis[_rng.nextInt(multiplicationEmojis.length)],
      options: kind == MultiplicationTrialKind.array
          ? _generateOptions(rows, columns)
          : const [],
    );
  }

  int _factor(int maxFactor) =>
      MultiplicationDifficulty.minFactor +
      _rng.nextInt(maxFactor - MultiplicationDifficulty.minFactor + 1);

  /// Okuma turunun 4 seçeneği: doğru cevap + 3 çeldirici.
  ///
  /// Çeldiriciler rastgele sayılar değil, çocukların gerçekten yaptığı
  /// hatalar: bir sıra eksik/fazla saymak (`answer ± columns`), bir sütun
  /// kaçırmak (`answer ± rows`), çarpmak yerine toplamak (`rows + columns`)
  /// ve komşu bir sayıya kaymak (`answer ± 1`). Çarpanların ikisi de en az 2
  /// olduğu için bu listede her zaman en az üç geçerli (pozitif ve cevaptan
  /// farklı) aday bulunur; ayrıca bir tamamlama döngüsüne gerek yok.
  List<int> _generateOptions(int rows, int columns) {
    final answer = rows * columns;
    final candidates = <int>[
      answer - columns,
      answer + columns,
      answer - rows,
      answer + rows,
      rows + columns,
      answer - 1,
      answer + 1,
    ]..shuffle(_rng);

    final wrong = <int>{};
    for (final candidate in candidates) {
      if (wrong.length == 3) break;
      if (candidate > 0 && candidate != answer) wrong.add(candidate);
    }

    return [answer, ...wrong]..shuffle(_rng);
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (currentPlayerIndex + offset) % players.length;
      if (players[index].roundsPlayed < multiplicationRoundsPerPlayer) {
        return index;
      }
    }
    return null;
  }
}
