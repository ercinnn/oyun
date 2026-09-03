import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bombali_sayilar/controllers/auth_controller.dart';
import 'package:bombali_sayilar/controllers/chess_controller.dart';
import 'package:bombali_sayilar/controllers/game_controller.dart';
import 'package:bombali_sayilar/controllers/memory_match_controller.dart';
import 'package:bombali_sayilar/controllers/pattern_controller.dart';
import 'package:bombali_sayilar/controllers/profile_controller.dart';
import 'package:bombali_sayilar/controllers/puzzle_controller.dart';
import 'package:bombali_sayilar/controllers/reflex_controller.dart';
import 'package:bombali_sayilar/controllers/sequence_memory_controller.dart';
import 'package:bombali_sayilar/controllers/simon_controller.dart';
import 'package:bombali_sayilar/controllers/stroop_controller.dart';
import 'package:bombali_sayilar/controllers/theme_controller.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/chess_board.dart';
import 'package:bombali_sayilar/models/chess_game_phase.dart';
import 'package:bombali_sayilar/models/chess_mode.dart';
import 'package:bombali_sayilar/models/chess_move.dart';
import 'package:bombali_sayilar/models/chess_outcome.dart';
import 'package:bombali_sayilar/models/chess_piece.dart';
import 'package:bombali_sayilar/models/chess_square.dart';
import 'package:bombali_sayilar/models/color_theme.dart';
import 'package:bombali_sayilar/models/player_state.dart';
import 'package:bombali_sayilar/models/puzzle_player_state.dart';
import 'package:bombali_sayilar/models/reflex_round_state.dart';
import 'package:bombali_sayilar/models/sequence_tile_color.dart';
import 'package:bombali_sayilar/models/simon_attribute_type.dart';
import 'package:bombali_sayilar/models/simon_tile_id.dart';
import 'package:bombali_sayilar/models/simon_trial.dart';
import 'package:bombali_sayilar/screens/chess_game_screen.dart';
import 'package:bombali_sayilar/screens/game_screen.dart';
import 'package:bombali_sayilar/screens/memory_game_screen.dart';
import 'package:bombali_sayilar/screens/game_catalog_screen.dart';
import 'package:bombali_sayilar/screens/pattern_game_screen.dart';
import 'package:bombali_sayilar/screens/puzzle_game_screen.dart';
import 'package:bombali_sayilar/screens/reflex_game_screen.dart';
import 'package:bombali_sayilar/screens/sequence_memory_game_screen.dart';
import 'package:bombali_sayilar/screens/setup_screen.dart';
import 'package:bombali_sayilar/screens/simon_game_screen.dart';
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

/// Platform ana menüsünden Tepki Süresi oyununa girer.
Future<void> _openReflex(WidgetTester tester) async {
  // Bkz. _openSequenceMemory/_openPattern — 6. (son) kart, beceri tablosu
  // yüzünden lazy build cache dışında kalabiliyor.
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Tepki Süresi'));
  await tester.pumpAndSettle();
}

// ReflexController'daki gecikme sabitleri kütüphane içi (private)
// olduğundan, diğer oyun testlerinin de yaptığı gibi burada kendi
// kopyaları tutulur.
const _reflexMaxSignalDelay = Duration(milliseconds: 3500);
const _reflexFeedbackDelay = Duration(milliseconds: 900);

/// `startGame`'den hemen sonra (hiç pump etmeden) dokunur; `_minSignalDelay`
/// (1200ms) bir taban olduğu için bu deterministik olarak erken başlamadır.
/// Bir turu hızlıca bitirmenin en basit yolu.
Future<void> _falseStartTap(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('reflexTapArea')));
  await tester.pump(_reflexFeedbackDelay);
}

/// Platform ana menüsünden Simon Diyor ki oyununa girer. Katalog listesi
/// 7 karta çıktığı için (bkz. "Game catalog shows the available games")
/// son kartın ListView'in lazy build cache'i dışında kalmaması için
/// görünümü uzatıyoruz.
Future<void> _openSimon(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 4200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Simon Diyor ki'));
  await tester.pumpAndSettle();
}

