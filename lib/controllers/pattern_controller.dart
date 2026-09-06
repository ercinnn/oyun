import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/pattern_difficulty.dart';
import '../models/pattern_game_phase.dart';
import '../models/pattern_player_state.dart';
import '../models/pattern_trial.dart';

/// Her oyuncunun oynadığı tur sayısı. Stroop'un `roundsPerPlayer` sabitiyle
/// aynı adı kullanmıyoruz: ikisi de test/widget_test.dart içinde birlikte
/// import edildiğinde Dart bunu "ambiguous import" hatası sayar.
const int patternRoundsPerPlayer = 8;

class PatternController extends ChangeNotifier {
  PatternController({Random? random}) : _rng = random ?? Random();

  PatternGamePhase phase = PatternGamePhase.setup;
  List<PatternPlayerState> players = [];
  int currentPlayerIndex = 0;
  PatternDifficulty difficulty = PatternDifficulty.orta;
  late PatternTrial currentTrial;

  /// Son cevabın doğru/yanlış olduğunu kısa bir geri bildirim penceresi
  /// boyunca tutar; hiçbir geri bildirim gösterilmeyecekse null'dır.
  bool? lastAnswerCorrect;

  bool _resolving = false;
  // startGame/restart her çağrıldığında artar; bekleyen bir geri bildirim
  // gecikmesi tamamlandığında hâlâ aynı oyunda olduğumuzu doğrulamak için
  // kullanılır (aksi halde yeniden başlatılmış bir oyunun state'ini bozabilir).
  int _generation = 0;
  final Random _rng;

  PatternPlayerState get currentPlayer => players[currentPlayerIndex];

  List<PatternPlayerState> get rankedByCorrect {
    final sorted = List<PatternPlayerState>.from(players);
    sorted.sort((a, b) => b.correctCount.compareTo(a.correctCount));
    return sorted;
  }

  PatternTrial _generateTrial() {
    final terms = switch (difficulty) {
      PatternDifficulty.kolay => _generateKolayTerms(),
      PatternDifficulty.orta => _generateOrtaTerms(),
      PatternDifficulty.zor => _generateZorTerms(),
    };

    final answer = terms.last;
    final shown = terms.sublist(0, 4);
    // Ekranda görünen ilk iki terimden türetilir — yön (artan/azalan) fark
    // etmeksizin her zaman doğru işaretli, pozitif bir "sayılar ne kadar
    // aralıklı" ölçüsü verir. Orta için bu, eski kodun step.abs() /
    // terms[1]-terms[0] hesaplarıyla birebir aynı sonucu üretir.
    final spacing = (shown[1] - shown[0]).abs();

    // Yanlış şıklar: doğru cevaptan da, ekranda zaten görünen dört terimden
    // de farklı, pozitif adaylar arasından seçilir. `spacing` her dalda en
    // az 1 ve cevap her dalda en az 4-5 olduğu için aday havuzu hep yeterince
    // geniştir; sonsuz döngü riski yok.
    final wrongOptions = <int>{};
    while (wrongOptions.length < 3) {
      final magnitude = 1 + _rng.nextInt(spacing.clamp(1, 20) + 3);
      final offset = _rng.nextBool() ? magnitude : -magnitude;
      final candidate = answer + offset;
      if (candidate > 0 && candidate != answer && !shown.contains(candidate)) {
        wrongOptions.add(candidate);
      }
    }

    final options = [answer, ...wrongOptions]..shuffle(_rng);
    return PatternTrial(sequence: shown, answer: answer, options: options);
  }

  /// **Kolay**: çarpım tablosunu pekiştirir. Adım her zaman 2-9 arası bir
  /// tablo sayısı, dizinin kendisi o tablonun ardışık katları (7,14,21,? → 7
  /// tablosu; 42,49,56,? → yine 7 tablosu ama 6. kattan başlıyor). Üst sınır
  /// (çarpan ≤ 7) en büyük terimi (11 × 9 =) 99'un altında tutar.
  List<int> _generateKolayTerms() {
    final step = 2 + _rng.nextInt(8); // 2..9
    final startMultiplier = 1 + _rng.nextInt(7); // 1..7
    return List.generate(5, (i) => (startMultiplier + i) * step);
  }

