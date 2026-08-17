import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/memory_card.dart';
import '../models/memory_category.dart';
import '../models/memory_game_phase.dart';
import '../models/memory_player_state.dart';
import '../services/speech_service.dart';

const int gridColumns = 4;
const int gridRows = 4;
const int pairCount = (gridColumns * gridRows) ~/ 2;

/// Meyve kategorisi: her sembol için Türkçe/İngilizce adı. Bir çiftin iki
/// kartından biri [tr]'yi, diğeri [en]'i etiket olarak alır (bkz.
/// [MemoryMatchController.startGame]).
const Map<String, ({String tr, String en})> _fruitNames = {
  '🍎': (tr: 'Elma', en: 'Apple'),
  '🍌': (tr: 'Muz', en: 'Banana'),
  '🍇': (tr: 'Üzüm', en: 'Grapes'),
  '🍉': (tr: 'Karpuz', en: 'Watermelon'),
  '🍒': (tr: 'Kiraz', en: 'Cherries'),
  '🍋': (tr: 'Limon', en: 'Lemon'),
  '🥝': (tr: 'Kivi', en: 'Kiwi'),
  '🍑': (tr: 'Şeftali', en: 'Peach'),
  '🍍': (tr: 'Ananas', en: 'Pineapple'),
  '🍓': (tr: 'Çilek', en: 'Strawberry'),
  '🍈': (tr: 'Kavun', en: 'Melon'),
  '🥥': (tr: 'Hindistan Cevizi', en: 'Coconut'),
};

/// Taşıt kategorisi. Tam olarak [pairCount] kadar (8) sembol içerir, bu
/// yüzden meyvelerin aksine rastgele bir alt küme seçilmez, hepsi kullanılır.
const Map<String, ({String tr, String en})> _vehicleNames = {
  '🚗': (tr: 'Araba', en: 'Car'),
  '🚌': (tr: 'Otobüs', en: 'Bus'),
  '🚢': (tr: 'Gemi', en: 'Ship'),
  '🏍️': (tr: 'Motosiklet', en: 'Motorcycle'),
  '🚚': (tr: 'Kamyon', en: 'Truck'),
  '🚆': (tr: 'Tren', en: 'Train'),
  '✈️': (tr: 'Uçak', en: 'Airplane'),
  '🚲': (tr: 'Bisiklet', en: 'Bicycle'),
};

Map<String, ({String tr, String en})> _namesFor(MemoryCategory category) {
  switch (category) {
    case MemoryCategory.fruits:
      return _fruitNames;
    case MemoryCategory.vehicles:
      return _vehicleNames;
  }
}

class MemoryMatchController extends ChangeNotifier {
  MemoryMatchController({required SpeechService speechService})
    : _speechService = speechService;

  final SpeechService _speechService;

  MemoryGamePhase phase = MemoryGamePhase.setup;
  List<MemoryPlayerState> players = [];
  List<MemoryCard> cards = [];
  int currentPlayerIndex = 0;

  final List<int> _faceUpIndices = [];
  bool _resolving = false;
  // startGame/restart her çağrıldığında artar; bekleyen bir eşleşme/eşleşmeme
  // gecikmesi tamamlandığında hâlâ aynı oyunda olduğumuzu doğrulamak için
  // kullanılır (aksi halde yeniden başlatılmış bir oyunun state'ini bozabilir).
  int _generation = 0;

  MemoryPlayerState get currentPlayer => players[currentPlayerIndex];

  bool get isResolving => _resolving;

  List<MemoryPlayerState> get rankedByMatches {
    final sorted = List<MemoryPlayerState>.from(players);
    sorted.sort((a, b) => b.matchedPairs.compareTo(a.matchedPairs));
    return sorted;
  }

  void startGame(List<String> names, {required MemoryCategory category}) {
    _generation++;
    final rng = Random();
    final symbolNames = _namesFor(category);
    final symbols = (symbolNames.keys.toList()..shuffle(rng))
        .take(pairCount)
        .toList();
    final freshCards = <MemoryCard>[];
    var id = 0;
    for (final symbol in symbols) {
      final names = symbolNames[symbol]!;
      freshCards.add(
        MemoryCard(
          id: id++,
          symbol: symbol,
          label: names.tr,
          languageCode: 'tr-TR',
        ),
      );
      freshCards.add(
        MemoryCard(
          id: id++,
          symbol: symbol,
          label: names.en,
          languageCode: 'en-US',
        ),
      );
    }
    freshCards.shuffle(rng);

    players = names.map((name) => MemoryPlayerState(name: name)).toList();
    cards = freshCards;
    currentPlayerIndex = 0;
    _faceUpIndices.clear();
    _resolving = false;
    phase = MemoryGamePhase.playing;
    notifyListeners();
  }

  Future<void> flipCard(int index) async {
    if (phase != MemoryGamePhase.playing) return;
    if (_resolving) return;
    final card = cards[index];
    if (card.isFaceUp || card.isMatched) return;

    card.isFaceUp = true;
    _faceUpIndices.add(index);
    notifyListeners();

    if (_faceUpIndices.length < 2) return;

    _resolving = true;
    final generation = _generation;
    final first = cards[_faceUpIndices[0]];
    final second = cards[_faceUpIndices[1]];

    if (first.symbol == second.symbol) {
      // Eşleşme: kısa bir gösterimin ardından kartlar kilitlenir; oyuncu
      // sırayı bırakmadan devam eder (hafıza oyunlarının standart kuralı).
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (generation != _generation) return;
      first.isMatched = true;
      second.isMatched = true;
      currentPlayer.matchedPairs++;
      _faceUpIndices.clear();
      _resolving = false;
      if (cards.every((c) => c.isMatched)) {
        phase = MemoryGamePhase.finished;
      }
      notifyListeners();
    } else {
      // Eşleşmeme: her iki oyuncunun da kartları görebilmesi için kısa bir
      // süre açık bırakılır, sonra kapanır ve sıra diğer oyuncuya geçer.
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (generation != _generation) return;
      first.isFaceUp = false;
      second.isFaceUp = false;
      _faceUpIndices.clear();
      _resolving = false;
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      notifyListeners();
    }
  }

  /// Bulunmuş (eşleşmiş) bir karta tıklanınca etiketini seslendirir. Oyun
  /// durumunu hiç değiştirmez — [flipCard]'ın aksine sadece geri bildirim
  /// amaçlıdır.
  void pronounce(int index) {
    final card = cards[index];
    if (!card.isMatched) return;
    unawaited(
      _speechService.speak(card.label, languageCode: card.languageCode),
    );
  }

  @override
  void dispose() {
    unawaited(_speechService.dispose());
    super.dispose();
  }

  void restart() {
    _generation++;
    players = [];
    cards = [];
    currentPlayerIndex = 0;
    _faceUpIndices.clear();
    _resolving = false;
    phase = MemoryGamePhase.setup;
    notifyListeners();
  }
}
