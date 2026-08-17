import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bombali_sayilar/controllers/game_controller.dart';
import 'package:bombali_sayilar/controllers/memory_match_controller.dart';
import 'package:bombali_sayilar/controllers/pattern_controller.dart';
import 'package:bombali_sayilar/controllers/sequence_memory_controller.dart';
import 'package:bombali_sayilar/controllers/stroop_controller.dart';
import 'package:bombali_sayilar/controllers/theme_controller.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/color_theme.dart';
import 'package:bombali_sayilar/models/player_state.dart';
import 'package:bombali_sayilar/models/sequence_tile_color.dart';
import 'package:bombali_sayilar/screens/game_screen.dart';
import 'package:bombali_sayilar/screens/memory_game_screen.dart';
import 'package:bombali_sayilar/screens/game_catalog_screen.dart';
import 'package:bombali_sayilar/screens/pattern_game_screen.dart';
import 'package:bombali_sayilar/screens/sequence_memory_game_screen.dart';
import 'package:bombali_sayilar/screens/setup_screen.dart';
import 'package:bombali_sayilar/screens/stroop_game_screen.dart';
import 'package:bombali_sayilar/widgets/memory_card_widget.dart';
import 'package:bombali_sayilar/widgets/star_rating.dart';

/// Platform ana menüsünden Bombalı Sayılar oyununa girer.
Future<void> _openBombaliSayilar(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Bombalı Sayılar'));
  await tester.pumpAndSettle();
}

/// Platform ana menüsünden Kart Eşleştirme oyununa girer.
Future<void> _openMemoryMatch(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Kart Eşleştirme'));
  await tester.pumpAndSettle();
}

/// Platform ana menüsünden Renk mi Kelime mi? oyununa girer.
Future<void> _openStroop(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Renk mi Kelime mi?'));
  await tester.pumpAndSettle();
}