  /// **Orta**: oyunun zorluk seviyesi eklenmeden önceki tek hâli, birebir
  /// aynı — davranış hiç değişmedi, sadece üç seçenekten biri oldu.
  List<int> _generateOrtaTerms() {
    final arithmetic = _rng.nextBool();
    if (arithmetic) {
      final ascending = _rng.nextBool();
      late int start;
      late int step;
      if (ascending) {
        start = 1 + _rng.nextInt(20); // 1..20
        step = 1 + _rng.nextInt(5); // 1..5
      } else {
        // Terimler her zaman pozitif kalsın diye yüksek bir başlangıçtan
        // azalır: min terim = 25 + 4*(-5) = 5.
        start = 25 + _rng.nextInt(26); // 25..50
        step = -(1 + _rng.nextInt(5)); // -1..-5
      }
      return List.generate(5, (i) => start + i * step);
    }
    final start = 1 + _rng.nextInt(4); // 1..4
    final ratio = 2 + _rng.nextInt(2); // 2..3
    return List.generate(5, (i) => start * pow(ratio, i).toInt());
  }

  /// **Zor**: Orta'nın aynı iki kural tipini (aritmetik, geometrik) daha
  /// büyük aralıklarla kullanır, artı dördüncü bir dal: azalan geometrik,
  /// yani "bölen" dizi (1280, 320, 80, 20, ? → 5). Bunun için ayrı bir üretim
  /// yazmak yerine artan geometrik diziyi tersine çeviriyoruz — pozitiflik ve
  /// tam sayılık zaten üretimden geliyor.
  List<int> _generateZorTerms() {
    final arithmetic = _rng.nextBool();
    if (arithmetic) {
      final ascending = _rng.nextBool();
      late int start;
      late int step;
      if (ascending) {
        start = 1 + _rng.nextInt(40); // 1..40
        step = 2 + _rng.nextInt(8); // 2..9
      } else {
        // min terim = start - 4*9 ≥ 60-36 = 24 > 0.
        start = 60 + _rng.nextInt(61); // 60..120
        step = -(2 + _rng.nextInt(8)); // -2..-9
      }
      return List.generate(5, (i) => start + i * step);
    }
    final start = 1 + _rng.nextInt(6); // 1..6
    final ratio = 2 + _rng.nextInt(3); // 2..4
    final ascending = _rng.nextBool();
    final growth = List.generate(5, (i) => start * pow(ratio, i).toInt());
    return ascending ? growth : growth.reversed.toList();
  }

  void startGame(List<String> names, {required PatternDifficulty difficulty}) {
    this.difficulty = difficulty;
    _generation++;
    players = names.map((name) => PatternPlayerState(name: name)).toList();
    currentPlayerIndex = 0;
    currentTrial = _generateTrial();
    lastAnswerCorrect = null;
    _resolving = false;
    phase = PatternGamePhase.playing;
    notifyListeners();
  }

  Future<void> answer(int selected) async {
    if (phase != PatternGamePhase.playing) return;
    if (_resolving) return;
    _resolving = true;
    final generation = _generation;

    final correct = selected == currentTrial.answer;
    lastAnswerCorrect = correct;
    if (correct) currentPlayer.correctCount++;
    currentPlayer.roundsPlayed++;
    notifyListeners();

    // Oyuncunun doğru/yanlış geri bildirimini görebilmesi için kısa bir
    // duraklama, ardından bir sonraki tura geçilir.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (generation != _generation) return;

    lastAnswerCorrect = null;

    if (currentPlayer.roundsPlayed >= patternRoundsPerPlayer) {
      final nextIndex = _findNextUnfinishedPlayerIndex();
      if (nextIndex == null) {
        phase = PatternGamePhase.finished;
      } else {
        currentPlayerIndex = nextIndex;
        currentTrial = _generateTrial();
        phase = PatternGamePhase.turnTransition;
      }
    } else {
      currentTrial = _generateTrial();
    }
    _resolving = false;
    notifyListeners();
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (currentPlayerIndex + offset) % players.length;
      if (players[index].roundsPlayed < patternRoundsPerPlayer) return index;
    }
    return null;
  }

  void acknowledgeTurnTransition() {
    phase = PatternGamePhase.playing;
    notifyListeners();
  }

  void restart() {
    _generation++;
    players = [];
    currentPlayerIndex = 0;
    lastAnswerCorrect = null;
    _resolving = false;
    phase = PatternGamePhase.setup;
    notifyListeners();
  }
}