/// Mevcut turun doğru tepkisini verir: `obey` ise hedef kutuya, değilse
/// "Pas Geç" butonuna basar; ardından geri bildirim gecikmesinin
/// geçmesini bekler.
Future<void> _respondCorrectly(
  WidgetTester tester,
  SimonController controller,
) async {
  final trial = controller.currentTrial;
  final finder = trial.obey
      ? find.byKey(ValueKey(trial.target))
      : find.byKey(const Key('simonPassButton'));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

/// Platform ana menüsünden Kayan Yapboz oyununa girer. Katalog listesi
/// 8 karta çıktığı için (bkz. "Game catalog shows the available games")
/// son kartın ListView'in lazy build cache'i dışında kalmaması için
/// görünümü uzatıyoruz.
Future<void> _openPuzzle(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 4800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Kayan Yapboz'));
  await tester.pumpAndSettle();
}

/// Platform ana menüsünden Satranç oyununa girer. Katalog listesi 9 karta
/// çıktığı için (bkz. "Game catalog shows the available games") son kartın
/// ListView'in lazy build cache'i dışında kalmaması için görünümü
/// uzatıyoruz.
Future<void> _openChess(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 5400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Satranç'));
  await tester.pumpAndSettle();
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
  // BombaliSayilarGame yalnızca [Supabase.instance] üzerinden bir
  // SupabaseGameResultRepository kurar; gerçek bir ağ isteği yapılmadan
  // (initialize network çağrısı yapmaz, yalnızca istemciyi kurar) testlerin
  // çalışabilmesi için sahte bir proje ile bir kez initialize ediyoruz.
  // shared_preferences'ın oturum kalıcılığı için kullandığı platform
  // kanalı test ortamında yok, o yüzden mock başlangıç değerleri veriyoruz.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('Game catalog shows the available games', (
    WidgetTester tester,
  ) async {
    // Katalog listesi 9 karta çıktığı için varsayılan test görünümünde
    // ListView'in lazy build cache'i son kartı henüz kurmayabilir; tam
    // liste görünür olsun diye görünümü uzatıyoruz.
    tester.view.physicalSize = const Size(800, 5400);
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
    expect(find.text('Tepki Süresi'), findsOneWidget);
    expect(find.text('Simon Diyor ki'), findsOneWidget);
    expect(find.text('Kayan Yapboz'), findsOneWidget);
    expect(find.text('Satranç'), findsOneWidget);
  });

  testWidgets(
    'Game catalog shows a Zeka/İngilizce/IQ/Hafıza star table per game',
    (WidgetTester tester) async {
      // Her kart artık 4 satırlık bir yıldız tablosu da içeriyor; ListView'in
      // lazy build cache'i tüm kartları kurabilsin diye görünümü daha da
      // uzatıyoruz.
      tester.view.physicalSize = const Size(800, 5400);
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

  testWidgets(
    'Profildeki isim, oyunun 1. Oyuncu alanını otomatik doldurur',
    (WidgetTester tester) async {
      final profile = ProfileController()..name = 'Ada';
      await tester.pumpWidget(GamePlatformApp(profileController: profile));
      await tester.tap(find.text('Bombalı Sayılar'));
      await tester.pumpAndSettle();

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('2. Oyuncu'), findsOneWidget);
    },
  );

  testWidgets('Profil: isim girip kaydetmek profili günceller', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GamePlatformApp());
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    expect(find.text('Profilim'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('profileNameField')), 'Ada');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Oyun Platformu'), findsOneWidget);
    final profile = Provider.of<ProfileController>(
      tester.element(find.text('Oyun Platformu')),
      listen: false,
    );
    expect(profile.name, 'Ada');
  });

  testWidgets('Auth: oturum yokken giriş ekranı gösterilir', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GamePlatformApp(authController: AuthController()..isSignedIn = false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google ile Bağlan'), findsOneWidget);
    expect(find.text('Oyun Platformu'), findsOneWidget);
    expect(find.text('Bombalı Sayılar'), findsNothing);
  });

  testWidgets('Auth: Çıkış Yap, giriş ekranına döner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GamePlatformApp(authController: AuthController()..isSignedIn = true),
    );
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('signOutButton')));
    await tester.pumpAndSettle();

    expect(find.text('Google ile Bağlan'), findsOneWidget);
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

  testWidgets('Reflex: starting a game shows the waiting state', (
    WidgetTester tester,
  ) async {
    await _openReflex(tester);
    await tester.tap(find.text('Oyunu Başlat'));
    await tester.pump();

    expect(find.textContaining('oynuyor'), findsOneWidget);
    expect(find.text('Bekle...'), findsOneWidget);

    // Testin sonunda bekleyen bir zamanlayıcı kalmaması için sinyal
    // gecikmesinin bitmesini bekle.
    await tester.pump(_reflexMaxSignalDelay);
  });

  testWidgets(
    'Reflex: tapping before the signal is a false start',
    (WidgetTester tester) async {
      await _openReflex(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<ReflexController>(
        tester.element(find.byType(ReflexGameScreen)),
        listen: false,
      );

      // _minSignalDelay bir taban olduğu için hiç pump etmeden dokunmak
      // deterministik olarak erken başlamadır.
      await tester.tap(find.byKey(const Key('reflexTapArea')));
      await tester.pump();

      expect(controller.roundState, ReflexRoundState.tooEarly);
      expect(find.text('Çok erken!'), findsOneWidget);
      expect(controller.players[0].reactionTimes, [falseStartPenaltyMs]);
      expect(controller.players[0].roundsPlayed, 1);

      // Testin sonunda bekleyen zamanlayıcı kalmaması için geri bildirim
      // gecikmesini ve ardından başlayan sıradaki turun sinyal gecikmesini
      // bitir.
      await tester.pump(_reflexFeedbackDelay);
      await tester.pump(_reflexMaxSignalDelay);
    },
  );

  testWidgets(
    'Reflex: tapping after the signal records a reaction time',
    (WidgetTester tester) async {
      await _openReflex(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<ReflexController>(
        tester.element(find.byType(ReflexGameScreen)),
        listen: false,
      );

      // _maxSignalDelay kadar pump etmek, RNG ne çekerse çeksin
      // deterministik olarak "ready" durumuna ulaştırır.
      await tester.pump(_reflexMaxSignalDelay);
      expect(controller.roundState, ReflexRoundState.ready);

      await tester.tap(find.byKey(const Key('reflexTapArea')));
      await tester.pump();

      expect(controller.roundState, ReflexRoundState.result);
      expect(controller.players[0].roundsPlayed, 1);
      expect(controller.players[0].reactionTimes, hasLength(1));

      // Testin sonunda bekleyen zamanlayıcı kalmaması için geri bildirim
      // gecikmesini ve ardından başlayan sıradaki turun sinyal gecikmesini
      // bitir.
      await tester.pump(_reflexFeedbackDelay);
      await tester.pump(_reflexMaxSignalDelay);
    },
  );

  testWidgets(
    'Reflex: 1 Kişi tamamlanınca sonuç ekranında ortalama süre görünür',
    (WidgetTester tester) async {
      await _openReflex(tester);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('2. Oyuncu adı'), findsNothing);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<ReflexController>(
        tester.element(find.byType(ReflexGameScreen)),
        listen: false,
      );
      expect(controller.players, hasLength(1));

      for (var round = 0; round < reflexRoundsPerPlayer; round++) {
        await _falseStartTap(tester);
      }
      // Her erken başlama, bir sonraki tur için yeni bir sinyal gecikmesi
      // zamanlayıcısı da başlatır (o tur da erken bitirildiği için hiç
      // ateşlenmez); testin sonunda bekleyen zamanlayıcı kalmaması için
      // hepsini tek seferde temizle.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('Tebrikler, 1. Oyuncu!'), findsOneWidget);
    },
  );

  testWidgets(
    'Reflex: 2 Kişi — ilk oyuncu bitirince sıra ikinciye geçer',
    (WidgetTester tester) async {
      await _openReflex(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<ReflexController>(
        tester.element(find.byType(ReflexGameScreen)),
        listen: false,
      );

      for (var round = 0; round < reflexRoundsPerPlayer; round++) {
        await _falseStartTap(tester);
      }
      // Bkz. "1 Kişi" testindeki not: her erken başlama bir sonraki turun
      // sinyal zamanlayıcısını da başlatıyor, hiçbiri ateşlenmiyor.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(controller.players[0].roundsPlayed, reflexRoundsPerPlayer);
      expect(find.textContaining('Sıra'), findsOneWidget);

      await tester.tap(find.text('Hazırım'));
      await tester.pump();

      expect(controller.currentPlayerIndex, 1);
      expect(find.textContaining('2. Oyuncu oynuyor'), findsOneWidget);

      // Testin sonunda bekleyen bir zamanlayıcı kalmaması için 2. oyuncunun
      // ilk turunun sinyal gecikmesinin bitmesini bekle.
      await tester.pump(_reflexMaxSignalDelay);
    },
  );

  testWidgets(
    'Simon: starting a game shows the instruction, 4 tiles and pass button',
    (WidgetTester tester) async {
      await _openSimon(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      expect(find.textContaining('oynuyor'), findsOneWidget);
      expect(
        find.textContaining('Tur 1 / $simonRoundsPerPlayer'),
        findsOneWidget,
      );
      for (final tile in SimonTileId.values) {
        expect(find.byKey(ValueKey(tile)), findsOneWidget);
      }
      expect(find.byKey(const Key('simonPassButton')), findsOneWidget);
    },
  );

  testWidgets(
    'Simon: correct response (obey) increments the score',
    (WidgetTester tester) async {
      await _openSimon(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<SimonController>(
        tester.element(find.byType(SimonGameScreen)),
        listen: false,
      );
      // Deterministik bir "Simon dedi ki" turu için doğrudan controller
      // state'ini set ediyoruz (Pattern/SequenceMemory testlerindeki gibi,
      // controller alanları public).
      controller.currentTrial = SimonTrial(
        obey: true,
        attributeType: SimonAttributeType.color,
        target: SimonTileId.redCircle,
        boardOrder: SimonTileId.values,
      );

      await _respondCorrectly(tester, controller);

      expect(controller.currentPlayer.correctCount, 1);
      expect(controller.currentPlayer.roundsPlayed, 1);
    },
  );

  testWidgets(
    'Simon: correct response (Pas Geç) increments the score',
    (WidgetTester tester) async {
      await _openSimon(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<SimonController>(
        tester.element(find.byType(SimonGameScreen)),
        listen: false,
      );
      // Deterministik bir "Simon dedi ki" OLMAYAN tur için doğrudan
      // controller state'ini set ediyoruz.
      controller.currentTrial = SimonTrial(
        obey: false,
        attributeType: SimonAttributeType.shape,
        target: SimonTileId.greenTriangle,
        boardOrder: SimonTileId.values,
      );

      await _respondCorrectly(tester, controller);

      expect(controller.currentPlayer.correctCount, 1);
      expect(controller.currentPlayer.roundsPlayed, 1);
    },
  );

  testWidgets(
    'Simon: 1 Kişi tamamlanınca sonuç ekranında doğru sayısı görünür',
    (WidgetTester tester) async {
      await _openSimon(tester);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('2. Oyuncu adı'), findsNothing);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<SimonController>(
        tester.element(find.byType(SimonGameScreen)),
        listen: false,
      );
      expect(controller.players, hasLength(1));

      for (var round = 0; round < simonRoundsPerPlayer; round++) {
        await _respondCorrectly(tester, controller);
      }
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('Tebrikler, 1. Oyuncu!'), findsOneWidget);
      expect(
        find.text('$simonRoundsPerPlayer / $simonRoundsPerPlayer doğru'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Simon: 2 Kişi — ilk oyuncu bitirince sıra ikinciye geçer',
    (WidgetTester tester) async {
      await _openSimon(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<SimonController>(
        tester.element(find.byType(SimonGameScreen)),
        listen: false,
      );

      for (var round = 0; round < simonRoundsPerPlayer; round++) {
        await _respondCorrectly(tester, controller);
      }
      await tester.pumpAndSettle();

      expect(controller.players[0].correctCount, simonRoundsPerPlayer);
      expect(find.textContaining('Sıra'), findsOneWidget);

      await tester.tap(find.text('Hazırım'));
      await tester.pumpAndSettle();

      expect(controller.currentPlayerIndex, 1);
      expect(find.textContaining('2. Oyuncu oynuyor'), findsOneWidget);
    },
  );

  testWidgets(
    'Puzzle: starting a game shows 15 numbered tiles',
    (WidgetTester tester) async {
      await _openPuzzle(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      expect(find.textContaining('oynuyor'), findsOneWidget);
      for (var value = 1; value <= 15; value++) {
        expect(find.text('$value'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'Puzzle: tapping a tile adjacent to the empty cell slides it',
    (WidgetTester tester) async {
      await _openPuzzle(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<PuzzleController>(
        tester.element(find.byType(PuzzleGameScreen)),
        listen: false,
      );
      final emptyIndex = controller.currentPlayer.tiles.indexOf(0);
      final adjacentIndex = adjacentIndices(emptyIndex).first;
      final movedValue = controller.currentPlayer.tiles[adjacentIndex];

      await tester.tap(find.byKey(ValueKey(movedValue)));
      await tester.pump();

      expect(controller.currentPlayer.moveCount, 1);
      expect(controller.currentPlayer.tiles[emptyIndex], movedValue);
      expect(controller.currentPlayer.tiles[adjacentIndex], 0);
    },
  );

  testWidgets(
    'Puzzle: tapping a non-adjacent tile does nothing',
    (WidgetTester tester) async {
      await _openPuzzle(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<PuzzleController>(
        tester.element(find.byType(PuzzleGameScreen)),
        listen: false,
      );
      final emptyIndex = controller.currentPlayer.tiles.indexOf(0);
      final neighbors = adjacentIndices(emptyIndex);
      final nonAdjacentIndex = List.generate(
        16,
        (i) => i,
      ).firstWhere((i) => i != emptyIndex && !neighbors.contains(i));
      final tappedValue = controller.currentPlayer.tiles[nonAdjacentIndex];

      await tester.tap(find.byKey(ValueKey(tappedValue)));
      await tester.pump();

      expect(controller.currentPlayer.moveCount, 0);
    },
  );

  testWidgets(
    'Puzzle: 1 Kişi tamamlanınca sonuç ekranında hamle sayısı görünür',
    (WidgetTester tester) async {
      await _openPuzzle(tester);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('2. Oyuncu adı'), findsNothing);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<PuzzleController>(
        tester.element(find.byType(PuzzleGameScreen)),
        listen: false,
      );
      expect(controller.players, hasLength(1));

      // Çözülmeye tam bir hamle uzak bir durum set ediyoruz — gerçek bir
      // karışık 15'lik bulmacayı testte çözmek bir solver gerektirir.
      final oneMoveFromSolved = List<int>.generate(16, (i) {
        if (i == 14) return 0;
        if (i == 15) return 15;
        return i + 1;
      });
      for (var i = 0; i < oneMoveFromSolved.length; i++) {
        controller.currentPlayer.tiles[i] = oneMoveFromSolved[i];
      }

      // Doğrudan controller.moveTile çağırıyoruz: tiles listesini yerinde
      // değiştirdiğimiz için widget ağacı henüz yeniden kurulmadı, bu
      // yüzden find.byKey(ValueKey(15)) hâlâ eski (karışık) düzendeki
      // index'e bağlı kalırdı.
      controller.moveTile(15);
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('Tebrikler, 1. Oyuncu!'), findsOneWidget);
      expect(find.text('1 hamle'), findsOneWidget);
    },
  );

  testWidgets(
    'Puzzle: 2 Kişi — ilk oyuncu bitirince sıra ikinciye geçer',
    (WidgetTester tester) async {
      await _openPuzzle(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<PuzzleController>(
        tester.element(find.byType(PuzzleGameScreen)),
        listen: false,
      );

      final oneMoveFromSolved = List<int>.generate(16, (i) {
        if (i == 14) return 0;
        if (i == 15) return 15;
        return i + 1;
      });
      for (var i = 0; i < oneMoveFromSolved.length; i++) {
        controller.currentPlayer.tiles[i] = oneMoveFromSolved[i];
      }

      // Doğrudan controller.moveTile çağırıyoruz: tiles listesini yerinde
      // değiştirdiğimiz için widget ağacı henüz yeniden kurulmadı, bu
      // yüzden find.byKey(ValueKey(15)) hâlâ eski (karışık) düzendeki
      // index'e bağlı kalırdı.
      controller.moveTile(15);
      await tester.pumpAndSettle();

      expect(controller.players[0].moveCount, 1);
      expect(find.textContaining('Sıra'), findsOneWidget);

      await tester.tap(find.text('Hazırım'));
      await tester.pumpAndSettle();

      expect(controller.currentPlayerIndex, 1);
      expect(find.textContaining('2. Oyuncu oynuyor'), findsOneWidget);
    },
  );

  testWidgets(
    'Chess setup: 1 Kişi renk seçici + tek isim alanı, 2 Kişi iki isim '
    'alanı gösterir',
    (WidgetTester tester) async {
      await _openChess(tester);

      expect(find.text('Beyaz Oyuncu adı'), findsOneWidget);
      expect(find.text('Siyah Oyuncu adı'), findsOneWidget);
      expect(find.text('Beyaz'), findsNothing);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();

      expect(find.text('Oyuncu adı'), findsOneWidget);
      expect(find.text('Siyah Oyuncu adı'), findsNothing);
      expect(find.text('Beyaz'), findsOneWidget);
      expect(find.text('Siyah'), findsOneWidget);
    },
  );

  testWidgets(
    'Chess: 2 kişilik oyun başlangıç diziliminde, beyaz başlar, tahta '
    'dönmemiş olur',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      expect(controller.currentColor, PieceColor.white);
      expect(controller.boardFlipped, isFalse);
      expect(find.text('♙'), findsNWidgets(8));
      expect(find.text('♟'), findsNWidgets(8));
      expect(find.text('♔'), findsOneWidget);
      expect(find.text('♚'), findsOneWidget);
    },
  );

  testWidgets(
    'Chess: bir piyonu seçip geçerli hedefe dokununca hareket eder',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );
      final from = squareIndex(4, 1); // e2
      final to = squareIndex(4, 3); // e4

      await tester.tap(find.byKey(ValueKey('sq_$from')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('sq_$to')));
      await tester.pump();

      expect(controller.board.squares[to]?.type, PieceType.pawn);
      expect(controller.board.squares[from], isNull);
      expect(controller.currentColor, PieceColor.black);
    },
  );

  testWidgets(
    'Chess: geçersiz bir kareye dokunmak no-op olur',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );
      final from = squareIndex(4, 1); // e2
      controller.selectSquare(from);
      final before = List<ChessPiece?>.from(controller.board.squares);

      controller.selectSquare(squareIndex(4, 4)); // e5 — tek hamlede ulaşılamaz
      await tester.pump();

      expect(controller.board.squares, equals(before));
      expect(controller.selectedSquare, from);
    },
  );

  testWidgets(
    'Chess: rakip taşı alınca tahtadan kalkar',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      final squares = List<ChessPiece?>.filled(64, null);
      squares[squareIndex(4, 0)] = const ChessPiece(
        PieceType.king,
        PieceColor.white,
      );
      squares[squareIndex(4, 7)] = const ChessPiece(
        PieceType.king,
        PieceColor.black,
      );
      squares[squareIndex(3, 3)] = const ChessPiece(
        PieceType.rook,
        PieceColor.white,
      );
      squares[squareIndex(3, 6)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.black,
      );
      controller.board = ChessBoard.custom(squares: squares);

      controller.selectSquare(squareIndex(3, 3));
      controller.selectSquare(squareIndex(3, 6));

      expect(controller.board.squares[squareIndex(3, 6)]?.type, PieceType.rook);
      expect(controller.board.squares[squareIndex(3, 3)], isNull);
    },
  );

  testWidgets(
    'Chess: 2 kişilik modda tahta her hamlede döner',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );
      expect(controller.boardFlipped, isFalse);

      controller.selectSquare(squareIndex(4, 1));
      controller.selectSquare(squareIndex(4, 3));
      expect(controller.boardFlipped, isTrue);

      controller.selectSquare(squareIndex(4, 6));
      controller.selectSquare(squareIndex(4, 4));
      expect(controller.boardFlipped, isFalse);
    },
  );

  testWidgets(
    'Chess: bilgisayara karşı modda tahta oyuncunun rengine sabit kalır',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      await tester.tap(find.text('Siyah'));
      await tester.pump();
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      expect(controller.boardFlipped, isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.boardFlipped, isTrue);
    },
  );

  testWidgets(
    'Chess: rok kral ve kaleyi birlikte taşır; geçiş karesi tehdit '
    'altındaysa reddedilir',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      final squares = List<ChessPiece?>.filled(64, null);
      squares[squareIndex(4, 0)] = const ChessPiece(
        PieceType.king,
        PieceColor.white,
      );
      squares[squareIndex(7, 0)] = const ChessPiece(
        PieceType.rook,
        PieceColor.white,
      );
      squares[squareIndex(4, 7)] = const ChessPiece(
        PieceType.king,
        PieceColor.black,
      );
      controller.board = ChessBoard.custom(
        squares: squares,
        whiteKingsideRights: true,
      );

      controller.selectSquare(squareIndex(4, 0));
      expect(
        controller.selectedSquareLegalMoves.any(
          (m) => m.flag == ChessMoveFlag.castleKingside,
        ),
        isTrue,
      );
      controller.selectSquare(squareIndex(6, 0));

      expect(controller.board.squares[squareIndex(6, 0)]?.type, PieceType.king);
      expect(controller.board.squares[squareIndex(5, 0)]?.type, PieceType.rook);
      expect(controller.board.squares[squareIndex(4, 0)], isNull);
      expect(controller.board.squares[squareIndex(7, 0)], isNull);

      // Reddedilme durumu: f1 karesi siyah kale tarafından tehdit ediliyor.
      final blockedSquares = List<ChessPiece?>.filled(64, null);
      blockedSquares[squareIndex(4, 0)] = const ChessPiece(
        PieceType.king,
        PieceColor.white,
      );
      blockedSquares[squareIndex(7, 0)] = const ChessPiece(
        PieceType.rook,
        PieceColor.white,
      );
      blockedSquares[squareIndex(4, 7)] = const ChessPiece(
        PieceType.king,
        PieceColor.black,
      );
      blockedSquares[squareIndex(5, 7)] = const ChessPiece(
        PieceType.rook,
        PieceColor.black,
      );
      final blockedBoard = ChessBoard.custom(
        squares: blockedSquares,
        whiteKingsideRights: true,
      );
      expect(
        blockedBoard
            .legalMovesFrom(squareIndex(4, 0))
            .any((m) => m.flag == ChessMoveFlag.castleKingside),
        isFalse,
      );
    },
  );

  testWidgets(
    'Chess: geçerken alma yakalanan piyonu doğru kareden kaldırır',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      final squares = List<ChessPiece?>.filled(64, null);
      squares[squareIndex(4, 0)] = const ChessPiece(
        PieceType.king,
        PieceColor.white,
      );
      squares[squareIndex(4, 7)] = const ChessPiece(
        PieceType.king,
        PieceColor.black,
      );
      squares[squareIndex(4, 4)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.white,
      ); // e5
      squares[squareIndex(3, 4)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.black,
      ); // d5, az önce d7-d5 oynanmış gibi
      controller.board = ChessBoard.custom(
        squares: squares,
        enPassantTargetSquare: squareIndex(3, 5), // d6
      );

      controller.selectSquare(squareIndex(4, 4));
      controller.selectSquare(squareIndex(3, 5));

      expect(controller.board.squares[squareIndex(3, 5)]?.type, PieceType.pawn);
      expect(controller.board.squares[squareIndex(3, 4)], isNull);
      expect(controller.board.squares[squareIndex(4, 4)], isNull);
    },
  );

  testWidgets(
    'Chess: terfi penceresi 4 seçenek gösterir, seçilen taşa dönüştürür',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      final squares = List<ChessPiece?>.filled(64, null);
      squares[squareIndex(4, 0)] = const ChessPiece(
        PieceType.king,
        PieceColor.white,
      );
      squares[squareIndex(4, 7)] = const ChessPiece(
        PieceType.king,
        PieceColor.black,
      );
      squares[squareIndex(0, 6)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.white,
      ); // a7
      controller.board = ChessBoard.custom(squares: squares);

      await tester.tap(find.byKey(ValueKey('sq_${squareIndex(0, 6)}')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('sq_${squareIndex(0, 7)}'))); // a8
      await tester.pumpAndSettle();

      expect(controller.pendingPromotionMoves, hasLength(4));
      expect(find.text('Terfi'), findsOneWidget);

      await tester.tap(find.text('♕'));
      await tester.pumpAndSettle();

      expect(
        controller.board.squares[squareIndex(0, 7)],
        const ChessPiece(PieceType.queen, PieceColor.white),
      );
      expect(controller.pendingPromotionMoves, isEmpty);
    },
  );

  testWidgets(
    'Chess: şah mat oyunu doğru sonuçla bitirir',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      // Klasik son sıra matı: siyah kral g8'de kendi piyonları arasına
      // sıkışmış, beyaz kale a5'ten a8'e giderek mat eder.
      final squares = List<ChessPiece?>.filled(64, null);
      squares[squareIndex(6, 7)] = const ChessPiece(
        PieceType.king,
        PieceColor.black,
      ); // g8
      squares[squareIndex(5, 6)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.black,
      ); // f7
      squares[squareIndex(6, 6)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.black,
      ); // g7
      squares[squareIndex(7, 6)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.black,
      ); // h7
      squares[squareIndex(0, 4)] = const ChessPiece(
        PieceType.rook,
        PieceColor.white,
      ); // a5
      squares[squareIndex(4, 0)] = const ChessPiece(
        PieceType.king,
        PieceColor.white,
      ); // e1
      controller.board = ChessBoard.custom(squares: squares);

      controller.selectSquare(squareIndex(0, 4));
      controller.selectSquare(squareIndex(0, 7)); // Ra5-a8#

      expect(controller.phase, ChessGamePhase.finished);
      expect(controller.outcome, ChessOutcome.whiteWins);
      expect(controller.outcomeReason, ChessOutcomeReason.checkmate);
    },
  );

  testWidgets(
    'Chess: pat oyunu berabere olarak bitirir',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      // Klasik K+V pat kalıbı: beyaz vezir a5'ten b6'ya giderek siyah
      // kralı (a8) hiçbir kaçış karesi bırakmadan (ama şah çekmeden) kilitler.
      final squares = List<ChessPiece?>.filled(64, null);
      squares[squareIndex(0, 7)] = const ChessPiece(
        PieceType.king,
        PieceColor.black,
      ); // a8
      squares[squareIndex(2, 6)] = const ChessPiece(
        PieceType.king,
        PieceColor.white,
      ); // c7
      squares[squareIndex(0, 4)] = const ChessPiece(
        PieceType.queen,
        PieceColor.white,
      ); // a5
      controller.board = ChessBoard.custom(squares: squares);

      controller.selectSquare(squareIndex(0, 4));
      controller.selectSquare(squareIndex(1, 5)); // Qa5-b6

      expect(controller.phase, ChessGamePhase.finished);
      expect(controller.outcome, ChessOutcome.draw);
      expect(controller.outcomeReason, ChessOutcomeReason.stalemate);
    },
  );

  test('Chess: çivilenmiş (pinned) taş hattı terk edemez', () {
    final squares = List<ChessPiece?>.filled(64, null);
    squares[squareIndex(4, 0)] = const ChessPiece(
      PieceType.king,
      PieceColor.white,
    ); // e1
    squares[squareIndex(4, 1)] = const ChessPiece(
      PieceType.bishop,
      PieceColor.white,
    ); // e2
    squares[squareIndex(4, 7)] = const ChessPiece(
      PieceType.rook,
      PieceColor.black,
    ); // e8
    squares[squareIndex(0, 7)] = const ChessPiece(
      PieceType.king,
      PieceColor.black,
    ); // a8
    final board = ChessBoard.custom(squares: squares);

    expect(board.legalMovesFrom(squareIndex(4, 1)), isEmpty);
  });

  testWidgets(
    'Chess: AI düşünme gecikmesi sonrası geçerli bir hamle oynar',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      await tester.tap(find.text('Siyah'));
      await tester.pump();
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );
      expect(controller.aiThinking, isTrue);

      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.aiThinking, isFalse);
      expect(controller.board.moveHistory, hasLength(1));
      expect(controller.currentColor, PieceColor.black);
    },
  );

  testWidgets(
    'Chess: AI gecikmesi sırasında yeniden başlatmak yeni oyuna bayat '
    'hamle sızdırmaz',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      await tester.tap(find.text('Siyah'));
      await tester.pump();
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );
      expect(controller.aiThinking, isTrue);

      controller.restart();
      await tester.pump();
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      expect(controller.mode, ChessMode.twoPlayer);
      expect(controller.board.moveHistory, isEmpty);

      // Eski AI hamlesinin gecikmesi geçsin — generation korumasız olsaydı
      // burada yeni oyuna sızardı.
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.board.moveHistory, isEmpty);
      expect(controller.aiThinking, isFalse);
    },
  );
}