/// Stroop kontrolcüsündeki güncel turun doğru cevabına (mürekkep rengine)
/// karşılık gelen renk butonuna basar ve geri bildirim gecikmesinin
/// geçmesini bekler.
Future<void> _answerCorrectly(
  WidgetTester tester,
  StroopController controller,
) async {
  final correct = controller.currentTrial.ink;
  await tester.tap(find.byKey(ValueKey(correct)));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Platform ana menüsünden Dizi Hafızası oyununa girer.
Future<void> _openSequenceMemory(WidgetTester tester) async {
  // Katalog kartları artık bir beceri yıldız tablosu da içerdiğinden
  // ListView'in lazy build cache'i "Dizi Hafızası" kartını (4.) henüz
  // kurmayabilir; tüm liste görünür olsun diye görünümü uzatıyoruz.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Dizi Hafızası'));
  await tester.pumpAndSettle();
}

// SequenceMemoryController'daki otomatik oynatım gecikmeleri kütüphane
// içi (private) olduğundan, Stroop/Kart Eşleştirme testlerinin de yaptığı
// gibi burada kendi kopyaları tutulur.
const _seqPreRoundDelay = Duration(milliseconds: 600);
const _seqLitDuration = Duration(milliseconds: 500);
const _seqGapDuration = Duration(milliseconds: 200);
const _seqCorrectExtendDelay = Duration(milliseconds: 400);
const _seqWrongFlashDuration = Duration(milliseconds: 500);

Duration _seqPlaybackDuration(int length) =>
    _seqPreRoundDelay + (_seqLitDuration + _seqGapDuration) * length;

/// Mevcut diziyi baştan sona doğru sırayla tıklar; önce otomatik
/// oynatımın bitmesini bekler.
Future<void> _tapCurrentSequenceCorrectly(
  WidgetTester tester,
  SequenceMemoryController controller,
) async {
  await tester.pump(_seqPlaybackDuration(controller.sequence.length));
  for (final tile in controller.sequence) {
    await tester.tap(find.byKey(ValueKey(tile)));
    await tester.pump();
  }
}

/// Platform ana menüsünden Desen Tamamlama oyununa girer. Katalog listesi
/// 5 karta çıktığı için (bkz. "Game catalog shows the available games")
/// son kartın ListView'in lazy build cache'i dışında kalmaması için
/// görünümü uzatıyoruz.
Future<void> _openPattern(WidgetTester tester) async {
  // Bkz. _openSequenceMemory — kartlardaki beceri tablosu yüzünden
  // "Desen Tamamlama" (5. kart) lazy build cache dışında kalabiliyor.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Desen Tamamlama'));
  await tester.pumpAndSettle();
}

/// Mevcut turun doğru cevabına (`controller.currentTrial.answer`) karşılık
/// gelen seçenek butonuna basar ve geri bildirim gecikmesinin geçmesini
/// bekler.
Future<void> _answerPatternCorrectly(
  WidgetTester tester,
  PatternController controller,
) async {
  final correct = controller.currentTrial.answer;
  await tester.tap(find.byKey(ValueKey(correct)));
  await tester.pump(const Duration(milliseconds: 400));
}

/// [controller.cards] içinde aynı sembole sahip kartları sembole göre
/// gruplar; her grup tam olarak o çiftin iki index'ini içerir.
Map<String, List<int>> _groupCardIndicesBySymbol(
  MemoryMatchController controller,
) {
  final bySymbol = <String, List<int>>{};
  for (var i = 0; i < controller.cards.length; i++) {
    bySymbol.putIfAbsent(controller.cards[i].symbol, () => []).add(i);
  }
  return bySymbol;
}

void main() {
  testWidgets('Game catalog shows the available games', (
    WidgetTester tester,
  ) async {
    // Katalog listesi 5 karta çıktığı için varsayılan test görünümünde
    // ListView'in lazy build cache'i son kartı henüz kurmayabilir; tam
    // liste görünür olsun diye görünümü uzatıyoruz.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GamePlatformApp());

    expect(find.text('Oyun Platformu'), findsOneWidget);
    expect(find.text('Bombalı Sayılar'), findsOneWidget);
    expect(find.text('Kart Eşleştirme'), findsOneWidget);
    expect(find.text('Renk mi Kelime mi?'), findsOneWidget);
    expect(find.text('Dizi Hafızası'), findsOneWidget);
    expect(find.text('Desen Tamamlama'), findsOneWidget);
  });

  testWidgets(
    'Game catalog shows a Zeka/İngilizce/IQ/Hafıza star table per game',
    (WidgetTester tester) async {
      // Her kart artık 4 satırlık bir yıldız tablosu da içeriyor; ListView'in
      // lazy build cache'i tüm kartları kurabilsin diye görünümü daha da
      // uzatıyoruz.
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GamePlatformApp());

      expect(find.text('Zeka'), findsNWidgets(gameCatalog.length));
      expect(find.text('İngilizce'), findsNWidgets(gameCatalog.length));
      expect(find.text('IQ'), findsNWidgets(gameCatalog.length));
      expect(find.text('Hafıza'), findsNWidgets(gameCatalog.length));
      expect(
        find.byType(StarRating),
        findsNWidgets(gameCatalog.length * 4),
      );
    },
  );

  testWidgets('Setup screen shows player name fields and start button', (
    WidgetTester tester,
  ) async {
    await _openBombaliSayilar(tester);

    expect(find.text('1. Oyuncu adı'), findsOneWidget);
    expect(find.text('2. Oyuncu adı'), findsOneWidget);
    expect(find.text('Oyunu Başlat'), findsOneWidget);
  });

  testWidgets('Setup screen shows the 5 standard theme presets', (
    WidgetTester tester,
  ) async {
    await _openBombaliSayilar(tester);

    for (final theme in standardThemes) {
      expect(find.text(theme.name), findsOneWidget);
    }
  });

  testWidgets(
    'Selecting a preset and a custom color updates the active theme',
    (WidgetTester tester) async {
      await _openBombaliSayilar(tester);

      final controller = Provider.of<AppThemeController>(
        tester.element(find.byType(SetupScreen)),
        listen: false,
      );

      await tester.tap(find.text('Okyanus'));
      await tester.pump();
      expect(controller.current.name, 'Okyanus');
      expect(controller.current.boxColor, Colors.teal);

      controller.selectCustomBoxColor(customColorPalette[4]);
      expect(controller.selectedPresetIndex, isNull);
      expect(controller.current.name, 'Özel');
      expect(controller.current.boxColor, customColorPalette[4]);
    },
  );

  testWidgets('Starting a game shows the 5x10 number grid for player 1', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openBombaliSayilar(tester);

    await tester.tap(find.text('Oyunu Başlat'));
    await tester.pumpAndSettle();

    expect(find.textContaining('oynuyor'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('Hitting a bomb increments attempts and resets to row 1', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openBombaliSayilar(tester);
    await tester.tap(find.text('Oyunu Başlat'));
    await tester.pumpAndSettle();

    final controller = Provider.of<GameController>(
      tester.element(find.byType(GameScreen)),
      listen: false,
    );
    final bombCol = controller.currentPlayer.bombLayout[0].first;

    await tester.tap(find.text('${bombCol + 1}'));
    await tester.pump();

    expect(find.textContaining('💥'), findsOneWidget);
    expect(controller.currentPlayer.attempts, 1);
    expect(controller.currentPlayer.currentRow, 0);
  });

  testWidgets(
    'Completing both players transitions turns and shows the winner',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openBombaliSayilar(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<GameController>(
        tester.element(find.byType(GameScreen)),
        listen: false,
      );

      // 1. Oyuncu: hiç bombaya basmadan tüm satırları tamamlar.
      for (var row = 0; row < rowCount; row++) {
        final player = controller.currentPlayer;
        final safeCol = List.generate(
          colCount,
          (c) => c,
        ).firstWhere((c) => !player.bombLayout[row].contains(c));
        final number = row * colCount + safeCol + 1;
        await tester.tap(find.text('$number'));
        await tester.pump();
      }

      expect(controller.currentPlayer.attempts, 0);
      expect(find.textContaining('Sıra'), findsOneWidget);

      await tester.tap(find.text('Hazırım'));
      await tester.pumpAndSettle();

      // 2. Oyuncu: ilk satırda bilerek bombaya basar, sonra tamamlar.
      final player2BombCol = controller.currentPlayer.bombLayout[0].first;
      await tester.tap(find.text('${player2BombCol + 1}'));
      await tester.pump();
      expect(controller.currentPlayer.attempts, 1);

      for (var row = 0; row < rowCount; row++) {
        final player = controller.currentPlayer;
        final safeCol = List.generate(
          colCount,
          (c) => c,
        ).firstWhere((c) => !player.bombLayout[row].contains(c));
        final number = row * colCount + safeCol + 1;
        await tester.tap(find.text('$number'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('1. Oyuncu kazandı'), findsOneWidget);
      expect(find.text('0 deneme'), findsOneWidget);
      expect(find.text('1 deneme'), findsOneWidget);
    },
  );

  testWidgets(
    'Memory match: starting a game shows the card grid',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openMemoryMatch(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sıra:'), findsOneWidget);
      expect(
        find.byType(MemoryCardWidget),
        findsNWidgets(gridColumns * gridRows),
      );
    },
  );

  testWidgets(
    'Memory match: selecting Taşıtlar uses vehicle symbols instead of fruit',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openMemoryMatch(tester);
      await tester.tap(find.text('Taşıtlar'));
      await tester.pump();
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<MemoryMatchController>(
        tester.element(find.byType(MemoryGameScreen)),
        listen: false,
      );

      const vehicleSymbols = {
        '🚗',
        '🚌',
        '🚢',
        '🏍️',
        '🚚',
        '🚆',
        '✈️',
        '🚲',
      };
      expect(
        controller.cards.map((c) => c.symbol).toSet(),
        everyElement(isIn(vehicleSymbols)),
      );
      expect(controller.cards.any((c) => c.symbol == '🍎'), isFalse);
    },
  );

  testWidgets(
    'Memory match: matching a pair keeps the turn and scores a point',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openMemoryMatch(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<MemoryMatchController>(
        tester.element(find.byType(MemoryGameScreen)),
        listen: false,
      );
      final pair = _groupCardIndicesBySymbol(controller).values.first;

      await tester.tap(find.byType(MemoryCardWidget).at(pair[0]));
      await tester.pump();
      await tester.tap(find.byType(MemoryCardWidget).at(pair[1]));
      await tester.pump(const Duration(milliseconds: 500));

      expect(controller.players[0].matchedPairs, 1);
      expect(controller.currentPlayerIndex, 0);

      // Bulunan bir karta tekrar tıklamak seslendirmeyi tetikler ama oyun
      // durumunu (skor/sıra) değiştirmez.
      await tester.tap(find.byType(MemoryCardWidget).at(pair[0]));
      await tester.pumpAndSettle();

      expect(controller.players[0].matchedPairs, 1);
      expect(controller.currentPlayerIndex, 0);
    },
  );

  testWidgets(
    'Memory match: a mismatch passes the turn to the other player',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openMemoryMatch(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<MemoryMatchController>(
        tester.element(find.byType(MemoryGameScreen)),
        listen: false,
      );
      final bySymbol = _groupCardIndicesBySymbol(controller);
      final firstPair = bySymbol.values.first;
      final otherSymbolPair = bySymbol.values.firstWhere(
        (indices) => indices != firstPair,
      );

      await tester.tap(find.byType(MemoryCardWidget).at(firstPair[0]));
      await tester.pump();
      await tester.tap(find.byType(MemoryCardWidget).at(otherSymbolPair[0]));
      await tester.pump(const Duration(milliseconds: 950));

      expect(controller.players[0].matchedPairs, 0);
      expect(controller.currentPlayerIndex, 1);
    },
  );

  testWidgets(
    'Memory match: finding all pairs shows the winner',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openMemoryMatch(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<MemoryMatchController>(
        tester.element(find.byType(MemoryGameScreen)),
        listen: false,
      );

      // 1. Oyuncu tüm çiftleri sırayla, hiç yanlış yapmadan bulur; bu
      // yüzden sıra hiç değişmez ve tüm puanlar ona gider.
      for (final pair in _groupCardIndicesBySymbol(controller).values) {
        await tester.tap(find.byType(MemoryCardWidget).at(pair[0]));
        await tester.pump();
        await tester.tap(find.byType(MemoryCardWidget).at(pair[1]));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('1. Oyuncu kazandı'), findsOneWidget);
      expect(find.text('$pairCount çift'), findsOneWidget);
      expect(find.text('0 çift'), findsOneWidget);
    },
  );

  testWidgets(
    'Bombalı Sayılar: 1 Kişi seçimi ikinci oyuncu alanını gizler ve '
    'tek oyunculu tamamlanmayı kutlar',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openBombaliSayilar(tester);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('2. Oyuncu adı'), findsNothing);
      expect(find.text('Oyuncu adı'), findsOneWidget);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<GameController>(
        tester.element(find.byType(GameScreen)),
        listen: false,
      );
      expect(controller.players, hasLength(1));

      for (var row = 0; row < rowCount; row++) {
        final player = controller.currentPlayer;
        final safeCol = List.generate(
          colCount,
          (c) => c,
        ).firstWhere((c) => !player.bombLayout[row].contains(c));
        final number = row * colCount + safeCol + 1;
        await tester.tap(find.text('$number'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('Tebrikler, 1. Oyuncu!'), findsOneWidget);
    },
  );

  testWidgets(
    'Memory match: 1 Kişi seçimi ikinci oyuncu alanını gizler ve '
    'tek oyunculu tamamlanmayı kutlar',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openMemoryMatch(tester);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('2. Oyuncu adı'), findsNothing);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1. Oyuncu oynuyor'), findsOneWidget);

      final controller = Provider.of<MemoryMatchController>(
        tester.element(find.byType(MemoryGameScreen)),
        listen: false,
      );
      expect(controller.players, hasLength(1));

      for (final pair in _groupCardIndicesBySymbol(controller).values) {
        await tester.tap(find.byType(MemoryCardWidget).at(pair[0]));
        await tester.pump();
        await tester.tap(find.byType(MemoryCardWidget).at(pair[1]));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('Tebrikler, 1. Oyuncu!'), findsOneWidget);
    },
  );

  testWidgets(
    'Stroop: starting a game shows a stimulus and 6 color options',
    (WidgetTester tester) async {
      await _openStroop(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      expect(find.textContaining('oynuyor'), findsOneWidget);
      expect(find.textContaining('Tur 1 / $roundsPerPlayer'), findsOneWidget);
      expect(find.byType(GestureDetector), findsAtLeastNWidgets(6));
    },
  );

  testWidgets(
    'Stroop: answering correctly increments the score and advances the round',
    (WidgetTester tester) async {
      await _openStroop(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<StroopController>(
        tester.element(find.byType(StroopGameScreen)),
        listen: false,
      );

      await _answerCorrectly(tester, controller);

      expect(controller.currentPlayer.correctCount, 1);
      expect(controller.currentPlayer.roundsPlayed, 1);
    },
  );

  testWidgets(
    'Stroop: 1 Kişi tamamlanınca sonuç ekranında doğru sayısı görünür',
    (WidgetTester tester) async {
      await _openStroop(tester);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('2. Oyuncu adı'), findsNothing);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<StroopController>(
        tester.element(find.byType(StroopGameScreen)),
        listen: false,
      );
      expect(controller.players, hasLength(1));

      for (var round = 0; round < roundsPerPlayer; round++) {
        await _answerCorrectly(tester, controller);
      }
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('Tebrikler, 1. Oyuncu!'), findsOneWidget);
      expect(find.text('$roundsPerPlayer / $roundsPerPlayer doğru'), findsOneWidget);
    },
  );

  testWidgets(
    'Stroop: 2 Kişi — ilk oyuncu bitirince sıra ikinciye geçer',
    (WidgetTester tester) async {
      await _openStroop(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<StroopController>(
        tester.element(find.byType(StroopGameScreen)),
        listen: false,
      );

      for (var round = 0; round < roundsPerPlayer; round++) {
        await _answerCorrectly(tester, controller);
      }
      await tester.pumpAndSettle();

      expect(controller.players[0].correctCount, roundsPerPlayer);
      expect(find.textContaining('Sıra'), findsOneWidget);

      await tester.tap(find.text('Hazırım'));
      await tester.pumpAndSettle();

      expect(controller.currentPlayerIndex, 1);
      expect(find.textContaining('2. Oyuncu oynuyor'), findsOneWidget);
    },
  );

  testWidgets('Sequence memory: starting a game shows the 4 tiles', (
    WidgetTester tester,
  ) async {
    await _openSequenceMemory(tester);
    await tester.tap(find.text('Oyunu Başlat'));
    await tester.pump();

    expect(find.textContaining('oynuyor'), findsOneWidget);
    for (final tile in SequenceTileColor.values) {
      expect(find.byKey(ValueKey(tile)), findsOneWidget);
    }

    // Testin sonunda bekleyen bir zamanlayıcı kalmaması için otomatik
    // oynatımın bitmesini bekle.
    await tester.pump(_seqPlaybackDuration(1));
  });

  testWidgets(
    'Sequence memory: repeating the sequence correctly extends it',
    (WidgetTester tester) async {
      await _openSequenceMemory(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<SequenceMemoryController>(
        tester.element(find.byType(SequenceMemoryGameScreen)),
        listen: false,
      );

      await _tapCurrentSequenceCorrectly(tester, controller);
      await tester.pump(_seqCorrectExtendDelay);
      await tester.pump(_seqPlaybackDuration(2));

      expect(controller.sequence.length, 2);
      expect(controller.playerInputIndex, 0);
      expect(controller.showingSequence, isFalse);
    },
  );

  testWidgets(
    'Sequence memory: a wrong tap ends the turn and hands off',
    (WidgetTester tester) async {
      await _openSequenceMemory(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<SequenceMemoryController>(
        tester.element(find.byType(SequenceMemoryGameScreen)),
        listen: false,
      );
      await tester.pump(_seqPlaybackDuration(1));

      final wrongTile = SequenceTileColor.values.firstWhere(
        (tile) => tile != controller.sequence.first,
      );
      await tester.tap(find.byKey(ValueKey(wrongTile)));
      await tester.pump(_seqWrongFlashDuration);

      expect(controller.players[0].bestLength, 0);
      expect(controller.players[0].finished, isTrue);
      expect(find.textContaining('Sıra'), findsOneWidget);
    },
  );

  testWidgets(
    'Sequence memory: 1 Kişi tamamlanınca sonuç ekranında tebrik mesajı '
    'görünür',
    (WidgetTester tester) async {
      await _openSequenceMemory(tester);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('2. Oyuncu adı'), findsNothing);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<SequenceMemoryController>(
        tester.element(find.byType(SequenceMemoryGameScreen)),
        listen: false,
      );
      expect(controller.players, hasLength(1));
      await tester.pump(_seqPlaybackDuration(1));

      final wrongTile = SequenceTileColor.values.firstWhere(
        (tile) => tile != controller.sequence.first,
      );
      await tester.tap(find.byKey(ValueKey(wrongTile)));
      await tester.pump(_seqWrongFlashDuration);
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('Tebrikler, 1. Oyuncu!'), findsOneWidget);
    },
  );

  testWidgets(
    'Sequence memory: maxSequenceLength\'e ulaşmak mükemmel skorla turu '
    'bitirir',
    (WidgetTester tester) async {
      await _openSequenceMemory(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<SequenceMemoryController>(
        tester.element(find.byType(SequenceMemoryGameScreen)),
        listen: false,
      );
      await tester.pump(_seqPlaybackDuration(1));

      controller.sequence = List.filled(
        maxSequenceLength,
        SequenceTileColor.red,
      );
      controller.playerInputIndex = maxSequenceLength - 1;

      await tester.tap(find.byKey(const ValueKey(SequenceTileColor.red)));
      await tester.pump();

      expect(controller.players[0].bestLength, maxSequenceLength);
      expect(controller.players[0].finished, isTrue);
    },
  );

  testWidgets(
    'Pattern: starting a game shows the sequence and 4 options',
    (WidgetTester tester) async {
      await _openPattern(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      expect(find.textContaining('oynuyor'), findsOneWidget);
      expect(
        find.textContaining('Tur 1 / $patternRoundsPerPlayer'),
        findsOneWidget,
      );
      expect(find.text('?'), findsOneWidget);
      expect(find.byType(GestureDetector), findsAtLeastNWidgets(4));
    },
  );

  testWidgets(
    'Pattern: answering correctly increments the score and advances the '
    'round',
    (WidgetTester tester) async {
      await _openPattern(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<PatternController>(
        tester.element(find.byType(PatternGameScreen)),
        listen: false,
      );

      await _answerPatternCorrectly(tester, controller);

      expect(controller.currentPlayer.correctCount, 1);
      expect(controller.currentPlayer.roundsPlayed, 1);
    },
  );

  testWidgets(
    'Pattern: 1 Kişi tamamlanınca sonuç ekranında doğru sayısı görünür',
    (WidgetTester tester) async {
      await _openPattern(tester);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('2. Oyuncu adı'), findsNothing);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<PatternController>(
        tester.element(find.byType(PatternGameScreen)),
        listen: false,
      );
      expect(controller.players, hasLength(1));

      for (var round = 0; round < patternRoundsPerPlayer; round++) {
        await _answerPatternCorrectly(tester, controller);
      }
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('Tebrikler, 1. Oyuncu!'), findsOneWidget);
      expect(
        find.text('$patternRoundsPerPlayer / $patternRoundsPerPlayer doğru'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Pattern: 2 Kişi — ilk oyuncu bitirince sıra ikinciye geçer',
    (WidgetTester tester) async {
      await _openPattern(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<PatternController>(
        tester.element(find.byType(PatternGameScreen)),
        listen: false,
      );

      for (var round = 0; round < patternRoundsPerPlayer; round++) {
        await _answerPatternCorrectly(tester, controller);
      }
      await tester.pumpAndSettle();

      expect(controller.players[0].correctCount, patternRoundsPerPlayer);
      expect(find.textContaining('Sıra'), findsOneWidget);

      await tester.tap(find.text('Hazırım'));
      await tester.pumpAndSettle();

      expect(controller.currentPlayerIndex, 1);
      expect(find.textContaining('2. Oyuncu oynuyor'), findsOneWidget);
    },
  );
}
