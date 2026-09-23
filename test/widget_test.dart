import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bombali_sayilar/controllers/auth_controller.dart';
import 'package:bombali_sayilar/controllers/chess_controller.dart';
import 'package:bombali_sayilar/controllers/chess_lesson_controller.dart';
import 'package:bombali_sayilar/services/chess_move_sound.dart';
import 'package:bombali_sayilar/services/chess_move_sound_recipe.dart';
import 'package:bombali_sayilar/services/chess_move_sound_synth.dart';
import 'package:bombali_sayilar/data/chess_lesson_catalog.dart';
import 'package:bombali_sayilar/models/chess_lesson.dart';
import 'package:bombali_sayilar/screens/chess_lesson_screen.dart';
import 'package:bombali_sayilar/controllers/game_controller.dart';
import 'package:bombali_sayilar/controllers/memory_match_controller.dart';
import 'package:bombali_sayilar/controllers/multiplication_controller.dart';
import 'package:bombali_sayilar/controllers/pattern_controller.dart';
import 'package:bombali_sayilar/models/pattern_difficulty.dart';
import 'package:bombali_sayilar/controllers/electricity_controller.dart';
import 'package:bombali_sayilar/controllers/town_controller.dart';
import 'package:bombali_sayilar/data/town_map_data.dart';
import 'package:bombali_sayilar/models/town/avatar_spec.dart';
import 'package:bombali_sayilar/models/town/iso_projection.dart';
import 'package:bombali_sayilar/models/town/mini_game_session.dart';
import 'package:bombali_sayilar/models/town/room_layout.dart';
import 'package:bombali_sayilar/models/town/shop_catalog.dart';
import 'package:bombali_sayilar/models/town/town_map.dart';
import 'package:bombali_sayilar/models/town/town_phase.dart';
import 'package:bombali_sayilar/models/town/town_profile.dart';
import 'package:bombali_sayilar/models/town/town_world.dart';
import 'package:bombali_sayilar/services/town_progress_repository.dart';
import 'package:bombali_sayilar/data/town_sound_clips.dart';
import 'package:bombali_sayilar/services/audio/clip_synth.dart';
import 'package:bombali_sayilar/services/audio/sound_clip.dart';
import 'package:bombali_sayilar/services/town_sounds.dart';
import 'package:bombali_sayilar/widgets/iso_room_view.dart';
import 'package:bombali_sayilar/widgets/iso_world_painter.dart';
import 'package:bombali_sayilar/widgets/iso_world_view.dart';
import 'package:bombali_sayilar/controllers/plant_lab_controller.dart';
import 'package:bombali_sayilar/data/electric_materials.dart';
import 'package:bombali_sayilar/data/safety_scenes.dart';
import 'package:bombali_sayilar/models/circuit_simulation.dart';
import 'package:bombali_sayilar/models/circuit_spec.dart';
import 'package:bombali_sayilar/models/electric_task.dart';
import 'package:bombali_sayilar/models/electric_task_factory.dart';
import 'package:bombali_sayilar/models/electricity_phase.dart';
import 'package:bombali_sayilar/models/energy_city.dart';
import 'package:bombali_sayilar/models/wire_puzzle.dart';
import 'package:bombali_sayilar/data/plant_catalog.dart';
import 'package:bombali_sayilar/models/plant_conditions.dart';
import 'package:bombali_sayilar/models/plant_growth.dart';
import 'package:bombali_sayilar/models/plant_lab_game_phase.dart';
import 'package:bombali_sayilar/models/plant_lab_trial.dart';
import 'package:bombali_sayilar/controllers/profile_controller.dart';
import 'package:bombali_sayilar/controllers/puzzle_controller.dart';
import 'package:bombali_sayilar/controllers/reflex_controller.dart';
import 'package:bombali_sayilar/controllers/sequence_memory_controller.dart';
import 'package:bombali_sayilar/controllers/simon_controller.dart';
import 'package:bombali_sayilar/controllers/stroop_controller.dart';
import 'package:bombali_sayilar/controllers/sudoku_controller.dart';
import 'package:bombali_sayilar/controllers/theme_controller.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/chess_board.dart';
import 'package:bombali_sayilar/models/chess_difficulty.dart';
import 'package:bombali_sayilar/models/chess_game_phase.dart';
import 'package:bombali_sayilar/models/chess_mode.dart';
import 'package:bombali_sayilar/models/chess_move.dart';
import 'package:bombali_sayilar/models/chess_notation.dart';
import 'package:bombali_sayilar/models/chess_outcome.dart';
import 'package:bombali_sayilar/models/chess_piece.dart';
import 'package:bombali_sayilar/models/chess_square.dart';
import 'package:bombali_sayilar/models/chess_time_control.dart';
import 'package:bombali_sayilar/models/color_theme.dart';
import 'package:bombali_sayilar/models/multiplication_context.dart';
import 'package:bombali_sayilar/models/multiplication_difficulty.dart';
import 'package:bombali_sayilar/models/multiplication_trial.dart';
import 'package:bombali_sayilar/models/player_state.dart';
import 'package:bombali_sayilar/models/puzzle_player_state.dart';
import 'package:bombali_sayilar/models/reflex_round_state.dart';
import 'package:bombali_sayilar/models/sequence_tile_color.dart';
import 'package:bombali_sayilar/models/simon_attribute_type.dart';
import 'package:bombali_sayilar/models/simon_tile_id.dart';
import 'package:bombali_sayilar/models/simon_trial.dart';
import 'package:bombali_sayilar/models/sudoku_board.dart';
import 'package:bombali_sayilar/models/sudoku_difficulty.dart';
import 'package:bombali_sayilar/models/sudoku_game_phase.dart';
import 'package:bombali_sayilar/screens/chess_game_screen.dart';
import 'package:bombali_sayilar/screens/game_screen.dart';
import 'package:bombali_sayilar/screens/memory_game_screen.dart';
import 'package:bombali_sayilar/screens/multiplication_game_screen.dart';
import 'package:bombali_sayilar/screens/game_catalog_screen.dart';
import 'package:bombali_sayilar/screens/pattern_game_screen.dart';
import 'package:bombali_sayilar/screens/puzzle_game_screen.dart';
import 'package:bombali_sayilar/screens/reflex_game_screen.dart';
import 'package:bombali_sayilar/screens/sequence_memory_game_screen.dart';
import 'package:bombali_sayilar/screens/setup_screen.dart';
import 'package:bombali_sayilar/screens/simon_game_screen.dart';
import 'package:bombali_sayilar/screens/stroop_game_screen.dart';
import 'package:bombali_sayilar/screens/sudoku_game_screen.dart';
import 'package:bombali_sayilar/widgets/memory_card_widget.dart';
import 'package:bombali_sayilar/widgets/multiplication_array_view.dart';
import 'package:bombali_sayilar/services/chess_ai.dart';
import 'package:bombali_sayilar/widgets/chess_evaluation_bar.dart';
import 'package:bombali_sayilar/widgets/chess_move_history.dart';
import 'package:bombali_sayilar/widgets/chess_piece_glyph.dart';
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

/// Platform ana menüsünden Diziler oyununa girer. Katalog listesi
/// 5 karta çıktığı için (bkz. "Game catalog shows the available games")
/// son kartın ListView'in lazy build cache'i dışında kalmaması için
/// görünümü uzatıyoruz.
Future<void> _openPattern(WidgetTester tester) async {
  // Bkz. _openSequenceMemory — kartlardaki beceri tablosu yüzünden
  // "Diziler" (5. kart) lazy build cache dışında kalabiliyor.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Diziler'));
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

/// Platform ana menüsünden Çarpım Bahçesi oyununa girer. Katalogdaki 10. kart
/// olduğu için görünümü bir kademe daha uzatıyoruz (bkz. _openChess).
Future<void> _openMultiplication(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Çarpım Bahçesi'));
  await tester.pumpAndSettle();
}

/// Platform ana menüsünden Sudoku oyununa girer. Katalogdaki 11. kart
/// olduğu için görünümü bir kademe daha uzatıyoruz (bkz. _openMultiplication).
Future<void> _openSudoku(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 6600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Sudoku'));
  await tester.pumpAndSettle();
}

/// Çarpım Bahçesi'nde açık olan turu doğru cevaplar ve açıklama panelindeki
/// "Devam"a basarak bir sonraki tura geçer.
///
/// Kurma turunda ızgarayı `+` düğmeleriyle kurmak tur başına 10'a varan
/// dokunuş demek; onun yerine kontrolcünün alanları doğrudan set ediliyor —
/// Kayan Yapboz testlerinin `controller.currentPlayer.tiles`'ı doğrudan
/// kurmasıyla aynı yerleşik konvansiyon.
Future<void> _answerMultiplicationCorrectly(
  WidgetTester tester,
  MultiplicationController controller,
) async {
  final trial = controller.currentTrial;
  if (trial.kind == MultiplicationTrialKind.array) {
    await tester.tap(find.byKey(ValueKey(trial.answer)));
  } else {
    controller.buildRows = trial.rows;
    controller.buildColumns = trial.columns;
    await tester.tap(find.byKey(const Key('multiplicationConfirm')));
  }
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('multiplicationContinue')));
  await tester.pumpAndSettle();
}

/// Çarpım Bahçesi kontrolcüsünü oyun ekranının context'inden alır.
MultiplicationController _multiplicationController(WidgetTester tester) {
  return Provider.of<MultiplicationController>(
    tester.element(find.byType(MultiplicationGameScreen)),
    listen: false,
  );
}

/// Tahtadaki belirli bir taşı bulur. Taşlar Unicode sembolü olarak
/// çizilmediği için (bkz. `widgets/chess_piece_glyph.dart`) metin yerine
/// widget'ın taşına bakılır.
Finder _findPiece(PieceType type, PieceColor color) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is ChessPieceGlyph && widget.piece == ChessPiece(type, color),
  );
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
    // Bilgisayarın insansı düşünme gecikmesi testlerde kapalı; kendi testi
    // çarpanı geçici olarak 1'e çeker.
    ChessController.aiThinkTimeScale = 0;
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('Game catalog shows the available games', (
    WidgetTester tester,
  ) async {
    // Katalog listesi 11 karta çıktığı için varsayılan test görünümünde
    // ListView'in lazy build cache'i son kartı henüz kurmayabilir; tam
    // liste görünür olsun diye görünümü uzatıyoruz.
    tester.view.physicalSize = const Size(800, 6600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GamePlatformApp());

    expect(find.text('Oyun Platformu'), findsOneWidget);
    expect(find.text('Bombalı Sayılar'), findsOneWidget);
    expect(find.text('Kart Eşleştirme'), findsOneWidget);
    expect(find.text('Renk mi Kelime mi?'), findsOneWidget);
    expect(find.text('Dizi Hafızası'), findsOneWidget);
    expect(find.text('Diziler'), findsOneWidget);
    expect(find.text('Tepki Süresi'), findsOneWidget);
    expect(find.text('Simon Diyor ki'), findsOneWidget);
    expect(find.text('Kayan Yapboz'), findsOneWidget);
    expect(find.text('Satranç'), findsOneWidget);
    expect(find.text('Çarpım Bahçesi'), findsOneWidget);
    expect(find.text('Sudoku'), findsOneWidget);
  });

  testWidgets(
    'Game catalog shows a Zeka/İngilizce/IQ/Hafıza star table per game',
    (WidgetTester tester) async {
      // Her kart artık 4 satırlık bir yıldız tablosu da içeriyor; ListView'in
      // lazy build cache'i tüm kartları kurabilsin diye görünümü daha da
      // uzatıyoruz.
      tester.view.physicalSize = const Size(800, 6600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GamePlatformApp());

      expect(find.text('Zeka'), findsNWidgets(gameCatalog.length));
      expect(find.text('İngilizce'), findsNWidgets(gameCatalog.length));
      expect(find.text('IQ'), findsNWidgets(gameCatalog.length));
      expect(find.text('Hafıza'), findsNWidgets(gameCatalog.length));
      expect(find.text('Dikkat'), findsNWidgets(gameCatalog.length));
      expect(
        find.byType(StarRating),
        findsNWidgets(gameCatalog.length * 5),
      );
    },
  );

  testWidgets(
    'Game catalog: telefon genişliğinde kartlar taşmadan tek sütuna düşer',
    (WidgetTester tester) async {
      // Kartların yüksekliği sabit (GameCatalogScreen._cardHeight); dar
      // ekranda açıklama 3 satıra çıktığı için taşma riski en yüksek yer
      // burası. Taşma debug'da exception attığından test kendiliğinden
      // kırmızıya döner — ayrıca assert etmeye gerek yok.
      tester.view.physicalSize = const Size(400, 4600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GamePlatformApp());

      expect(find.text('Bombalı Sayılar'), findsOneWidget);
      expect(find.text('Çarpım Bahçesi'), findsOneWidget);
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

  test('Diziler: Kolay seviye çarpım tablosunu pekiştirir', () async {
    final controller = PatternController(random: Random(1));
    controller.startGame(['Test'], difficulty: PatternDifficulty.kolay);

    for (var round = 0; round < patternRoundsPerPlayer; round++) {
      final trial = controller.currentTrial;
      final sequence = trial.sequence;
      final step = sequence[1] - sequence[0];

      expect(step, inInclusiveRange(2, 9));
      // Dizinin tamamı aynı adımla artan bir çarpım tablosu satırı olmalı,
      // ve her terim o tablonun bir katı olmalı (2,4,6,8 gibi, 3,5,7,9 gibi
      // değil).
      for (var i = 0; i < sequence.length; i++) {
        expect(sequence[i] % step, 0);
        if (i > 0) expect(sequence[i] - sequence[i - 1], step);
      }
      expect(trial.answer - sequence.last, step);
      expect(trial.answer % step, 0);

      await controller.answer(trial.answer);
    }
  });

  test(
    'Diziler: Orta seviye eski (zorluksuz) davranışla aynı kural '
    'tiplerini üretir',
    () async {
      final controller = PatternController(random: Random(2));
      controller.startGame(['Test'], difficulty: PatternDifficulty.orta);

      for (var round = 0; round < patternRoundsPerPlayer; round++) {
        final trial = controller.currentTrial;
        final sequence = trial.sequence;
        final diffs = [
          for (var i = 1; i < sequence.length; i++)
            sequence[i] - sequence[i - 1],
        ];
        final isArithmetic = diffs.toSet().length == 1;
        final isGeometric =
            sequence[0] > 0 &&
            List.generate(
              sequence.length,
              (i) => sequence[0] * pow(sequence[1] ~/ sequence[0], i).toInt(),
            ).join(',') ==
                sequence.join(',');
        expect(
          isArithmetic || isGeometric,
          isTrue,
          reason: 'Orta seviyede beklenmeyen bir dizi üretildi: $sequence',
        );

        await controller.answer(trial.answer);
      }
    },
  );

  test(
    'Diziler: Zor seviye büyük aralıklar kullanır ve azalan (bölen) '
    'geometrik diziler üretebilir',
    () async {
      final controller = PatternController(random: Random(3));
      controller.startGame(['Test'], difficulty: PatternDifficulty.zor);

      var sawDescendingGeometric = false;
      for (var round = 0; round < patternRoundsPerPlayer; round++) {
        final trial = controller.currentTrial;
        final sequence = trial.sequence;
        final diffs = [
          for (var i = 1; i < sequence.length; i++)
            sequence[i] - sequence[i - 1],
        ];
        final isDescending = diffs.every((d) => d < 0);
        final isArithmetic = diffs.toSet().length == 1;
        if (isDescending && !isArithmetic) sawDescendingGeometric = true;

        await controller.answer(trial.answer);
      }

      // Rastgelelik yüzünden 8 turda en az bir azalan geometrik (bölen) dizi
      // çıkması garanti değil ama sabit bir seed ile deterministik; bu seed
      // (3) en az bir tane üretiyor.
      expect(sawDescendingGeometric, isTrue);
    },
  );

  test(
    'Diziler: her üç seviyede de üretilen seçenekler her zaman 4 tekrarsız '
    'aday içerir',
    () async {
      for (final difficulty in PatternDifficulty.values) {
        final controller = PatternController(random: Random(4));
        controller.startGame(['Test'], difficulty: difficulty);

        for (var round = 0; round < patternRoundsPerPlayer; round++) {
          final trial = controller.currentTrial;
          expect(trial.options, hasLength(4));
          expect(trial.options.toSet(), hasLength(4));
          expect(trial.options, contains(trial.answer));

          await controller.answer(trial.answer);
        }
      }
    },
  );

  testWidgets(
    'Diziler: kurulum ekranında zorluk seçici görünür ve seçim '
    'değiştirince ipucu metni güncellenir',
    (WidgetTester tester) async {
      await _openPattern(tester);

      expect(
        find.text('Zorluk: ${PatternDifficulty.kolay.hint}'),
        findsOneWidget,
      );

      await tester.tap(find.text('Zor'));
      await tester.pumpAndSettle();

      expect(
        find.text('Zorluk: ${PatternDifficulty.zor.hint}'),
        findsOneWidget,
      );
      expect(
        find.text('Zorluk: ${PatternDifficulty.kolay.hint}'),
        findsNothing,
      );
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

  test(
    'Sudoku: üretilen çözüm her satır/sütun/kutuda 1-9 permütasyonu içerir',
    () {
      final grid = generateSolvedSudokuGrid(Random(1));

      bool isPermutation(List<int> values) {
        final set = values.toSet();
        return set.length == sudokuSize &&
            set.every((v) => v >= 1 && v <= sudokuSize);
      }

      for (var r = 0; r < sudokuSize; r++) {
        expect(
          isPermutation([
            for (var c = 0; c < sudokuSize; c++) grid[r * sudokuSize + c],
          ]),
          isTrue,
        );
      }
      for (var c = 0; c < sudokuSize; c++) {
        expect(
          isPermutation([
            for (var r = 0; r < sudokuSize; r++) grid[r * sudokuSize + c],
          ]),
          isTrue,
        );
      }
      for (var box = 0; box < sudokuSize; box++) {
        final boxRow = (box ~/ sudokuBoxSize) * sudokuBoxSize;
        final boxCol = (box % sudokuBoxSize) * sudokuBoxSize;
        final values = [
          for (var r = boxRow; r < boxRow + sudokuBoxSize; r++)
            for (var c = boxCol; c < boxCol + sudokuBoxSize; c++)
              grid[r * sudokuSize + c],
        ];
        expect(isPermutation(values), isTrue);
      }
    },
  );

  test(
    'Sudoku: her zorluk seviyesi 81\'den az, hedefe en az eşit sayıda ipucu '
    'üretir',
    () {
      for (final difficulty in SudokuDifficulty.values) {
        final puzzle = generateSudokuPuzzle(difficulty, Random(2));
        final clueCount = puzzle.given.where((g) => g).length;

        expect(clueCount, greaterThanOrEqualTo(difficulty.targetClues));
        // Gevşek bir üst sınır: üretici anlamlı miktarda hücre çıkarabildi mi
        // diye kontrol ediyor (81 kalırsa üretici bozuk demektir).
        expect(clueCount, lessThan(60));
      }
    },
  );

  test('Sudoku: doğru son rakamı girince oyuncu biter ve devreder', () {
    final controller = SudokuController(random: Random(3));
    controller.startGame(['A', 'B'], difficulty: SudokuDifficulty.kolay);

    final player = controller.players[0];
    final lastEmpty = player.given.indexWhere((g) => !g);
    for (var i = 0; i < player.values.length; i++) {
      if (i != lastEmpty) player.values[i] = player.solution[i];
    }

    controller.selectCell(lastEmpty);
    controller.enterDigit(player.solution[lastEmpty]);

    expect(player.finished, isTrue);
    expect(player.mistakeCount, 0);
    expect(player.isSolved, isTrue);
    expect(controller.currentPlayerIndex, 1);
    expect(controller.phase, SudokuGamePhase.turnTransition);
    expect(controller.rankedByMistakes.first, same(player));
  });

  test(
    'Sudoku: yanlış rakam hata sayısını artırır ama 3\'ten az ise tur '
    'bitmez',
    () {
      final controller = SudokuController(random: Random(4));
      controller.startGame(['A'], difficulty: SudokuDifficulty.kolay);
      final player = controller.players[0];
      final index = player.given.indexWhere((g) => !g);
      final wrong = player.solution[index] == sudokuSize
          ? 1
          : player.solution[index] + 1;

      controller.selectCell(index);
      controller.enterDigit(wrong);

      expect(player.mistakeCount, 1);
      expect(player.finished, isFalse);
      expect(controller.phase, SudokuGamePhase.playing);
    },
  );

  test(
    'Sudoku: 3. yanlış girişte tahta tamamlanmamış olsa da tur biter',
    () {
      final controller = SudokuController(random: Random(5));
      controller.startGame(['A', 'B'], difficulty: SudokuDifficulty.kolay);
      final player = controller.players[0];
      final index = player.given.indexWhere((g) => !g);
      final wrong = player.solution[index] == sudokuSize
          ? 1
          : player.solution[index] + 1;

      controller.selectCell(index);
      for (var i = 0; i < sudokuMaxMistakes; i++) {
        controller.enterDigit(wrong);
      }

      expect(player.mistakeCount, sudokuMaxMistakes);
      expect(player.finished, isTrue);
      expect(player.isSolved, isFalse);
      expect(controller.currentPlayerIndex, 1);
      expect(controller.phase, SudokuGamePhase.turnTransition);
    },
  );

  test('Sudoku: given hücre seçilemez ve değiştirilemez', () {
    final controller = SudokuController(random: Random(6));
    controller.startGame(['A'], difficulty: SudokuDifficulty.kolay);
    final player = controller.players[0];
    final givenIndex = player.given.indexWhere((g) => g);
    final originalValue = player.values[givenIndex];

    controller.selectCell(givenIndex);

    expect(controller.selectedIndex, isNull);
    expect(player.values[givenIndex], originalValue);
  });

  test(
    'Sudoku: clearSelectedCell hücreyi hata sayısına dokunmadan sıfırlar',
    () {
      final controller = SudokuController(random: Random(7));
      controller.startGame(['A'], difficulty: SudokuDifficulty.kolay);
      final player = controller.players[0];
      final index = player.given.indexWhere((g) => !g);
      final wrong = player.solution[index] == sudokuSize
          ? 1
          : player.solution[index] + 1;

      controller.selectCell(index);
      controller.enterDigit(wrong);
      expect(player.values[index], wrong);
      expect(player.mistakeCount, 1);

      controller.clearSelectedCell();

      expect(player.values[index], 0);
      expect(player.mistakeCount, 1);
    },
  );

  testWidgets(
    'Sudoku setup: zorluk seçici ve ipucu metni görünür, oyunu başlatır',
    (WidgetTester tester) async {
      await _openSudoku(tester);

      expect(find.text('Kolay'), findsOneWidget);
      expect(find.text('Orta'), findsOneWidget);
      expect(find.text('Zor'), findsOneWidget);
      expect(find.textContaining('Zorluk:'), findsOneWidget);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      expect(find.textContaining('oynuyor'), findsOneWidget);
    },
  );

  testWidgets(
    'Sudoku: düzenlenebilir hücreye dokunup rakam girmek değeri günceller',
    (WidgetTester tester) async {
      await _openSudoku(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<SudokuController>(
        tester.element(find.byType(SudokuGameScreen)),
        listen: false,
      );
      final player = controller.currentPlayer;
      final editableIndex = player.given.indexWhere((g) => !g);
      final digit = player.solution[editableIndex];

      await tester.tap(find.byKey(ValueKey('sudokuCell_$editableIndex')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey(digit)));
      await tester.pump();

      expect(player.values[editableIndex], digit);
    },
  );

  testWidgets(
    'Sudoku: given hücreye dokunmak hiçbir şey değiştirmez',
    (WidgetTester tester) async {
      await _openSudoku(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<SudokuController>(
        tester.element(find.byType(SudokuGameScreen)),
        listen: false,
      );
      final player = controller.currentPlayer;
      final givenIndex = player.given.indexWhere((g) => g);
      final originalValue = player.values[givenIndex];

      await tester.tap(find.byKey(ValueKey('sudokuCell_$givenIndex')));
      await tester.pump();

      expect(controller.selectedIndex, isNull);
      expect(player.values[givenIndex], originalValue);
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
      // Taşlar Unicode sembolü olarak değil, dolgu + kontur çizen
      // ChessPieceGlyph ile çiziliyor (beyaz taşların içi şeffaf kalmasın
      // diye); bu yüzden sembol metni yerine taşın kendisi aranıyor.
      expect(_findPiece(PieceType.pawn, PieceColor.white), findsNWidgets(8));
      expect(_findPiece(PieceType.pawn, PieceColor.black), findsNWidgets(8));
      expect(_findPiece(PieceType.king, PieceColor.white), findsOneWidget);
      expect(_findPiece(PieceType.king, PieceColor.black), findsOneWidget);
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
    'Chess: ele geçirilen taş doğru tarafa yazılır ve taş puanı farkını '
    'günceller',
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

      // Beyaz bir piyon aldı: bu taş beyazın "capturedByWhite" listesinde
      // olmalı (kaybeden siyah olduğu için siyah tarafında görünecek olan
      // taş bu), siyah henüz hiçbir şey almadı.
      expect(controller.capturedByWhite, [
        const ChessPiece(PieceType.pawn, PieceColor.black),
      ]);
      expect(controller.capturedByBlack, isEmpty);
      expect(controller.materialDifference, 1);
    },
  );

  testWidgets(
    'Chess: iki taraf da taş aldığında taş puanı farkı ikisini birden '
    'yansıtır',
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
      // Beyaz kale d4 -> d7'de siyah atı alacak (3 puan).
      squares[squareIndex(3, 3)] = const ChessPiece(
        PieceType.rook,
        PieceColor.white,
      );
      squares[squareIndex(3, 6)] = const ChessPiece(
        PieceType.knight,
        PieceColor.black,
      );
      // Siyah kale a5 -> a2'de beyaz piyonu alacak (1 puan).
      squares[squareIndex(0, 4)] = const ChessPiece(
        PieceType.rook,
        PieceColor.black,
      );
      squares[squareIndex(0, 1)] = const ChessPiece(
        PieceType.pawn,
        PieceColor.white,
      );
      controller.board = ChessBoard.custom(squares: squares);

      controller.selectSquare(squareIndex(3, 3));
      controller.selectSquare(squareIndex(3, 6));
      controller.selectSquare(squareIndex(0, 4));
      controller.selectSquare(squareIndex(0, 1));

      expect(controller.capturedByWhite, [
        const ChessPiece(PieceType.knight, PieceColor.black),
      ]);
      expect(controller.capturedByBlack, [
        const ChessPiece(PieceType.pawn, PieceColor.white),
      ]);
      // Beyaz 3 puanlık at aldı, siyah 1 puanlık piyon aldı: fark 3-1=2,
      // beyaz öndedir.
      expect(controller.materialDifference, 2);
    },
  );

  testWidgets(
    'Chess: ele geçirilen taş paneli doğru simgeyi ve "+N" rozetini gösterir',
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
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('chessCapturedByWhite')),
          matching: _findPiece(PieceType.pawn, PieceColor.black),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('chessCapturedByWhite')),
          matching: find.text('+1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('chessCapturedByBlack')),
          matching: find.text('+1'),
        ),
        findsNothing,
      );
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

      await tester.tap(find.byKey(const ValueKey('promote_queen')));
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

  test('Chess: AI düşünme süresi 0.3-5 sn arasında ve karmaşıklıkla artar', () {
    final rng = Random(1);
    // Tek yasal hamleli dar pozisyon → tam alt sınır.
    final narrow = ChessBoard.fromFen('7k/8/8/8/8/8/5q2/7K w - - 0 1');
    expect(
      narrow.legalMoves(narrow.sideToMove).length,
      lessThanOrEqualTo(5),
    );
    expect(
      chessAiThinkTime(narrow, rng),
      const Duration(milliseconds: 300),
    );

    final wide = ChessBoard.initial();
    var max = Duration.zero;
    var min = const Duration(days: 1);
    for (var i = 0; i < 300; i++) {
      final t = chessAiThinkTime(wide, rng);
      expect(t, greaterThanOrEqualTo(const Duration(milliseconds: 300)));
      expect(t, lessThanOrEqualTo(const Duration(milliseconds: 5000)));
      if (t > max) max = t;
      if (t < min) min = t;
    }
    // Aynı pozisyonda süre rastgele değişir: hem kısa hem uzun düşünülür.
    expect(max - min, greaterThan(const Duration(seconds: 1)));
  });

  testWidgets('Chess: AI hamlesi düşünme süresi dolmadan oynanmaz', (
    WidgetTester tester,
  ) async {
    ChessController.aiThinkTimeScale = 1;
    addTearDown(() => ChessController.aiThinkTimeScale = 0);

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
    await tester.pump(const Duration(milliseconds: 200));
    // Alt sınır 300 ms + 150 ms başlangıç gecikmesi: hâlâ düşünüyor.
    expect(controller.aiThinking, isTrue);
    expect(controller.board.moveHistory, isEmpty);

    await tester.pump(const Duration(seconds: 6));
    expect(controller.aiThinking, isFalse);
    expect(controller.board.moveHistory, hasLength(1));
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

  testWidgets(
    'Chess: zorluk seçici yalnızca bilgisayara karşı modda görünür ve '
    'seçilen seviye oyuna geçer',
    (WidgetTester tester) async {
      await _openChess(tester);

      // 2 kişilik mod (varsayılan): zorluk seçici yok.
      expect(find.text('Zorluk: 3 · Orta'), findsNothing);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('Zorluk: 3 · Orta'), findsOneWidget);

      await tester.tap(find.text('5'));
      await tester.pump();
      expect(find.text('Zorluk: 5 · Çok Zor'), findsOneWidget);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );
      expect(controller.difficulty, ChessDifficulty.cokZor);
    },
  );

  testWidgets(
    'Chess: süre seçilince saat işler ve sırası gelen tarafınki azalır',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('5 dk'));
      await tester.pump();
      await tester.tap(find.text('Oyunu Başlat'));
      // Saat çalışırken pumpAndSettle asla "settle" etmez (her saniye yeni
      // bir frame planlanır), bu yüzden bu testte hep tek tek pump edilir.
      await tester.pump();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );
      expect(controller.timeControl, ChessTimeControl.fiveMinutes);
      expect(controller.whiteRemaining, const Duration(minutes: 5));
      expect(find.text('05:00'), findsNWidgets(2));

      await tester.pump(const Duration(seconds: 3));

      // Beyazın sırası: yalnızca beyazın saati işler.
      expect(controller.whiteRemaining, const Duration(seconds: 297));
      expect(controller.blackRemaining, const Duration(minutes: 5));
      expect(find.text('04:57'), findsOneWidget);
    },
  );

  testWidgets(
    'Chess: süresi biten taraf kaybeder',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('5 dk'));
      await tester.pump();
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );
      // 5 dakikayı gerçekten saymak yerine saati doğrudan son saniyeye
      // çekiyoruz (controller alanları public, testler doğrudan set eder).
      controller.whiteRemaining = const Duration(seconds: 1);
      await tester.pump(const Duration(seconds: 1));

      expect(controller.outcome, ChessOutcome.blackWins);
      expect(controller.outcomeReason, ChessOutcomeReason.timeout);
      expect(controller.phase, ChessGamePhase.finished);

      await tester.pumpAndSettle();
      expect(find.text('Süre bitti.'), findsOneWidget);
    },
  );

  testWidgets(
    'Chess: değerlendirme çubuğu taş üstünlüğünü yansıtır',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      // Başlangıç dizilimi simetrik: şans ~%50.
      expect(controller.whiteWinChance, closeTo(0.5, 0.05));
      expect(find.byType(ChessEvaluationBar), findsOneWidget);

      // Siyah vezirini kaybetmiş bir konumda çubuk beyaza kaymalı.
      final squares = List<ChessPiece?>.filled(64, null);
      squares[squareIndex(4, 0)] = const ChessPiece(
        PieceType.king,
        PieceColor.white,
      );
      squares[squareIndex(4, 7)] = const ChessPiece(
        PieceType.king,
        PieceColor.black,
      );
      squares[squareIndex(3, 0)] = const ChessPiece(
        PieceType.queen,
        PieceColor.white,
      );
      controller.board = ChessBoard.custom(squares: squares);
      controller.selectSquare(squareIndex(3, 0));
      controller.selectSquare(squareIndex(3, 1)); // vezirle bir hamle
      await tester.pumpAndSettle();

      expect(controller.whiteWinChance, greaterThan(0.9));
    },
  );

  test('Chess AI: her zorluk seviyesi geçerli bir hamle döndürür', () {
    final ai = ChessAI(random: Random(7));
    final board = ChessBoard.initial();
    final legal = board.legalMoves(PieceColor.white);
    for (final difficulty in ChessDifficulty.values) {
      final move = ai.findBestMove(board, difficulty: difficulty);
      expect(move, isNotNull, reason: '${difficulty.label} hamle üretmedi');
      expect(
        legal.any((m) => m.from == move!.from && m.to == move.to),
        isTrue,
        reason: '${difficulty.label} geçersiz hamle üretti',
      );
    }
  });

  testWidgets(
    'Chess: oynanan hamleler geçmiş panelinde görünür',
    (WidgetTester tester) async {
      await _openChess(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = Provider.of<ChessController>(
        tester.element(find.byType(ChessGameScreen)),
        listen: false,
      );

      expect(find.byType(ChessMoveHistory), findsOneWidget);
      expect(find.text('Henüz hamle\nyapılmadı'), findsOneWidget);

      // e2-e4, ardından siyah e7-e5.
      await tester.tap(find.byKey(ValueKey('sq_${squareIndex(4, 1)}')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('sq_${squareIndex(4, 3)}')));
      await tester.pumpAndSettle();

      expect(controller.moveNotations, ['e4']);
      expect(find.text('e4'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('sq_${squareIndex(4, 6)}')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('sq_${squareIndex(4, 4)}')));
      await tester.pumpAndSettle();

      expect(controller.moveNotations, ['e4', 'e5']);
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('e5'), findsOneWidget);
    },
  );

  testWidgets(
    'Chess: dar ekranda hamle geçmişi tahtanın altında şerit olur',
    (WidgetTester tester) async {
      // Yan panel eşiğinin (640) altında bir telefon genişliği; taşma olursa
      // debug'da exception atılır ve test kendiliğinden kırmızıya döner.
      // Yükseklik bilerek büyük: katalogdaki Satranç kartı tek sütunda çok
      // aşağıda kalıyor ve kısa bir görünümde dokunulamıyor. Eşik yalnızca
      // genişliğe baktığı için bu, dar ekran yerleşimini bozmuyor.
      tester.view.physicalSize = const Size(400, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GamePlatformApp());
      await tester.tap(find.text('Satranç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('sq_${squareIndex(4, 1)}')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('sq_${squareIndex(4, 3)}')));
      await tester.pumpAndSettle();

      final history = tester.widget<ChessMoveHistory>(
        find.byType(ChessMoveHistory),
      );
      expect(history.axis, Axis.horizontal);
      expect(find.text('1. e4'), findsOneWidget);
    },
  );

  test('Chess gösterimi: taş harfi, alma, rok, terfi ve şah ekleri', () {
    String notationFor(ChessBoard board, int from, int to, {PieceType? promo}) {
      final move = board
          .legalMoves(board.sideToMove)
          .firstWhere(
            (m) =>
                m.from == from &&
                m.to == to &&
                (promo == null || m.promotionType == promo),
          );
      return chessMoveNotation(
        before: board,
        move: move,
        after: board.applyMove(move),
      );
    }

    // Piyon ilerlemesi ve at hamlesi (Türkçe harf: At = A).
    final opening = ChessBoard.initial();
    expect(notationFor(opening, squareIndex(4, 1), squareIndex(4, 3)), 'e4');
    expect(notationFor(opening, squareIndex(6, 0), squareIndex(5, 2)), 'Af3');

    // Rok: beyaz şah e1, kale h1.
    final castleSquares = List<ChessPiece?>.filled(64, null);
    castleSquares[squareIndex(4, 0)] = const ChessPiece(
      PieceType.king,
      PieceColor.white,
    );
    castleSquares[squareIndex(7, 0)] = const ChessPiece(
      PieceType.rook,
      PieceColor.white,
    );
    castleSquares[squareIndex(4, 7)] = const ChessPiece(
      PieceType.king,
      PieceColor.black,
    );
    final castleBoard = ChessBoard.custom(
      squares: castleSquares,
      whiteKingsideRights: true,
    );
    expect(
      notationFor(castleBoard, squareIndex(4, 0), squareIndex(6, 0)),
      '0-0',
    );

    // Terfi + şah: a7 piyonu a8'de vezire çıkıp e8'deki şaha şah çeker.
    final promoSquares = List<ChessPiece?>.filled(64, null);
    promoSquares[squareIndex(4, 0)] = const ChessPiece(
      PieceType.king,
      PieceColor.white,
    );
    promoSquares[squareIndex(4, 7)] = const ChessPiece(
      PieceType.king,
      PieceColor.black,
    );
    promoSquares[squareIndex(0, 6)] = const ChessPiece(
      PieceType.pawn,
      PieceColor.white,
    );
    final promoBoard = ChessBoard.custom(squares: promoSquares);
    expect(
      notationFor(
        promoBoard,
        squareIndex(0, 6),
        squareIndex(0, 7),
        promo: PieceType.queen,
      ),
      'a8=V+',
    );

    // Alma: beyaz vezir d1'den d7'deki siyah piyonu alır.
    final captureSquares = List<ChessPiece?>.filled(64, null);
    captureSquares[squareIndex(4, 0)] = const ChessPiece(
      PieceType.king,
      PieceColor.white,
    );
    captureSquares[squareIndex(4, 7)] = const ChessPiece(
      PieceType.king,
      PieceColor.black,
    );
    captureSquares[squareIndex(3, 0)] = const ChessPiece(
      PieceType.queen,
      PieceColor.white,
    );
    captureSquares[squareIndex(3, 6)] = const ChessPiece(
      PieceType.pawn,
      PieceColor.black,
    );
    final captureBoard = ChessBoard.custom(squares: captureSquares);
    expect(
      notationFor(captureBoard, squareIndex(3, 0), squareIndex(3, 6)),
      'Vxd7+',
    );
  });

  test('Chess gösterimi: aynı kareye giden iki taşı ayırt eder', () {
    // a1 ve h1'deki iki beyaz kale de d1'e gidebilir → kalkış dosyası yazılır.
    final squares = List<ChessPiece?>.filled(64, null);
    squares[squareIndex(4, 4)] = const ChessPiece(
      PieceType.king,
      PieceColor.white,
    );
    squares[squareIndex(4, 7)] = const ChessPiece(
      PieceType.king,
      PieceColor.black,
    );
    squares[squareIndex(0, 0)] = const ChessPiece(
      PieceType.rook,
      PieceColor.white,
    );
    squares[squareIndex(7, 0)] = const ChessPiece(
      PieceType.rook,
      PieceColor.white,
    );
    final board = ChessBoard.custom(squares: squares);
    final move = board
        .legalMoves(PieceColor.white)
        .firstWhere(
          (m) => m.from == squareIndex(0, 0) && m.to == squareIndex(3, 0),
        );

    expect(
      chessMoveNotation(
        before: board,
        move: move,
        after: board.applyMove(move),
      ),
      'Kad1',
    );
  });

  test('Chess AI: süre bütçesi aramayı sınırlar', () {
    // Bütçe, senkron aramanın arayüzü kilitleme süresinin üst sınırı — en
    // yüksek seviyede bile aşılmamalı (bkz. ChessDifficulty).
    final ai = ChessAI(random: Random(1));
    final stopwatch = Stopwatch()..start();
    ai.findBestMove(ChessBoard.initial(), difficulty: ChessDifficulty.cokZor);
    stopwatch.stop();

    // Bütçe iki düğüm kontrolü arasında dolabildiği için bir miktar pay
    // bırakılıyor; asıl mesele 5 ply'ın ölçülen ~11 sn'sine düşmemesi.
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(ChessDifficulty.cokZor.timeBudgetMs * 2),
    );
  });

  testWidgets(
    'Çarpım Bahçesi: oyun ilk turda ızgarayı ve 4 seçeneği gösterir',
    (WidgetTester tester) async {
      await _openMultiplication(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      expect(find.textContaining('oynuyor'), findsOneWidget);
      expect(
        find.text('Tur 1 / $multiplicationRoundsPerPlayer'),
        findsOneWidget,
      );
      expect(find.byType(MultiplicationArrayView), findsOneWidget);

      // Turlar dönüşümlü: ilk tur her zaman okuma turudur.
      final controller = _multiplicationController(tester);
      expect(controller.currentTrial.kind, MultiplicationTrialKind.array);
      expect(controller.currentTrial.options, hasLength(4));
    },
  );

  testWidgets(
    'Çarpım Bahçesi: doğru cevaptan sonra açıklama paneli tekrarlı toplamayı '
    'gösterir ve tur ancak Devam ile ilerler',
    (WidgetTester tester) async {
      await _openMultiplication(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = _multiplicationController(tester);
      final trial = controller.currentTrial;

      await tester.tap(find.byKey(ValueKey(trial.answer)));
      await tester.pumpAndSettle();

      // Panel kendi kendine kapanmaz: puan işlendi ama tur hâlâ ekranda.
      expect(controller.showingExplanation, isTrue);
      expect(find.text('Doğru!'), findsOneWidget);
      expect(find.text(trial.repeatedAdditionText), findsOneWidget);

      await tester.tap(find.byKey(const Key('multiplicationContinue')));
      await tester.pumpAndSettle();

      expect(controller.currentPlayer.correctCount, 1);
      expect(controller.currentPlayer.roundsPlayed, 1);
      expect(controller.currentTrial.kind, MultiplicationTrialKind.build);
    },
  );

  testWidgets(
    'Çarpım Bahçesi: ters çevrilmiş ızgara da doğru sayılır ve açıklama '
    'değişme özelliğini anlatır',
    (WidgetTester tester) async {
      await _openMultiplication(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = _multiplicationController(tester);
      // 1. tur okuma; doğru cevaplayınca 2. tur kurma turu olur.
      await _answerMultiplicationCorrectly(tester, controller);
      expect(controller.currentTrial.kind, MultiplicationTrialKind.build);

      // Hedefi sabitliyoruz: rastgele üretilen tur kare (örn. 3 × 3) çıkarsa
      // "ters çevirmek" hedefin aynısı olur ve test anlamsızlaşırdı.
      controller.currentTrial = MultiplicationTrial(
        kind: MultiplicationTrialKind.build,
        rows: 2,
        columns: 3,
        context: multiplicationContexts.firstWhere(
          (scene) => scene.id == 'yumurta',
        ),
      );
      controller.buildRows = 3;
      controller.buildColumns = 2;

      await tester.tap(find.byKey(const Key('multiplicationConfirm')));
      await tester.pumpAndSettle();

      expect(controller.lastAnswerCorrect, isTrue);
      expect(controller.lastAnswerCommuted, isTrue);
      expect(controller.currentPlayer.correctCount, 2);
      expect(find.textContaining('sonucu değiştirmez'), findsOneWidget);
    },
  );

  test(
    'Çarpım Bahçesi: her seviyede hem okuma hem kurma turu için sahne bulunur',
    () {
      for (final difficulty in MultiplicationDifficulty.values) {
        final scenes = multiplicationContextsFor(difficulty);
        expect(
          scenes,
          isNotEmpty,
          reason: '${difficulty.label} seviyesinde hiç sahne yok',
        );

        // Okuma turu sahneleri: sabit sütunlu sahneler (örümceğin 8 bacağı)
        // seviyenin çarpan tavanına sığmalı, yoksa o seviyede hiç seçilemez.
        final readable = scenes.where(
          (scene) =>
              scene.fixedColumns == null ||
              scene.fixedColumns! <= difficulty.arrayMaxFactor,
        );
        expect(
          readable,
          isNotEmpty,
          reason: '${difficulty.label} seviyesinde okuma turu sahnesi yok',
        );

        // Kurma turunda tavan daha düşük ve sahnenin kurma yönergesi olmalı.
        final buildable = scenes.where(
          (scene) =>
              scene.isBuildable &&
              (scene.fixedColumns == null ||
                  scene.fixedColumns! <= difficulty.buildMaxFactor),
        );
        expect(
          buildable,
          isNotEmpty,
          reason: '${difficulty.label} seviyesinde kurma turu sahnesi yok',
        );
      }
    },
  );

  test('Çarpım Bahçesi: sahne cümlelerinde doldurulmamış yer tutucu kalmaz', () {
    for (final scene in multiplicationContexts) {
      final columns = scene.fixedColumns ?? 4;
      final texts = <String>[
        scene.questionFor(3, columns),
        scene.groupingFor(3, columns),
        scene.conclusionFor(3, columns),
        if (scene.isBuildable) scene.buildPromptFor(3, columns)!,
      ];
      for (final text in texts) {
        expect(
          text,
          isNot(contains('{')),
          reason: '${scene.id} sahnesinde doldurulmamış yer tutucu var: $text',
        );
      }
      // Sonuç cümlesi sayıyı gerçekten söylemeli, yoksa panel sahneyi
      // matematiğe bağlamıyor demektir.
      expect(
        scene.conclusionFor(3, columns),
        contains('${3 * columns}'),
        reason: '${scene.id} sahnesinin sonuç cümlesi sonucu içermiyor',
      );
    }
  });

  test(
    'Çarpım Bahçesi: üretilen turlar seviyenin sahnelerinden ve tavanından '
    'çıkar',
    () {
      for (final difficulty in MultiplicationDifficulty.values) {
        final controller = MultiplicationController(random: Random(7));
        controller.startGame(['Test'], difficulty: difficulty);

        // 8 turun tamamını oynayıp her turun ürettiği sahneyi denetliyoruz;
        // tek tur bakmak sahne havuzunun tamamını örneklemezdi.
        for (var round = 0; round < multiplicationRoundsPerPlayer; round++) {
          final trial = controller.currentTrial;
          expect(
            trial.context.levels,
            contains(difficulty),
            reason: '${trial.context.id} sahnesi ${difficulty.label} '
                'seviyesine ait değil',
          );

          final maxFactor = trial.kind == MultiplicationTrialKind.array
              ? difficulty.arrayMaxFactor
              : difficulty.buildMaxFactor;
          expect(trial.rows, inInclusiveRange(2, maxFactor));
          if (trial.context.fixedColumns != null) {
            // Sahnenin doğasından gelen sütun sayısı (bisiklet 2, hafta 7)
            // rastgeleye çevrilmemeli.
            expect(trial.columns, trial.context.fixedColumns);
          } else {
            expect(trial.columns, inInclusiveRange(2, maxFactor));
          }
          expect(trial.columns, lessThanOrEqualTo(maxFactor));
          if (trial.kind == MultiplicationTrialKind.build) {
            expect(trial.context.isBuildable, isTrue);
            expect(trial.buildPrompt, isNotNull);
          }

          // Turu doğru cevaplayıp bir sonrakine geç.
          if (trial.kind == MultiplicationTrialKind.array) {
            controller.answerArray(trial.answer);
          } else {
            controller.buildRows = trial.rows;
            controller.buildColumns = trial.columns;
            controller.submitBuild();
          }
          controller.continueAfterExplanation();
        }

        expect(controller.players.first.correctCount,
            multiplicationRoundsPerPlayer);
      }
    },
  );

  testWidgets(
    'Çarpım Bahçesi: soru ve açıklama sahnenin gerçek hayat cümlelerini '
    'kullanır',
    (WidgetTester tester) async {
      await _openMultiplication(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = _multiplicationController(tester);
      final trial = controller.currentTrial;

      expect(find.text(trial.sceneQuestion), findsOneWidget);
      // Sahne başlığı ("🧁  Kek kalıbı") ayrı bir Text'tir; ama soru cümlesi de
      // başlığı içerebilir ("Kek kalıbında 5 sıra…"), bu yüzden textContaining
      // rastgele sahnelerde iki widget bulup testi kararsızlaştırıyordu.
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').endsWith(trial.context.title),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ValueKey(trial.answer)));
      await tester.pumpAndSettle();

      expect(find.text(trial.sceneConclusion), findsOneWidget);
    },
  );

  testWidgets(
    'Çarpım Bahçesi: 1 Kişi tamamlanınca sonuç ekranında doğru sayısı görünür',
    (WidgetTester tester) async {
      await _openMultiplication(tester);

      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      expect(find.text('2. Oyuncu adı'), findsNothing);

      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = _multiplicationController(tester);
      expect(controller.players, hasLength(1));

      for (var round = 0; round < multiplicationRoundsPerPlayer; round++) {
        await _answerMultiplicationCorrectly(tester, controller);
      }
      await tester.pumpAndSettle();

      expect(find.text('Sonuçlar'), findsOneWidget);
      expect(find.textContaining('Tebrikler, 1. Oyuncu!'), findsOneWidget);
      expect(
        find.text(
          '$multiplicationRoundsPerPlayer / '
          '$multiplicationRoundsPerPlayer doğru',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Çarpım Bahçesi: Zor seviyenin 12 × 12 ızgarası dar telefonda taşmaz',
    (WidgetTester tester) async {
      // En kötü durum: en büyük çarpanlar (MultiplicationDifficulty.zor) +
      // birikimli toplam etiketleri + gerçek hayat sahnelerinin iki kenar
      // şeridi (sıra başı grup emojisi, sütun başlığı) + birim ekli toplam
      // etiketi + dar bir telefon. Taşma debug'da exception attığından ayrıca
      // assert etmeye gerek yok.
      tester.view.physicalSize = const Size(320, 560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: MultiplicationArrayView(
                rows: 12,
                columns: 12,
                emoji: '🍎',
                showRunningTotals: true,
                rowLeadingEmoji: '🎁',
                columnHeaderEmoji: '👖',
                totalUnit: ' m²',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MultiplicationArrayView), findsOneWidget);
    },
  );

  testWidgets(
    'Çarpım Bahçesi: 2 Kişi — ilk oyuncu bitirince sıra ikinciye geçer',
    (WidgetTester tester) async {
      await _openMultiplication(tester);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pumpAndSettle();

      final controller = _multiplicationController(tester);

      for (var round = 0; round < multiplicationRoundsPerPlayer; round++) {
        await _answerMultiplicationCorrectly(tester, controller);
      }
      await tester.pumpAndSettle();

      expect(controller.players[0].correctCount, multiplicationRoundsPerPlayer);
      expect(find.text('Hazırım'), findsOneWidget);

      await tester.tap(find.text('Hazırım'));
      await tester.pumpAndSettle();

      expect(controller.currentPlayerIndex, 1);
      expect(find.textContaining('2. Oyuncu oynuyor'), findsOneWidget);
    },
  );

  group('Satranç dersleri', () {
    test('FEN başlangıç pozisyonu ChessBoard.initial() ile aynı', () {
      final fen = ChessBoard.fromFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      final initial = ChessBoard.initial();
      for (var i = 0; i < 64; i++) {
        expect(fen.squares[i], initial.squares[i], reason: 'kare $i');
      }
      expect(fen.sideToMove, PieceColor.white);
      expect(fen.whiteKingsideRights, isTrue);
      expect(fen.blackQueensideRights, isTrue);
      expect(fen.enPassantTargetSquare, isNull);
    });

    test('FEN geçerken alma karesini ve sırayı okur', () {
      final board = ChessBoard.fromFen('7k/8/8/3pP3/8/8/8/4K3 b - d6 0 1');
      expect(board.sideToMove, PieceColor.black);
      expect(board.enPassantTargetSquare, squareFromName('d6'));
      expect(board.squares[squareFromName('e5')]?.type, PieceType.pawn);
    });

    test('ders verisi tutarlı: her alıştırma çözülebilir', () {
      final ids = chessLessons.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'ders kimlikleri tekil');
      for (final level in ChessLessonLevel.values) {
        expect(
          chessLessons.where((l) => l.level == level),
          isNotEmpty,
          reason: '${level.label} seviyesinde ders olmalı',
        );
      }

      for (final lesson in chessLessons) {
        expect(lesson.steps, isNotEmpty, reason: lesson.id);
        for (var i = 0; i < lesson.steps.length; i++) {
          final where = '${lesson.id} adım ${i + 1}';
          final step = lesson.steps[i];
          switch (step) {
            case LessonInfoStep():
              if (step.fen != null) ChessBoard.fromFen(step.fen!);
              for (final h in step.highlights) {
                squareFromName(h);
              }
            case LessonQuizStep():
              if (step.fen != null) ChessBoard.fromFen(step.fen!);
              expect(step.options.length, greaterThanOrEqualTo(2), reason: where);
              expect(
                step.correctIndex,
                inInclusiveRange(0, step.options.length - 1),
                reason: where,
              );
            case LessonMarkStep():
              final board = ChessBoard.fromFen(step.fen);
              final square = squareFromName(step.pieceSquare);
              expect(board.squares[square], isNotNull, reason: where);
              expect(board.legalMovesFrom(square), isNotEmpty, reason: where);
            case LessonMoveStep():
              final board = ChessBoard.fromFen(step.fen);
              for (final h in step.highlights) {
                squareFromName(h);
              }
              expect(
                step.accepted.isNotEmpty || step.anyMate,
                isTrue,
                reason: '$where: kabul edilen hamle yok',
              );
              final legal = board.legalMoves(board.sideToMove);
              for (final move in step.accepted) {
                expect(
                  legal.any(
                    (m) =>
                        m.from == squareFromName(move.substring(0, 2)) &&
                        m.to == squareFromName(move.substring(2, 4)),
                  ),
                  isTrue,
                  reason: '$where: $move yasal değil',
                );
              }
              if (step.anyMate) {
                expect(
                  legal.any((m) => board.applyMove(m).isCheckmate),
                  isTrue,
                  reason: '$where: mat eden hamle yok',
                );
              }
          }
        }
      }
    });

    test('İşaretleme adımı: eksik kare hata verir, tam küme çözer', () {
      final lesson = chessLessons.firstWhere((l) => l.id == 'b2');
      final c = ChessLessonController(lesson);
      c.next(); // kale anlatımı → işaretleme
      expect(c.step, isA<LessonMarkStep>());
      // Kale d4: d5, d3, d2, d1, c4, b4 (alma), e4, f4, g4, h4.
      for (final n in ['d5', 'd3', 'd2', 'd1', 'c4', 'b4', 'e4', 'f4', 'g4']) {
        c.tapSquare(squareFromName(n));
      }
      c.checkMarks();
      expect(c.solved, isFalse);
      expect(c.feedback, contains('Eksik'));
      c.tapSquare(squareFromName('h4'));
      c.checkMarks();
      expect(c.solved, isTrue);
    });

    testWidgets('Ders akışı: quiz, hamle, yanlış hamle ve tamamlama', (
      tester,
    ) async {
      final progress = ChessLessonProgress();
      final lesson = chessLessons.firstWhere((l) => l.id == 'b1');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ChessLessonScreen(lesson: lesson, progress: progress),
                    ),
                  ),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();

      Future<void> tapContinue() async {
        await tester.ensureVisible(find.byKey(const Key('lessonContinue')));
        await tester.tap(find.byKey(const Key('lessonContinue')));
        await tester.pumpAndSettle();
      }

      // Adım 1 (anlatım) → 2 (quiz).
      await tapContinue();
      // Yanlış seçenek: geri bildirim var ama devam kapalı.
      await tester.tap(find.byKey(const ValueKey('lessonOption_0')));
      await tester.pumpAndSettle();
      expect(find.text('Olmadı, tekrar dene.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('lessonContinue')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('lessonOption_1')));
      await tester.pumpAndSettle();
      await tapContinue();
      await tapContinue(); // anlatım 3 → 4
      await tapContinue(); // anlatım 4 → quiz 5
      await tester.tap(find.byKey(const ValueKey('lessonOption_1')));
      await tester.pumpAndSettle();
      await tapContinue(); // → hamle adımı

      Future<void> tapSquare(String name) async {
        final finder = find.byKey(ValueKey('sq_${squareFromName(name)}'));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      // Yanlış (yasal ama hedef değil) hamle: e2-e3 → sıfırlanır.
      await tapSquare('e2');
      await tapSquare('e3');
      expect(find.byKey(const Key('lessonFeedback')), findsOneWidget);
      expect(find.textContaining('hedef değildi'), findsOneWidget);
      expect(find.text('Dersi Bitir'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('lessonContinue')))
            .onPressed,
        isNull,
      );

      // Doğru hamle: e2-e4.
      await tapSquare('e2');
      await tapSquare('e4');
      expect(find.textContaining('Harika'), findsOneWidget);

      await tapContinue();
      expect(find.text('aç'), findsOneWidget);
      expect(progress.completed, contains('b1'));
    });
  });

  group('Satranç hamle sesleri', () {
    test('Tarif her çalınışta frekans ve kazancı en fazla %5 saptırır', () {
      final rng = Random(3);
      for (var i = 0; i < 200; i++) {
        final r = captureRecipe.randomized(rng);
        expect(r.gain / captureRecipe.gain, inInclusiveRange(0.95, 1.05));
        expect(
          r.bodyModes.first.hz / captureRecipe.bodyModes.first.hz,
          inInclusiveRange(0.95, 1.05),
        );
        // Harmonik oranı korunur: 450 / 650 aynı çarpanla kayar.
        expect(
          r.bodyModes[1].hz / r.bodyModes[0].hz,
          closeTo(650 / 450, 1e-9),
        );
      }
      final a = normalMoveRecipe.randomized(Random(1));
      final b = normalMoveRecipe.randomized(Random(2));
      expect(a.gain, isNot(b.gain));
    });

    test('Sentezleyici üç ses için geçerli, duyulur ve bitişi sönük WAV üretir', () {
      const sampleRate = 44100;
      final lengths = <ChessMoveSoundKind, int>{};
      for (final kind in ChessMoveSoundKind.values) {
        final recipe = recipeFor(kind);
        final wav = renderMoveSoundWav(recipe, Random(5), sampleRate: sampleRate);
        final bytes = ByteData.sublistView(wav);
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
        final samples = (wav.length - 44) ~/ 2;
        expect(bytes.getUint32(40, Endian.little), samples * 2);
        lengths[kind] = samples;

        var peak = 0;
        for (var i = 0; i < samples; i++) {
          peak = max(peak, bytes.getInt16(44 + i * 2, Endian.little).abs());
        }
        expect(peak, greaterThan(3000), reason: '$kind duyulmalı');
        expect(peak, lessThanOrEqualTo(32767), reason: '$kind kırpılmamalı');

        // Son 10 ms neredeyse sessiz: tık sesi ("pop") kalmamalı.
        var tailPeak = 0;
        for (var i = samples - sampleRate ~/ 100; i < samples; i++) {
          tailPeak = max(tailPeak, bytes.getInt16(44 + i * 2, Endian.little).abs());
        }
        expect(tailPeak, lessThan(peak ~/ 20), reason: '$kind kuyruğu sönmeli');
      }
      // Süre sıralaması tariflerle uyumlu: yeme > normal, şah en uzun.
      expect(lengths[ChessMoveSoundKind.capture]!,
          greaterThan(lengths[ChessMoveSoundKind.normal]!));
      expect(lengths[ChessMoveSoundKind.check]!,
          greaterThan(lengths[ChessMoveSoundKind.capture]!));
    });

    test('Aynı ses iki çalınışta birebir aynı değildir', () {
      final a = renderMoveSoundWav(
        normalMoveRecipe.randomized(Random(1)),
        Random(1),
      );
      final b = renderMoveSoundWav(
        normalMoveRecipe.randomized(Random(2)),
        Random(2),
      );
      expect(a, isNot(b));
    });

    test('Controller hamleye göre normal / yeme / şah sesi seçer', () {
      final fake = _FakeMoveSounds();
      final c = ChessController(moveSounds: fake);
      c.startGame(
        mode: ChessMode.twoPlayer,
        whiteName: 'A',
        blackName: 'B',
      );

      void play(String from, String to) {
        c.selectSquare(squareFromName(from));
        c.selectSquare(squareFromName(to));
      }

      play('e2', 'e4'); // boş kare
      expect(fake.calls, ['normal']);

      c.board = ChessBoard.fromFen('4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1');
      play('e4', 'd5'); // yeme
      expect(fake.calls.last, 'capture');

      c.board = ChessBoard.fromFen('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      play('a1', 'a8'); // şah (yeme değil)
      expect(fake.calls.last, 'check');

      c.board = ChessBoard.fromFen('r3k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      play('a1', 'a8'); // hem yeme hem şah → şah sesi
      expect(fake.calls.last, 'check');

      c.dispose();
      expect(fake.disposed, isTrue);
    });
  });

  group('Bitki Laboratuvarı', () {
    test('bitki tablosu tutarlı: 3 kademe, 0-1 skor, tek en iyi kademe', () {
      final ids = plantCatalog.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'bitki kimlikleri tekil');
      for (final species in plantCatalog) {
        for (final factor in PlantFactor.values) {
          final scores = species.scoresOf(factor);
          final where = '${species.id} ${factor.name}';
          expect(scores.length, plantLevelCount, reason: where);
          for (final score in scores) {
            expect(score, inInclusiveRange(0.0, 1.0), reason: where);
          }
          final best = scores.reduce(max);
          expect(best, 1.0, reason: '$where: en iyi kademe 1.0 olmalı');
          expect(
            scores.where((s) => s == best).length,
            1,
            reason: '$where: tek bir en iyi kademe olmalı',
          );
          // Doktor turu her etken için en az bir "belirgin bozuk" kademe arar.
          final ideal = species.idealLevelOf(factor);
          expect(
            [
              for (var l = 0; l < plantLevelCount; l++)
                if (l != ideal && scores[l] <= 0.5) l,
            ],
            isNotEmpty,
            reason: '$where: bozuk kademe yok',
          );
        }
        expect(species.overallScore(species.idealConditions), 1.0);
      }
    });

    test('büyüme: ideal koşul her tek-etken bozulmasından daha uzun bitki verir',
        () {
      for (final species in plantCatalog) {
        final ideal = species.idealConditions;
        final idealHeight = simulatePlant(
          species,
          ideal,
          plantExperimentWeeks.toDouble(),
        ).heightCm;
        expect(idealHeight, closeTo(species.maxHeightCm, 0.001));
        for (final factor in PlantFactor.values) {
          for (var level = 0; level < plantLevelCount; level++) {
            if (level == species.idealLevelOf(factor)) continue;
            final height = simulatePlant(
              species,
              ideal.withLevel(factor, level),
              plantExperimentWeeks.toDouble(),
            ).heightCm;
            expect(
              height,
              lessThan(idealHeight),
              reason: '${species.id} ${factor.name} $level',
            );
          }
        }
      }
    });

    test('büyüme: zamanla boy artar ve simülasyon deterministiktir', () {
      final species = plantCatalog.first;
      final ideal = species.idealConditions;
      var previous = 0.0;
      for (var day = 0; day <= plantExperimentWeeks; day++) {
        final a = simulatePlant(species, ideal, day.toDouble());
        final b = simulatePlant(species, ideal, day.toDouble());
        expect(a.heightCm, b.heightCm);
        expect(a.heightCm, greaterThanOrEqualTo(previous));
        previous = a.heightCm;
      }
    });

    test('gerçekçi sonuçlar: kaktüs az suda büyür, çok suda çürür', () {
      final cactus = plantCatalog.firstWhere((s) => s.id == 'kaktus');
      final ideal = cactus.idealConditions;
      final dry = simulatePlant(
        cactus,
        ideal.withLevel(PlantFactor.water, 0),
        10,
      );
      final wet = simulatePlant(
        cactus,
        ideal.withLevel(PlantFactor.water, 2),
        10,
      );
      expect(dry.heightCm, greaterThan(wet.heightCm));
      expect(dry.health, PlantHealth.healthy);
      expect(wet.health, PlantHealth.rotting);
    });

    test('görünüm: ışıksız → soluk, susuz → solmuş, soğuk → yavaş', () {
      final bean = plantCatalog.firstWhere((s) => s.id == 'fasulye');
      final ideal = bean.idealConditions;
      expect(
        simulatePlant(bean, ideal.withLevel(PlantFactor.light, 0), 10).health,
        PlantHealth.pale,
      );
      expect(
        simulatePlant(bean, ideal.withLevel(PlantFactor.water, 0), 10).health,
        PlantHealth.wilted,
      );
      expect(
        simulatePlant(
          bean,
          ideal.withLevel(PlantFactor.temperature, 0),
          10,
        ).health,
        PlantHealth.slow,
      );
      // İlk günlerde belirti yok: bitki henüz sağlıklı görünür.
      expect(
        simulatePlant(bean, ideal.withLevel(PlantFactor.light, 0), 1).health,
        PlantHealth.healthy,
      );
    });

    test('koşullar: differingFactors ve withLevel', () {
      const a = PlantConditions(
        light: 2,
        water: 1,
        temperature: 1,
        altitude: 0,
      );
      final b = a.withLevel(PlantFactor.water, 0);
      expect(a.differingFactors(b), [PlantFactor.water]);
      expect(a.differingFactors(a), isEmpty);
      expect(a == a.withLevel(PlantFactor.light, 2), isTrue);
    });

    test('deney turları adil ve tahmin edilebilir, doktor turları tek nedenli',
        () {
      for (var seed = 0; seed < 30; seed++) {
        final controller = PlantLabController(random: Random(seed));
        controller.startGame(['A']);
        for (var round = 0; round < plantLabRoundsPerPlayer; round++) {
          final trial = controller.currentTrial;
          final species = trial.species;
          if (trial.kind == PlantLabTrialKind.experiment) {
            expect(round.isEven, isTrue);
            expect(
              trial.potA.differingFactors(trial.potB),
              [trial.factor],
              reason: 'adil deney: yalnızca test edilen etken farklı',
            );
            final heightA = simulatePlant(species, trial.potA, 10).heightCm;
            final heightB = simulatePlant(species, trial.potB, 10).heightCm;
            expect(
              (heightA - heightB).abs(),
              greaterThanOrEqualTo(species.maxHeightCm * 0.12),
              reason: 'tahmin gözle ayırt edilebilmeli',
            );
            expect(trial.outcome, isNot(PlantPrediction.same));
            controller.answerPrediction(trial.outcome);
          } else {
            expect(round.isOdd, isTrue);
            final ideal = species.idealConditions;
            expect(trial.potB, ideal);
            expect(trial.potA.differingFactors(ideal), [trial.factor]);
            final sick = simulatePlant(species, trial.potA, 10);
            expect(sick.health, isNot(PlantHealth.healthy));
            controller.answerDoctor(trial.factor);
          }
          expect(controller.lastAnswerCorrect, isTrue);
          controller.continueAfterResult();
        }
        expect(controller.phase, PlantLabPhase.finished);
      }
    });

    test('bir oyuncu dört deneyde dört etkeni de birer kez görür', () {
      final controller = PlantLabController(random: Random(3));
      controller.startGame(['A']);
      final factors = <PlantFactor>{};
      for (var round = 0; round < plantLabRoundsPerPlayer; round++) {
        final trial = controller.currentTrial;
        if (trial.kind == PlantLabTrialKind.experiment) {
          factors.add(trial.factor);
          controller.answerPrediction(trial.outcome);
        } else {
          controller.answerDoctor(trial.factor);
        }
        controller.continueAfterResult();
      }
      expect(factors, PlantFactor.values.toSet());
    });

    test('istenen bitkiler katalogda var ve en az 25 bitki bulunur', () {
      final ids = plantCatalog.map((s) => s.id).toSet();
      for (final id in [
        'cilek',
        'limon',
        'karpuz',
        'seftali',
        'muz',
        'cay',
        'kahve',
        'bugday',
        'pirinc',
      ]) {
        expect(ids, contains(id));
      }
      expect(plantCatalog.length, greaterThanOrEqualTo(25));
    });

    test('yükseklik etkeni: kahve yüksekte, muz ve pirinç alçakta iyi büyür', () {
      double heightAt(String id, int level) {
        final species = plantCatalog.firstWhere((s) => s.id == id);
        return simulatePlant(
          species,
          species.idealConditions.withLevel(PlantFactor.altitude, level),
          plantExperimentWeeks.toDouble(),
        ).heightCm;
      }

      // Kahve: yüksek > orta > alçak.
      expect(heightAt('kahve', 2), greaterThan(heightAt('kahve', 1)));
      expect(heightAt('kahve', 1), greaterThan(heightAt('kahve', 0)));
      // Muz, pirinç ve limon: alçak > yüksek.
      for (final id in ['muz', 'pirinc', 'limon']) {
        expect(heightAt(id, 0), greaterThan(heightAt(id, 2)), reason: id);
      }
      // Çay: en iyisi orta yükseklik.
      final tea = plantCatalog.firstWhere((s) => s.id == 'cay');
      expect(tea.idealLevelOf(PlantFactor.altitude), 1);

      // Yanlış yükseklikte bitki "cılız" görünür.
      final coffee = plantCatalog.firstWhere((s) => s.id == 'kahve');
      final lowland = simulatePlant(
        coffee,
        coffee.idealConditions.withLevel(PlantFactor.altitude, 0),
        plantExperimentWeeks.toDouble(),
      );
      expect(lowland.health, PlantHealth.weak);
    });

    test('yanlış cevap puan vermez ama turu ilerletir; tur tipi korunur', () {
      final controller = PlantLabController(random: Random(1));
      controller.startGame(['A']);
      final trial = controller.currentTrial;
      expect(trial.kind, PlantLabTrialKind.experiment);

      // Yanlış tahmin: doğru olmayan bir seçenek.
      final wrong = PlantPrediction.values.firstWhere((p) => p != trial.outcome);
      controller.answerPrediction(wrong);
      expect(controller.lastAnswerCorrect, isFalse);
      expect(controller.currentPlayer.correctCount, 0);
      expect(controller.currentPlayer.roundsPlayed, 1);
      expect(controller.showingResult, isTrue);

      // Açıklama açıkken ikinci cevap sayılmaz.
      controller.answerPrediction(trial.outcome);
      expect(controller.currentPlayer.roundsPlayed, 1);

      controller.continueAfterResult();
      expect(controller.showingResult, isFalse);
      expect(controller.currentTrial.kind, PlantLabTrialKind.doctor);

      // Doktor turunda deney cevabı yok sayılır.
      controller.answerPrediction(PlantPrediction.a);
      expect(controller.currentPlayer.roundsPlayed, 1);
    });

    test('iki oyunculu oyun: sıra devri ve sonuç sıralaması', () {
      final controller = PlantLabController(random: Random(5));
      controller.startGame(['A', 'B']);

      void playRound({required bool correct}) {
        final trial = controller.currentTrial;
        if (trial.kind == PlantLabTrialKind.experiment) {
          controller.answerPrediction(
            correct
                ? trial.outcome
                : PlantPrediction.values.firstWhere((p) => p != trial.outcome),
          );
        } else {
          controller.answerDoctor(
            correct
                ? trial.factor
                : PlantFactor.values.firstWhere((f) => f != trial.factor),
          );
        }
        controller.continueAfterResult();
      }

      for (var i = 0; i < plantLabRoundsPerPlayer; i++) {
        playRound(correct: true);
      }
      expect(controller.phase, PlantLabPhase.turnTransition);
      expect(controller.currentPlayerIndex, 1);
      controller.acknowledgeTurnTransition();
      expect(controller.phase, PlantLabPhase.playing);
      // İkinci oyuncu yeniden deney turuyla başlar.
      expect(controller.currentTrial.kind, PlantLabTrialKind.experiment);

      for (var i = 0; i < plantLabRoundsPerPlayer; i++) {
        playRound(correct: false);
      }
      expect(controller.phase, PlantLabPhase.finished);
      final ranked = controller.rankedByCorrect;
      expect(ranked.first.name, 'A');
      expect(ranked.first.correctCount, plantLabRoundsPerPlayer);
      expect(ranked.last.correctCount, 0);

      controller.restart();
      expect(controller.phase, PlantLabPhase.setup);
    });

    test('serbest laboratuvar: ayarla, adil deney kontrolü, çalıştır', () {
      final controller = PlantLabController(random: Random(2));
      controller.startFreeLab();
      expect(controller.phase, PlantLabPhase.freeLab);
      expect(controller.freeDifferingFactors, isEmpty);

      controller.setFreeCondition(
        potA: false,
        factor: PlantFactor.light,
        level: 0,
      );
      expect(controller.freeDifferingFactors, [PlantFactor.light]);

      controller.setFreeCondition(
        potA: false,
        factor: PlantFactor.water,
        level: 2,
      );
      expect(controller.freeDifferingFactors.length, 2);

      controller.runFreeExperiment();
      expect(controller.freeStarted, isTrue);
      expect(controller.freeRunCount, 1);

      // Ayar değişince gözlem kapanır; bitki değişince iki saksı da idealine döner.
      controller.setFreeCondition(
        potA: true,
        factor: PlantFactor.temperature,
        level: 2,
      );
      expect(controller.freeStarted, isFalse);
      final other = plantCatalog.last;
      controller.setFreeSpecies(other);
      expect(controller.freePotA, other.idealConditions);
      expect(controller.freePotB, other.idealConditions);

      controller.restart();
      expect(controller.phase, PlantLabPhase.setup);
    });

    testWidgets('katalogda kart var; 1 kişilik oyun deney + doktor turlarını oynatır',
        (tester) async {
      await _openPlantLab(tester);
      expect(find.text('1 Kişi'), findsOneWidget);
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plantLabStart')));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).last);
      final controller = context.read<PlantLabController>();
      expect(controller.phase, PlantLabPhase.playing);

      for (var round = 0; round < plantLabRoundsPerPlayer; round++) {
        if (round.isEven) {
          expect(find.byKey(const Key('plantPredictA')), findsOneWidget);
          await tester.tap(find.byKey(const Key('plantPredictA')));
        } else {
          expect(
            find.byKey(const Key('plantDoctor_light')),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('plantDoctor_light')));
        }
        // Sonuç paneli: zaman atlamalı animasyon biter, açıklama ve Devam görünür.
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('plantExplanation')), findsOneWidget);
        expect(find.byKey(const Key('plantDaySlider')), findsOneWidget);
        await tester.tap(find.byKey(const Key('plantLabContinue')));
        await tester.pumpAndSettle();
      }

      expect(controller.phase, PlantLabPhase.finished);
      expect(find.text('Tebrikler, 1. Oyuncu!'), findsOneWidget);
    });

    testWidgets('serbest laboratuvar: saksıyı ayarla ve deneyi başlat',
        (tester) async {
      await _openPlantLab(tester);
      await tester.tap(find.byKey(const Key('plantLabFreeLab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('plantDaySlider')), findsNothing);
      await tester.tap(find.byKey(const Key('potB_light_0')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Adil deney!'), findsOneWidget);

      await tester.tap(find.byKey(const Key('plantFreeStart')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('plantDaySlider')), findsOneWidget);
      expect(find.textContaining('Boy:'), findsNWidgets(2));
    });

    testWidgets('dar ekranda (320 px) sonuç paneli taşmaz', (tester) async {
      // Katalog ekranı bu testte ilgilendiğimiz şey değil; oyuna geniş ekranda
      // girip yalnızca oyun ekranlarını dar genişlikte sınıyoruz.
      await _openPlantLab(tester);
      tester.view.physicalSize = const Size(320, 3000);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plantLabStart')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plantPredictB')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('plantLabContinue')), findsOneWidget);
    });
  });

  group('Elektrik Atölyesi', () {
    test('simülasyon: açık anahtar ya da yalıtkan malzeme ampulü söndürür', () {
      const open = CircuitSpec(switchClosed: false);
      expect(simulateCircuit(open).anyLit, isFalse);
      expect(simulateCircuit(open).current, 0);

      final insulator = electricMaterials.firstWhere((m) => !m.conductive);
      final conductor = electricMaterials.firstWhere((m) => m.conductive);
      expect(simulateCircuit(CircuitSpec(material: insulator)).anyLit, isFalse);
      expect(simulateCircuit(CircuitSpec(material: conductor)).anyLit, isTrue);
      expect(simulateCircuit(const CircuitSpec()).anyLit, isTrue);
    });

    test('simülasyon: her malzeme kendi iletkenliğine göre devreyi kapatır', () {
      for (final material in electricMaterials) {
        final result = simulateCircuit(CircuitSpec(material: material));
        expect(result.anyLit, material.conductive, reason: material.id);
      }
    });

    test('simülasyon: seri ampuller sönükleşir, paralel ampuller sönmez', () {
      final one = simulateCircuit(const CircuitSpec(batteries: 2, lampCount: 1));
      final seriesTwo = simulateCircuit(
        const CircuitSpec(batteries: 2, lampCount: 2),
      );
      final seriesThree = simulateCircuit(
        const CircuitSpec(batteries: 2, lampCount: 3),
      );
      final parallelTwo = simulateCircuit(
        const CircuitSpec(
          batteries: 2,
          lampCount: 2,
          layout: LampLayout.parallel,
        ),
      );
      expect(seriesTwo.brightness.first, lessThan(one.brightness.first));
      expect(seriesThree.brightness.first, lessThan(seriesTwo.brightness.first));
      expect(parallelTwo.brightness.first, one.brightness.first);
      // Paralel devre pili daha çok harcar.
      expect(parallelTwo.current, greaterThan(seriesTwo.current));
    });

    test('simülasyon: fazla pil ampulü patlatır, çok pil daha parlak yakar', () {
      final burn = simulateCircuit(const CircuitSpec(batteries: 3));
      expect(burn.states.single, LampState.burnt);
      expect(burn.anyLit, isFalse);

      final two = simulateCircuit(const CircuitSpec(batteries: 2, lampCount: 2));
      final three = simulateCircuit(const CircuitSpec(batteries: 3, lampCount: 2));
      expect(three.brightness.first, greaterThan(two.brightness.first));
    });

    test('simülasyon: patlak ampul seride hepsini söndürür, paralelde söndürmez',
        () {
      final series = simulateCircuit(
        const CircuitSpec(lampCount: 3, burntLamp: 0),
      );
      expect(series.anyLit, isFalse);

      final parallel = simulateCircuit(
        const CircuitSpec(
          lampCount: 3,
          layout: LampLayout.parallel,
          burntLamp: 0,
        ),
      );
      expect(parallel.states[0], LampState.burnt);
      expect(parallel.states[1].isLit, isTrue);
      expect(parallel.states[2].isLit, isTrue);
    });

    test('simülasyon: deterministik ve açıklama her durumda dolu', () {
      for (var batteries = 1; batteries <= maxBatteries; batteries++) {
        for (var lamps = 1; lamps <= maxLamps; lamps++) {
          for (final layout in LampLayout.values) {
            for (final closed in [true, false]) {
              for (final burnt in <int?>[null, 0]) {
                final spec = CircuitSpec(
                  batteries: batteries,
                  lampCount: lamps,
                  layout: layout,
                  switchClosed: closed,
                  burntLamp: burnt,
                );
                final a = simulateCircuit(spec);
                final b = simulateCircuit(spec);
                expect(a.averageBrightness, b.averageBrightness);
                expect(describeCircuit(spec, a), isNotEmpty);
              }
            }
          }
        }
      }
    });

    test('kablo bulmacası: her üretim çözülebilir, başta çözülmüş değil', () {
      for (var size = 3; size <= 5; size++) {
        for (var seed = 0; seed < 100; seed++) {
          final puzzle = WirePuzzle.generate(size, Random(seed));
          final where = 'boyut $size tohum $seed';
          expect(puzzle.solved, isFalse, reason: where);
          expect(puzzle.parMoves, greaterThanOrEqualTo(1), reason: where);

          // Yol karolarını çözüm maskesine döndür: en az hamleyle çözülmeli.
          puzzle.solutionMasks.forEach((index, mask) {
            while (puzzle.tiles[index].mask != mask) {
              expect(puzzle.rotate(index), isTrue, reason: where);
            }
          });
          expect(puzzle.solved, isTrue, reason: where);
          expect(puzzle.moves, puzzle.parMoves, reason: where);
        }
      }
    });

    test('kablo bulmacası: pil ve ampul sabit, boş karo dönmez', () {
      final puzzle = WirePuzzle.generate(4, Random(1));
      expect(puzzle.rotate(puzzle.batteryIndex), isFalse);
      expect(puzzle.rotate(puzzle.bulbIndex), isFalse);
      final empty = puzzle.tiles.indexWhere((t) => t.kind == WireKind.empty);
      if (empty != -1) expect(puzzle.rotate(empty), isFalse);
      expect(puzzle.moves, 0);
    });

    test('görev üretimi: iletken soruları malzemeyle tutarlı', () {
      final rng = Random(4);
      for (var i = 0; i < 40; i++) {
        final task =
            generateElectricTask(ElectricTaskKind.conductor, rng) as ChoiceTask;
        final material = electricMaterials.firstWhere(
          (m) => task.subject == '${m.emoji} ${m.name}',
        );
        expect(task.correctIndex, material.conductive ? 0 : 1);
        expect(task.explanation, contains(material.note));
      }
    });

    test('görev üretimi: devre soruları tahmin edilebilir ve tutarlı', () {
      final rng = Random(7);
      for (var i = 0; i < 200; i++) {
        final task =
            generateElectricTask(ElectricTaskKind.circuit, rng) as ChoiceTask;
        expect(task.circuits, isNotEmpty);
        if (task.circuits.length == 2) {
          // Karşılaştırma: parlaklık farkı gözle ayırt edilebilir olmalı.
          final a = simulateCircuit(task.circuits[0].spec).averageBrightness;
          final b = simulateCircuit(task.circuits[1].spec).averageBrightness;
          expect((a - b).abs(), greaterThanOrEqualTo(minBrightnessGap));
          expect(task.correctIndex, a > b ? 0 : 1);
        }
        expect(task.correctIndex, inInclusiveRange(0, task.options.length - 1));
        expect(task.explanation, isNotEmpty);
      }
    });

    test('görev üretimi: enerji şehrinde tek doğru cevap vardır', () {
      EnergySource? sourceIn(String text) {
        for (final s in EnergySource.values) {
          if (text.contains(s.name)) return s;
        }
        return null;
      }

      List<EnergySource> sourcesIn(String text) => [
        for (final s in EnergySource.values)
          if (text.contains(s.name)) s,
      ];

      final rng = Random(11);
      var topCount = 0;
      var mixCount = 0;
      for (var i = 0; i < 300; i++) {
        final task =
            generateElectricTask(ElectricTaskKind.city, rng) as ChoiceTask;
        final weather = EnergyWeather.values.firstWhere(
          (w) => task.subject!.contains(w.label),
        );
        if (task.prompt.startsWith('Hangi kaynak')) {
          topCount++;
          final outputs = [
            for (final o in task.options) energyOutput(sourceIn(o)!, weather),
          ];
          final top = outputs.reduce(max);
          expect(outputs.where((o) => o == top).length, 1);
          expect(task.correctIndex, outputs.indexOf(top));
        } else {
          mixCount++;
          final demand = int.parse(
            RegExp(r'\d+').firstMatch(task.prompt)!.group(0)!,
          );
          bool ok(String option) {
            final mix = sourcesIn(option);
            final total = mix.fold(0, (s, e) => s + energyOutput(e, weather));
            return mix.every((e) => e.clean) && total >= demand;
          }

          expect(task.options.where(ok).length, 1, reason: task.prompt);
          expect(ok(task.options[task.correctIndex]), isTrue);
        }
      }
      expect(topCount, greaterThan(0));
      expect(mixCount, greaterThan(0));
    });

    test('güvenlik verisi: güvenli ve tehlikeli sahneler, geçerli watt tablosu', () {
      expect(safetyScenes.where((s) => s.safe).length, greaterThanOrEqualTo(4));
      expect(safetyScenes.where((s) => !s.safe).length, greaterThanOrEqualTo(4));
      for (final scene in safetyScenes) {
        expect(scene.explanation, isNotEmpty);
      }
      for (final appliance in appliances) {
        expect(appliance.watts, greaterThan(0));
      }
      final rng = Random(3);
      for (var i = 0; i < 100; i++) {
        final task =
            generateElectricTask(ElectricTaskKind.safety, rng) as ChoiceTask;
        expect(task.options.length, 2);
        if (task.prompt.startsWith('Hangi cihaz')) {
          final pair = [
            for (final o in task.options)
              appliances.firstWhere((a) => o == '${a.emoji} ${a.name}'),
          ];
          final high = max(pair[0].watts, pair[1].watts);
          final low = min(pair[0].watts, pair[1].watts);
          expect(high, greaterThanOrEqualTo(low * 1.5));
          expect(task.correctIndex, pair[0].watts > pair[1].watts ? 0 : 1);
        }
      }
    });

    /// Görevin doğru cevabını verir (kablo bulmacasını çözerek).
    void answerCorrectly(ElectricityController controller) {
      final task = controller.currentTask;
      if (task is ChoiceTask) {
        controller.answerChoice(task.correctIndex);
      } else if (task is WireTask) {
        task.puzzle.solutionMasks.forEach((index, mask) {
          while (task.puzzle.tiles[index].mask != mask) {
            controller.rotateWireTile(index);
          }
        });
      }
    }

    test('kontrolcü: tam oyun, tür dönüşümü ve sıra devri', () {
      final controller = ElectricityController(random: Random(5));
      controller.startGame(['A', 'B']);
      expect(controller.phase, ElectricityPhase.playing);

      for (var player = 0; player < 2; player++) {
        final kinds = <ElectricTaskKind>[];
        for (var round = 0; round < electricRoundsPerPlayer; round++) {
          kinds.add(controller.currentTask.kind);
          answerCorrectly(controller);
          expect(controller.showingResult, isTrue);
          expect(controller.lastAnswerCorrect, isTrue);
          controller.continueAfterResult();
        }
        // Her oyuncu her türden tam iki tur oynar.
        for (final kind in ElectricTaskKind.values) {
          expect(kinds.where((k) => k == kind).length, 2, reason: '$kind');
        }
        if (player == 0) {
          expect(controller.phase, ElectricityPhase.turnTransition);
          expect(controller.currentPlayerIndex, 1);
          controller.acknowledgeTurnTransition();
        }
      }
      expect(controller.phase, ElectricityPhase.finished);
      expect(
        controller.rankedByCorrect.first.correctCount,
        electricRoundsPerPlayer,
      );
      controller.restart();
      expect(controller.phase, ElectricityPhase.setup);
    });

    test('kontrolcü: yanlış cevap puan vermez, açıkken ikinci cevap sayılmaz', () {
      final controller = ElectricityController(random: Random(2));
      controller.startGame(['A']);
      final task = controller.currentTask as ChoiceTask;
      final wrong = task.options.length > 1 && task.correctIndex == 0 ? 1 : 0;
      controller.answerChoice(wrong);
      expect(controller.lastAnswerCorrect, isFalse);
      expect(controller.currentPlayer.correctCount, 0);
      expect(controller.currentPlayer.roundsPlayed, 1);

      controller.answerChoice(task.correctIndex);
      expect(controller.currentPlayer.roundsPlayed, 1);
      expect(controller.currentPlayer.correctCount, 0);

      controller.continueAfterResult();
      expect(controller.showingResult, isFalse);
      expect(controller.currentTask.kind, ElectricTaskKind.conductor);
    });

    test('kontrolcü: fazla hamleyle çözülen kablo bulmacası doğru sayılmaz', () {
      final controller = ElectricityController(random: Random(9));
      controller.startGame(['A']);
      // Wire turuna kadar ilerle (3. tur).
      for (var i = 0; i < 2; i++) {
        answerCorrectly(controller);
        controller.continueAfterResult();
      }
      final task = controller.currentTask as WireTask;
      expect(task.kind, ElectricTaskKind.wire);

      // Önce gereksiz hamlelerle sayacı şişir: her rotatable karoyu 4 kez çevir
      // (karo eski konumuna döner ama hamle sayılır), sonra çöz.
      for (var i = 0; i < task.puzzle.tiles.length; i++) {
        if (!task.puzzle.tiles[i].rotatable) continue;
        for (var k = 0; k < 4 && task.puzzle.moves < task.puzzle.parMoves + 6; k++) {
          controller.rotateWireTile(i);
          if (controller.showingResult) break;
        }
        if (controller.showingResult) break;
      }
      if (!controller.showingResult) {
        answerCorrectly(controller);
      }
      expect(controller.showingResult, isTrue);
      expect(controller.lastAnswerCorrect, isFalse);
    });

    test('kontrolcü: serbest atölye ve kablo yolu seviyeleri', () {
      final controller = ElectricityController(random: Random(1));
      controller.startFreeCircuit();
      expect(controller.phase, ElectricityPhase.freeCircuit);
      controller.setFreeSpec(controller.freeSpec.copyWith(batteries: 3));
      expect(simulateCircuit(controller.freeSpec).states.single, LampState.burnt);

      controller.startWireLevels();
      expect(controller.phase, ElectricityPhase.wireLevels);
      expect(controller.wireLevel, 1);

      // Aynı seviye her zaman aynı bulmacayı verir.
      controller.selectWireLevel(6);
      final first = [for (final t in controller.levelPuzzle.tiles) t.mask];
      controller.selectWireLevel(6);
      expect([for (final t in controller.levelPuzzle.tiles) t.mask], first);
      expect(controller.levelPuzzle.size, 4);
      controller.selectWireLevel(12);
      expect(controller.levelPuzzle.size, 5);

      controller.selectWireLevel(1);
      controller.levelPuzzle.solutionMasks.forEach((index, mask) {
        while (controller.levelPuzzle.tiles[index].mask != mask) {
          controller.rotateLevelTile(index);
        }
      });
      expect(controller.levelPuzzle.solved, isTrue);
      expect(controller.solvedLevels, contains(1));
      controller.nextWireLevel();
      expect(controller.wireLevel, 2);
    });

    testWidgets('katalogda kart var; 1 kişilik oyun 10 turu oynatır',
        (tester) async {
      await _openElectricity(tester);
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('electricityStart')));
      await tester.pumpAndSettle();

      final controller = tester
          .element(find.byType(Scaffold).last)
          .read<ElectricityController>();
      expect(controller.phase, ElectricityPhase.playing);

      for (var round = 0; round < electricRoundsPerPlayer; round++) {
        final task = controller.currentTask;
        if (task is ChoiceTask) {
          expect(find.byKey(const Key('electricOption_0')), findsOneWidget);
          await tester.tap(find.byKey(Key('electricOption_${task.correctIndex}')));
        } else if (task is WireTask) {
          expect(find.byKey(const Key('wireMoves')), findsOneWidget);
          // Bir karoya gerçekten dokun, sonra kalanını çöz.
          final rotatable = task.puzzle.solutionMasks.keys.first;
          final movesBefore = task.puzzle.moves;
          await tester.tap(find.byKey(Key('wireTile_$rotatable')));
          await tester.pump();
          // Dokunuş gerçekten karoyu döndürmeli (karo tıklanabilir boyutta olmalı).
          expect(task.puzzle.moves, movesBefore + 1);
          answerCorrectly(controller);
        }
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('electricExplanation')), findsOneWidget);
        await tester.tap(find.byKey(const Key('electricContinue')));
        await tester.pumpAndSettle();
      }

      expect(controller.phase, ElectricityPhase.finished);
      expect(find.text('Tebrikler, 1. Oyuncu!'), findsOneWidget);
    });

    testWidgets('serbest devre atölyesi: 3 pil ampulü patlatır', (tester) async {
      await _openElectricity(tester);
      await tester.tap(find.byKey(const Key('electricityFreeCircuit')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('freeBatteries_3')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Ampule fazla pil bağlanınca'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('freeBatteries_2')));
      await tester.tap(find.byKey(const Key('freeMaterial_plastik')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Yalıtkan malzeme devreyi kesti'), findsOneWidget);
    });

    testWidgets('kablo yolu seviyeleri: seviye seç ve çöz', (tester) async {
      await _openElectricity(tester);
      await tester.tap(find.byKey(const Key('electricityWireLevels')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('levelMoves')), findsOneWidget);

      final controller = tester
          .element(find.byType(Scaffold).last)
          .read<ElectricityController>();
      controller.levelPuzzle.solutionMasks.forEach((index, mask) {
        while (controller.levelPuzzle.tiles[index].mask != mask) {
          controller.rotateLevelTile(index);
        }
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('levelSolved')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nextWireLevel')));
      await tester.pumpAndSettle();
      expect(controller.wireLevel, 2);
    });

    testWidgets('dar ekranda (320 px) görev ve sonuç paneli taşmaz',
        (tester) async {
      await _openElectricity(tester);
      tester.view.physicalSize = const Size(320, 3000);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('electricityStart')));
      await tester.pumpAndSettle();

      final controller = tester
          .element(find.byType(Scaffold).last)
          .read<ElectricityController>();
      for (var round = 0; round < 5; round++) {
        final task = controller.currentTask;
        if (task is ChoiceTask) {
          await tester.tap(find.byKey(const Key('electricOption_0')));
        } else {
          answerCorrectly(controller);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tur $round');
        await tester.tap(find.byKey(const Key('electricContinue')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tur $round devam');
      }
    });
  });

  group('Renkli Kasaba', () {
    TownWorld townWorld({int npcs = 0, List<(int, int)> spots = const []}) =>
        TownWorld(
          map: buildTownMap(),
          random: Random(1),
          npcCount: npcs,
          coinSpots: spots,
        );

    test('izometrik dönüşüm gidiş-dönüş ve joystick yönü ekranda doğru', () {
      for (final (x, y) in [(0.0, 0.0), (3.5, 7.25), (19.0, 2.0)]) {
        final s = IsoProjection.toScreen(x, y);
        final back = IsoProjection.toTile(s.dx, s.dy);
        expect(back.dx, closeTo(x, 1e-9));
        expect(back.dy, closeTo(y, 1e-9));
      }
      // Ekranda "sağa" gitmek karede (+x, -y) yönündedir ve ekran dy ≈ 0.
      final dir = IsoProjection.screenDirToTile(1, 0);
      final screen = IsoProjection.toScreen(dir.dx, dir.dy);
      expect(screen.dx, greaterThan(0));
      expect(screen.dy.abs(), lessThan(1e-9));
      expect(IsoProjection.screenDirToTile(0, 0), Offset.zero);
    });

    test('haritalar: tutarlı boyut, 4 bina ve her kapı/altın noktası erişilebilir',
        () {
      for (final row in townRows) {
        expect(row.length, townRows.first.length);
      }
      final world = townWorld();
      final map = world.map;
      expect(map.buildings.map((b) => b.kind).toSet(), DoorKind.values.toSet());

      final sx = map.startX.floor();
      final sy = map.startY.floor();
      for (final b in map.buildings) {
        expect(map.kindAt(b.doorX, b.doorY), TileKind.door);
        expect(
          world.findPath(sx, sy, b.doorX, b.doorY),
          isNotNull,
          reason: '${b.kind} kapısına yol yok',
        );
      }
      for (final (x, y) in townCoinSpots) {
        expect(map.isWalkable(x, y), isTrue, reason: 'altın ($x,$y) yürünemez');
        expect(world.findPath(sx, sy, x, y), isNotNull, reason: 'altın ($x,$y)');
      }
      // Kasabadaki her yürünebilir kare başlangıçtan erişilebilir.
      for (var y = 0; y < map.height; y++) {
        for (var x = 0; x < map.width; x++) {
          if (map.isWalkable(x, y)) {
            expect(world.findPath(sx, sy, x, y), isNotNull, reason: '($x,$y)');
          }
        }
      }

      // Parkur: başlangıçtan bayrağa tehlikesiz yol var.
      final parkour = ParkourSession().world;
      expect(
        parkour.findPath(
          parkour.map.startX.floor(),
          parkour.map.startY.floor(),
          parkour.map.goalX,
          parkour.map.goalY,
        ),
        isNotNull,
      );
    });

    test('hareket: rastgele girdiyle karakter asla engelin içine girmez', () {
      final world = townWorld();
      final rng = Random(7);
      for (var i = 0; i < 4000; i++) {
        final angle = rng.nextDouble() * 2 * pi;
        final strength = rng.nextDouble();
        world.step(
          0.016,
          rng.nextInt(10) == 0
              ? WorldInput.none
              : WorldInput(cos(angle) * strength, sin(angle) * strength),
        );
        expect(world.canStand(world.x, world.y), isTrue, reason: 'adım $i');
      }
    });

    test('hareket: dev bir dt duvardan geçirmez (parçalara bölünür)', () {
      final world = townWorld();
      // Kuzey kenardaki ağaç duvarına doğru (ekranda yukarı) 5 saniye bas.
      world.step(5, const WorldInput(0, -1));
      expect(world.canStand(world.x, world.y), isTrue);
      expect(world.y, greaterThan(0.9)); // y=0 sırası ağaç
    });

    test('hareket: çapraz girdi düz girdiyle aynı hızda gider', () {
      final a = TownWorld(map: TownMap.parse(['.........', '.........', '.........', '.........', '.........', '.........', '.........', '.........', '.........']), random: Random(1), startX: 4.5, startY: 4.5);
      final b = TownWorld(map: TownMap.parse(['.........', '.........', '.........', '.........', '.........', '.........', '.........', '.........', '.........']), random: Random(1), startX: 4.5, startY: 4.5);
      a.step(0.4, const WorldInput(1, 0));
      final d = 1 / sqrt(2);
      b.step(0.4, WorldInput(d, d));
      double dist(TownWorld w) =>
          sqrt(pow(w.x - 4.5, 2) + pow(w.y - 4.5, 2)).toDouble();
      expect(dist(a), closeTo(dist(b), 1e-6));
      expect(dist(a), closeTo(TownWorld.speed * 0.4, 0.05));
    });

    test('yarım eğik joystick daha yavaş yürütür', () {
      final rows = List.filled(9, '.........');
      final full = TownWorld(map: TownMap.parse(rows), random: Random(1), startX: 4.5, startY: 4.5);
      final half = TownWorld(map: TownMap.parse(rows), random: Random(1), startX: 4.5, startY: 4.5);
      full.step(0.3, const WorldInput(1, 0));
      half.step(0.3, const WorldInput(0.5, 0));
      double dist(TownWorld w) =>
          sqrt(pow(w.x - 4.5, 2) + pow(w.y - 4.5, 2)).toDouble();
      expect(dist(half), closeTo(dist(full) / 2, 0.02));
    });

    test('dokun-yürü: engelden dolanarak kapıya varır', () {
      final world = townWorld();
      final door = world.map.buildings.firstWhere((b) => b.kind == DoorKind.arcade);
      expect(world.walkTo(door.doorX, door.doorY), isTrue);
      var steps = 0;
      while (world.hasPath && steps < 3000) {
        world.step(0.016, WorldInput.none);
        steps++;
        expect(world.canStand(world.x, world.y), isTrue);
      }
      expect(world.hasPath, isFalse, reason: 'yol bitmeli');
      expect(world.nearbyDoor?.kind, DoorKind.arcade);
      // Engelin (ağaç) üstüne yürünemez.
      expect(world.walkTo(0, 0), isFalse);
    });

    test('altın: toplanınca kaybolur, süre sonunda yeniden doğar; yıldız 5 değer',
        () {
      final world = TownWorld(
        map: buildTownMap(),
        random: Random(1),
        startX: 2.5,
        startY: 6.5,
        coinSpots: const [(2, 6), (5, 6), (8, 6), (12, 6), (15, 6), (17, 6)],
      );
      world.step(0.016, WorldInput.none);
      // (2,6) sıradan altın: 1 değer.
      expect(world.takeCollectedValue(), 1);
      expect(world.coins.first.active, isFalse);
      expect(world.takeCollectedValue(), 0);

      // Yıldız (6. nokta) 5 değerindedir.
      expect(world.coins.last.isStar, isTrue);
      expect(world.coins.last.value, 5);

      // 25 saniye sonra yeniden doğar (avatar uzakta).
      world.teleport(10.5, 14.5);
      world.step(26, WorldInput.none);
      expect(world.coins.first.active, isTrue);
    });

    test('NPC\'ler bir dakika boyunca yürünebilir karelerde kalır ve hareket eder',
        () {
      final world = townWorld(npcs: 4);
      final starts = [for (final n in world.npcs) (n.x, n.y)];
      for (var i = 0; i < 60 * 60; i++) {
        world.step(1 / 60, WorldInput.none);
        for (final npc in world.npcs) {
          expect(world.canStand(npc.x, npc.y), isTrue);
        }
      }
      var moved = 0;
      for (var i = 0; i < world.npcs.length; i++) {
        if ((world.npcs[i].x - starts[i].$1).abs() > 0.5 ||
            (world.npcs[i].y - starts[i].$2).abs() > 0.5) {
          moved++;
        }
      }
      expect(moved, greaterThan(0));
    });

    test('kapı: yanına gelince tanınır, uzaktayken yok', () {
      final world = townWorld();
      expect(world.nearbyDoor, isNull);
      for (final b in world.map.buildings) {
        world.teleport(b.doorX + 0.5, b.doorY + 0.5);
        expect(world.nearbyDoor?.kind, b.kind);
      }
      world.teleport(10.5, 14.5);
      expect(world.nearbyDoor, isNull);
    });

    test('derinlik: kapı önündeki karakter binanın önüne, kuzeydeki arkasına çizilir',
        () {
      final world = townWorld();
      for (final b in world.map.buildings) {
        final front = (b.doorX + 0.5) + (b.doorY + 0.5);
        expect(front, greaterThan(buildingDepth(b)), reason: '${b.kind} önü');
        final north = (b.x + 0.5) + (b.y - 0.5);
        expect(north, lessThan(buildingDepth(b)), reason: '${b.kind} kuzeyi');
      }
    });

    test('avatar: JSON gidiş-dönüş ve bozuk veri güvenli varsayılana düşer', () {
      const spec = AvatarSpec(
        skin: 3,
        hairStyle: 'hair_curly',
        hairColor: 5,
        outfit: 'outfit_space',
        outfitColor: 2,
        hat: 'hat_crown',
        accessory: 'acc_wings',
      );
      expect(AvatarSpec.fromJson(spec.toJson()), spec);
      final broken = AvatarSpec.fromJson({'skin': 99, 'hairColor': 'x', 'outfit': ''});
      expect(broken, const AvatarSpec());
    });

    test('profil: satın alma, adetli mobilya ve JSON gidiş-dönüş', () {
      final profile = TownProfile(coins: 60);
      final cap = shopItemById('hat_cap')!;
      expect(profile.buy(cap), isTrue);
      expect(profile.coins, 40);
      expect(profile.buy(cap), isFalse, reason: 'avatar eşyası tekrar alınmaz');
      expect(profile.buy(shopItemById('hat_crown')!), isFalse, reason: 'altın yetmez');
      expect(profile.coins, 40);

      final plant = shopItemById('furn_plant')!;
      expect(profile.buy(plant), isTrue);
      expect(profile.buy(plant), isTrue, reason: 'mobilya birden çok alınır');
      expect(profile.owned['furn_plant'], 2);

      final copy = TownProfile.fromJson(profile.toJson());
      expect(copy.coins, profile.coins);
      expect(copy.owned, profile.owned);
      expect(TownProfile.fromJson('bozuk').coins, 50);
      // Başlangıç eşyaları her zaman vardır.
      expect(TownProfile().owns('hair_short'), isTrue);
      expect(TownProfile().owns('furn_bed'), isTrue);
    });

    test('oda: sınır, çakışma, döndürünce ayak izi ve halı altına girilebilir', () {
      const layout = RoomLayout();
      final bed = shopItemById('furn_bed')!; // 2×1
      final lamp = shopItemById('furn_lamp')!; // 1×1
      final rug = shopItemById('furn_rug')!; // 2×2 zemin

      expect(layout.canPlace(bed, 0, 0, 0), isTrue);
      expect(layout.canPlace(bed, 7, 0, 0), isFalse, reason: 'sağ sınır');
      expect(layout.canPlace(bed, 0, 7, 1), isFalse, reason: 'döndürünce 1×2 taşar');
      expect(layout.canPlace(bed, 0, 6, 1), isTrue);
      expect(layout.canPlace(bed, -1, 0, 0), isFalse);

      final withBed = layout.copyWith(
        items: [const PlacedItem(itemId: 'furn_bed', x: 2, y: 2)],
      );
      expect(withBed.canPlace(lamp, 2, 2, 0), isFalse);
      expect(withBed.canPlace(lamp, 3, 2, 0), isFalse, reason: 'yatak 2 geniş');
      expect(withBed.canPlace(lamp, 4, 2, 0), isTrue);
      expect(withBed.canPlace(rug, 2, 2, 0), isTrue, reason: 'halı zemin eşyasıdır');
      expect(withBed.canPlace(bed, 2, 2, 0, ignoreIndex: 0), isTrue);

      final both = withBed.copyWith(
        items: [
          ...withBed.items,
          const PlacedItem(itemId: 'furn_rug', x: 2, y: 2),
        ],
      );
      expect(both.itemIndexAt(2, 2), 0, reason: 'kutu, halıdan önce seçilir');
      expect(both.itemIndexAt(3, 3), 1, reason: 'yalnız halı');
      expect(both.itemIndexAt(7, 7), -1);

      final copy = RoomLayout.fromJson(both.toJson());
      expect(copy.items.length, 2);
      expect(copy.items.first.itemId, 'furn_bed');
    });

    test('kayıt: bellek içi ve SharedPreferences depoları gidiş-dönüş yapar',
        () async {
      final profile = TownProfile(coins: 123)
        ..avatar = const AvatarSpec(hat: 'hat_party', skin: 4);

      final memory = InMemoryTownProgressRepository();
      expect(await memory.load(), isNull);
      await memory.save(profile);
      final loaded = await memory.load();
      expect(loaded!.coins, 123);
      expect(loaded.avatar.hat, 'hat_party');

      SharedPreferences.setMockInitialValues({});
      final prefs = SharedPrefsTownProgressRepository();
      expect(await prefs.load(), isNull);
      await prefs.save(profile);
      final fromPrefs = await prefs.load();
      expect(fromPrefs!.coins, 123);
      expect(fromPrefs.avatar.skin, 4);

      // Bozuk kayıt oyunu çökertmez.
      SharedPreferences.setMockInitialValues({'town_profile_v1': 'not json'});
      expect(await SharedPrefsTownProgressRepository().load(), isNull);
    });

    test('parkur: varil deseni deterministik, suya düşmek başa döndürür', () {
      const barrel = ParkourSession.barrels;
      expect(barrel.first.yAt(0), barrel.first.yAt(0));
      for (final b in barrel) {
        for (var t = 0.0; t < 10; t += 0.13) {
          expect(b.yAt(t), inInclusiveRange(b.y0, b.y1));
        }
      }

      final session = ParkourSession();
      final world = session.world;
      // Suya (kuzey kenar) doğru yürü: hazard kareye girince başa döner.
      world.teleport(2.5, 2.5);
      session.step(1.0, const WorldInput(1, -1)); // yukarı-sağ değil; yukarı için:
      var guard = 0;
      while (session.hits == 0 && guard++ < 600) {
        session.step(0.016, const WorldInput(-1, -1)); // ekranda sola-yukarı ≈ kuzey
      }
      expect(session.hits, greaterThan(0));
      expect((world.x - world.spawnX).abs() < 0.5, isTrue);
      expect(session.finished, isFalse);
    });

    test('parkur: bayrağa ulaşınca biter ve süreye göre puan verir; süre biterse 0',
        () {
      final win = ParkourSession();
      // Bayrağın hemen önüne ışınla ve içine yürü.
      win.world.teleport(win.world.map.goalX - 0.2, win.world.map.goalY + 0.5);
      // Varil olmayan bir zamanda: varillerden uzağız (x ≈ 13.8 > 11.5).
      var guard = 0;
      while (!win.finished && guard++ < 200) {
        win.step(0.016, const WorldInput(1, 1)); // ekranda sağ-aşağı ≈ +x
        if (win.world.map.goalX == win.world.x.floor()) break;
      }
      win.step(0.016, const WorldInput(1, 1));
      expect(win.finished, isTrue);
      expect(win.reachedGoal, isTrue);
      expect(win.score, greaterThanOrEqualTo(20));

      final lose = ParkourSession();
      lose.world.teleport(2.5, 3.5);
      lose.step(61, WorldInput.none);
      expect(lose.finished, isTrue);
      expect(lose.reachedGoal, isFalse);
      expect(lose.score, 0);
    });

    test('hazine avı: 3 sandık uzak yerleşir, ipucu uzaklıkla soğur/ısınır', () {
      for (var seed = 0; seed < 20; seed++) {
        final session = TreasureSession(Random(seed));
        final chests = session.world.props.where((p) => p.kind == 'chest').toList();
        expect(chests.length, TreasureSession.chestCount);
        for (final c in chests) {
          expect(session.world.map.isWalkable(c.x.floor(), c.y.floor()), isTrue);
          final dx = c.x - session.world.spawnX;
          final dy = c.y - session.world.spawnY;
          expect(sqrt(dx * dx + dy * dy), greaterThanOrEqualTo(6 - 1e-9));
        }
        for (var i = 0; i < chests.length; i++) {
          for (var j = i + 1; j < chests.length; j++) {
            final dx = chests[i].x - chests[j].x;
            final dy = chests[i].y - chests[j].y;
            expect(sqrt(dx * dx + dy * dy), greaterThanOrEqualTo(6 - 1e-9));
          }
        }
      }
      expect(TreasureSession.hintFor(1), contains('Yanıyorsun'));
      expect(TreasureSession.hintFor(4), contains('Sıcak'));
      expect(TreasureSession.hintFor(7), contains('Ilık'));
      expect(TreasureSession.hintFor(20), contains('Soğuk'));

      final session = TreasureSession(Random(3));
      final chests = session.world.props.where((p) => p.kind == 'chest').toList();
      var previous = -1;
      for (final c in chests) {
        session.world.teleport(c.x, c.y);
        session.step(0.016, WorldInput.none);
        expect(session.found, greaterThan(previous));
        previous = session.found;
      }
      expect(session.finished, isTrue);
      expect(session.score, greaterThanOrEqualTo(300));
    });

    test('yıldız yağmuru: 60 saniyede biter, puan yıldız × 10', () {
      final session = StarRushSession(Random(1));
      final spot = townCoinSpots.first;
      session.world.teleport(spot.$1 + 0.5, spot.$2 + 0.5);
      session.step(0.016, WorldInput.none);
      expect(session.score, 10);
      // Yıldızlar 3 saniyede yeniden doğar: aynı yerde tekrar toplanır.
      session.world.teleport(10.5, 14.5);
      session.step(3.5, WorldInput.none);
      session.world.teleport(spot.$1 + 0.5, spot.$2 + 0.5);
      session.step(0.016, WorldInput.none);
      expect(session.score, 20);
      session.step(70, WorldInput.none);
      expect(session.finished, isTrue);
      expect(session.timeLeft, 0);
    });

    test('kontrolcü: giyim ve market — altın yetmezse reddeder, yeterse kuşanır',
        () {
      final controller = TownController(random: Random(1));
      final crown = shopItemById('hat_crown')!; // 100
      final cap = shopItemById('hat_cap')!; // 20
      expect(controller.buyOrEquip(crown), isFalse);
      expect(controller.profile.avatar.hat, 'hat_none');

      expect(controller.buyOrEquip(cap), isTrue);
      expect(controller.profile.avatar.hat, 'hat_cap');
      expect(controller.profile.coins, 30);
      expect(controller.isEquipped(cap), isTrue);

      // Sahip olunan eşya bedava değiştirilir.
      expect(controller.buyOrEquip(shopItemById('hat_none')!), isTrue);
      expect(controller.buyOrEquip(cap), isTrue);
      expect(controller.profile.coins, 30);

      controller.setSkin(5);
      controller.setHairColor(2);
      controller.setOutfitColor(7);
      controller.setSkin(99); // yok sayılır
      expect(controller.profile.avatar.skin, 5);
      expect(controller.profile.avatar.hairColor, 2);
      expect(controller.profile.avatar.outfitColor, 7);

      expect(controller.buyFurniture(shopItemById('furn_tv')!), isFalse);
      controller.profile.coins = 200;
      expect(controller.buyFurniture(shopItemById('furn_tv')!), isTrue);
      expect(controller.profile.coins, 130);
      expect(controller.buyFurniture(shopItemById('hat_cap')!), isFalse);
    });

    test('kontrolcü: oda yerleştirme envanteri tüketir, taşır, döndürür, kaldırır',
        () {
      final controller = TownController(random: Random(1));
      final lamp = shopItemById('furn_lamp')!;
      final bed = shopItemById('furn_bed')!;
      expect(controller.profile.availableCount('furn_lamp'), 1);

      expect(controller.placeItem(lamp, 1, 1), isTrue);
      expect(controller.profile.availableCount('furn_lamp'), 0);
      expect(controller.placeItem(lamp, 3, 3), isFalse, reason: 'adet bitti');

      expect(controller.placeItem(bed, 1, 1), isFalse, reason: 'lambayla çakışır');
      expect(controller.placeItem(bed, 4, 4), isTrue);
      expect(controller.rotatePlaced(1), isTrue);
      expect(controller.profile.room.items[1].rotation, 1);
      expect(controller.movePlaced(1, 7, 7), isFalse, reason: 'sığmaz');
      expect(controller.movePlaced(1, 6, 5), isTrue);

      controller.setRoomFloor(3);
      controller.setRoomWall(2);
      expect(controller.profile.room.floorColor, 3);
      expect(controller.profile.room.wallColor, 2);
      controller.setRoomFloor(99);
      expect(controller.profile.room.floorColor, 3);

      controller.removePlaced(0);
      expect(controller.profile.availableCount('furn_lamp'), 1);
    });

    test('kontrolcü: ilerleme kaydedilir ve yeni oturumda yüklenir', () async {
      final repo = InMemoryTownProgressRepository();
      final first = TownController(repository: repo, random: Random(1));
      first.buyOrEquip(shopItemById('hat_party')!);
      first.setSkin(4);
      first.saveNow();
      await Future<void>.delayed(Duration.zero);

      final second = TownController(repository: repo, random: Random(1));
      await second.load();
      expect(second.profile.avatar.hat, 'hat_party');
      expect(second.profile.avatar.skin, 4);
      expect(second.profile.coins, 10);
    });

    test('kontrolcü: kapıya girince doğru faz açılır, geri dönünce kasaba', () {
      final controller = TownController(random: Random(1));
      controller.enterTown();
      expect(controller.phase, TownPhase.town);
      expect(controller.doorPrompt, isNull);

      const expected = {
        DoorKind.wardrobe: TownPhase.wardrobe,
        DoorKind.market: TownPhase.market,
        DoorKind.home: TownPhase.home,
        DoorKind.arcade: TownPhase.arcade,
      };
      for (final b in controller.world.map.buildings) {
        controller.world.teleport(b.doorX + 0.5, b.doorY + 0.5);
        controller.tick(0.016);
        expect(controller.doorPrompt, b.kind);
        controller.enterNearbyDoor();
        expect(controller.phase, expected[b.kind]);
        controller.backToTown();
        expect(controller.phase, TownPhase.town);
      }
    });

    test('kontrolcü: kasabada altın toplamak cüzdanı artırır', () {
      final controller = TownController(random: Random(1));
      controller.enterTown();
      final before = controller.profile.coins;
      final spot = townCoinSpots.first;
      controller.world.teleport(spot.$1 + 0.5, spot.$2 + 0.5);
      controller.tick(0.016);
      expect(controller.profile.coins, greaterThan(before));
    });

    test('kontrolcü: serbest mini oyun ödül verir ve oyun salonuna döner', () {
      final controller = TownController(random: Random(2));
      controller.startFreeMiniGame(MiniGameKind.stars);
      expect(controller.phase, TownPhase.miniGame);
      expect(controller.contest, isFalse);

      final before = controller.profile.coins;
      final spot = townCoinSpots.first;
      controller.session!.world.teleport(spot.$1 + 0.5, spot.$2 + 0.5);
      controller.tick(0.016);
      controller.session!.finish();
      controller.tick(0.016);
      expect(controller.sessionFinished, isTrue);

      final reward = controller.session!.rewardCoins;
      controller.continueAfterMiniGame();
      expect(controller.phase, TownPhase.arcade);
      expect(controller.profile.coins, before + reward);
    });

    test('kontrolcü: yarışma — iki oyuncu üçer oyun, sıra devri ve sıralama', () {
      final controller = TownController(random: Random(3));
      controller.startContest(['Ada', 'Can']);
      expect(controller.phase, TownPhase.miniGame);
      expect(controller.contest, isTrue);

      final kinds = <MiniGameKind>[];
      for (var player = 0; player < 2; player++) {
        for (var round = 0; round < townRoundsPerPlayer; round++) {
          kinds.add(controller.session!.kind);
          // Ada'ya yüksek, Can'a düşük puan: yıldız oyununda sayaç artır.
          controller.session!.finish();
          controller.session!.score = player == 0 ? 100 : 10;
          controller.continueAfterMiniGame();
        }
        if (player == 0) {
          expect(controller.phase, TownPhase.turnTransition);
          expect(controller.currentPlayerIndex, 1);
          controller.acknowledgeTurnTransition();
          expect(controller.phase, TownPhase.miniGame);
        }
      }
      expect(controller.phase, TownPhase.finished);
      // Her oyuncu her oyunu tam bir kez oynar.
      expect(kinds.sublist(0, 3), MiniGameKind.values);
      expect(kinds.sublist(3), MiniGameKind.values);
      final ranked = controller.rankedByScore;
      expect(ranked.first.name, 'Ada');
      expect(ranked.first.totalScore, 300);
      expect(ranked.last.totalScore, 30);

      controller.restart();
      expect(controller.phase, TownPhase.setup);
    });

    test('ses tarifleri: her klip geçerli, duyulur ve sonu sessiz WAV üretir', () {
      final clips = <String, SoundClip>{
        'coin': townCoinClip,
        'star': townStarClip,
        'doorNear': townDoorNearClip,
        'doorOpen': townDoorOpenClip,
        'purchase': townPurchaseClip,
        'denied': townDeniedClip,
        'place': townPlaceClip,
        'chest': townChestClip,
        'bump': townBumpClip,
        'gameStart': townGameStartClip,
        'win': townWinClip,
        'lose': townLoseClip,
        for (final (index, clip) in townStepClips.indexed) 'step$index': clip,
      };

      clips.forEach((name, clip) {
        final wav = renderClipWav(clip);
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
        final bytes = ByteData.sublistView(wav);
        final samples = (wav.length - 44) ~/ 2;
        expect(bytes.getUint32(40, Endian.little), samples * 2);

        var peak = 0;
        for (var i = 0; i < samples; i++) {
          peak = max(peak, bytes.getInt16(44 + i * 2, Endian.little).abs());
        }
        expect(peak, greaterThan(3000), reason: '$name duyulmalı');
        expect(peak, lessThanOrEqualTo(32767));

        // Zarf `durMs` içinde bittiği için sonu sessiz olmalı ("pop" yok).
        var tail = 0;
        for (var i = samples - clip.sampleRate ~/ 200; i < samples; i++) {
          tail = max(tail, bytes.getInt16(44 + i * 2, Endian.little).abs());
        }
        expect(tail, lessThan(peak ~/ 20), reason: '$name kuyruğu sönmeli');
      });
    });

    test('müzik döngüsü: tam 16 vuruş uzunluğunda ve dikişsiz', () {
      expect(townMusicClip.totalMs, 9600);
      final samples = renderClip(townMusicClip);
      expect(samples.length, (townMusicClip.sampleRate * 9.6).round());

      // Döngü dikişi: hem baş hem son neredeyse sıfır olmalı, yoksa her
      // tekrarda duyulur bir tık olur.
      expect(samples.first.abs(), lessThan(0.02));
      expect(samples.last.abs(), lessThan(0.02));

      var peak = 0.0;
      for (final sample in samples) {
        peak = max(peak, sample.abs());
      }
      expect(peak, greaterThan(0.1), reason: 'müzik duyulmalı');
      expect(peak, lessThanOrEqualTo(1.0), reason: 'müzik kırpılmamalı');
    });

    test('nota adı frekansa çevrilir', () {
      expect(noteHz('A4'), closeTo(440, 1e-9));
      expect(noteHz('A5'), closeTo(880, 1e-9));
      expect(noteHz('C4'), closeTo(261.6256, 1e-3));
      expect(noteHz('C#4'), closeTo(277.1826, 1e-3));
      expect(noteHz('Db4'), closeTo(277.1826, 1e-3));
      expect(() => noteHz('H4'), throwsArgumentError);
      expect(() => noteHz('A'), throwsArgumentError);
    });

    test('kontrolcü: olaylara göre doğru ses çalar, kapalıyken susar', () {
      final sounds = _FakeTownSounds();
      final controller = TownController(random: Random(1), sounds: sounds);

      // Kasabaya girmek müziği başlatır; kurulum ekranı sessizdir.
      controller.enterTown();
      expect(sounds.musicPlaying, isTrue);
      controller.leaveToSetup();
      expect(sounds.musicPlaying, isFalse);
      controller.enterTown();

      // Altın toplamak "coin", yıldız "star" çalar.
      sounds.calls.clear();
      final coin = controller.world.coins.firstWhere((c) => !c.isStar);
      controller.world.teleport(coin.x, coin.y);
      controller.tick(0.016);
      expect(sounds.calls, contains('coin'));

      sounds.calls.clear();
      final star = controller.world.coins.firstWhere((c) => c.isStar);
      controller.world.teleport(star.x, star.y);
      controller.tick(0.016);
      expect(sounds.calls, contains('star'));

      // Yürümek ayak sesi çıkarır (bir adım mesafesinden fazla yol alınca).
      sounds.calls.clear();
      controller.world.teleport(townStartX, townStartY);
      controller.setInput(const WorldInput(1, 0));
      for (var i = 0; i < 40; i++) {
        controller.tick(0.016);
      }
      expect(sounds.calls, contains('step'));
      controller.setInput(WorldInput.none);

      // Kapıdan girmek "doorOpen", satın alma "purchase", parasızlık "denied".
      sounds.calls.clear();
      final door = controller.world.map.buildings.first;
      controller.world.teleport(door.doorX + 0.5, door.doorY + 0.5);
      controller.tick(0.016);
      controller.enterNearbyDoor();
      expect(sounds.calls, contains('doorOpen'));

      sounds.calls.clear();
      expect(controller.buyOrEquip(shopItemById('hat_crown')!), isFalse);
      expect(sounds.calls, ['denied']);
      sounds.calls.clear();
      expect(controller.buyOrEquip(shopItemById('hat_cap')!), isTrue);
      expect(sounds.calls, ['purchase']);

      // Ses kapatılınca efekt çalınmaz; müzik ayrı anahtardadır.
      controller.toggleSound();
      sounds.calls.clear();
      controller.profile.coins = 500;
      expect(controller.buyFurniture(shopItemById('furn_tv')!), isTrue);
      expect(sounds.calls, isEmpty);
      expect(sounds.musicPlaying, isTrue);
      controller.toggleMusic();
      expect(sounds.musicPlaying, isFalse);
      expect(controller.profile.soundOn, isFalse);
      expect(controller.profile.musicOn, isFalse);
    });

    test('kontrolcü: mini oyun sesleri (başlangıç, çarpma, sandık, bitiş)', () {
      final sounds = _FakeTownSounds();
      final controller = TownController(random: Random(2), sounds: sounds);

      controller.startFreeMiniGame(MiniGameKind.parkour);
      expect(sounds.calls, contains('gameStart'));

      // Suya girmek başa döndürür ve "bump" çalar.
      sounds.calls.clear();
      final parkour = controller.session! as ParkourSession;
      final water = [
        for (var y = 0; y < parkour.world.map.height; y++)
          for (var x = 0; x < parkour.world.map.width; x++)
            if (parkour.world.map.isHazard(x, y)) (x, y),
      ].first;
      parkour.world.teleport(water.$1 + 0.5, water.$2 + 0.5);
      controller.tick(0.016);
      expect(sounds.calls, contains('bump'));

      // Puansız bitiş "lose", puanlı bitiş "win".
      sounds.calls.clear();
      controller.session!.finish();
      controller.tick(0.016);
      expect(sounds.calls, contains('lose'));

      controller.continueAfterMiniGame();
      controller.startFreeMiniGame(MiniGameKind.treasure);
      sounds.calls.clear();
      final chest =
          controller.session!.world.props.firstWhere((p) => p.kind == 'chest');
      controller.session!.world.teleport(chest.x, chest.y);
      controller.tick(0.016);
      expect(sounds.calls, contains('chest'));

      sounds.calls.clear();
      controller.session!.score = 120;
      controller.session!.finished = true;
      controller.tick(0.016);
      expect(sounds.calls, contains('win'));
    });

    test('ses tercihleri kayıtta saklanır, eski kayıtta açık kalır', () async {
      final repo = InMemoryTownProgressRepository();
      final first = TownController(repository: repo, random: Random(1));
      first.toggleSound();
      first.toggleMusic();
      await Future<void>.delayed(Duration.zero);

      final second = TownController(repository: repo, random: Random(1));
      await second.load();
      expect(second.profile.soundOn, isFalse);
      expect(second.profile.musicOn, isFalse);

      // Ses alanları olmayan eski kayıt: ses açık kabul edilir.
      expect(TownProfile.fromJson({'coins': 10}).soundOn, isTrue);
      expect(TownProfile.fromJson({'coins': 10}).musicOn, isTrue);
    });

    /// Ana menüden Renkli Kasaba'ya girer (katalogdaki 14. kart). Dünya ekranı
    /// sürekli kare istediği için burada `pumpAndSettle` kullanılmaz.
    Future<void> openTown(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 7800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GamePlatformApp());
      await tester.tap(find.text('Renkli Kasaba'));
      await tester.pumpAndSettle();
    }

    TownController controllerOf(WidgetTester tester) =>
        tester.element(find.byType(Scaffold).last).read<TownController>();

    testWidgets('kasabaya gir: klavye avatarı yürütür, kapıda Gir düğmesi çıkar',
        (tester) async {
      await openTown(tester);
      await tester.tap(find.byKey(const Key('townEnter')));
      await tester.pump();
      final controller = controllerOf(tester);
      expect(controller.phase, TownPhase.town);
      expect(find.byKey(const Key('townCoins')), findsOneWidget);
      expect(find.byKey(const Key('townJoystick')), findsOneWidget);

      final startX = controller.world.x;
      final startY = controller.world.y;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 16));
      final moved =
          (controller.world.x - startX).abs() + (controller.world.y - startY).abs();
      expect(moved, greaterThan(0.3), reason: 'klavye girdisi avatarı yürütmeli');

      // Girdi bırakılınca durur.
      final stopX = controller.world.x;
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.world.x, closeTo(stopX, 1e-9));

      // Giyim dükkânı kapısına ışınla: Gir düğmesi çıkar.
      final wardrobe = controller.world.map.buildings
          .firstWhere((b) => b.kind == DoorKind.wardrobe);
      controller.world.teleport(wardrobe.doorX + 0.5, wardrobe.doorY + 0.5);
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.byKey(const Key('townEnterDoor')), findsOneWidget);
      expect(find.textContaining('Giyim Dükkânı'), findsWidgets);
    });

    testWidgets('joystick sürüklenince avatar hareket eder', (tester) async {
      await openTown(tester);
      await tester.tap(find.byKey(const Key('townEnter')));
      await tester.pump();
      final controller = controllerOf(tester);
      final startX = controller.world.x;
      final startY = controller.world.y;

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('townJoystick'))),
      );
      await gesture.moveBy(const Offset(40, 0));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        (controller.world.x - startX).abs() + (controller.world.y - startY).abs(),
        greaterThan(0.3),
      );
    });

    testWidgets('giyim dükkânında şapka satın al ve kuşan', (tester) async {
      await openTown(tester);
      await tester.tap(find.byKey(const Key('townEnter')));
      await tester.pump();
      final controller = controllerOf(tester);
      final wardrobe = controller.world.map.buildings
          .firstWhere((b) => b.kind == DoorKind.wardrobe);
      controller.world.teleport(wardrobe.doorX + 0.5, wardrobe.doorY + 0.5);
      await tester.pump(const Duration(milliseconds: 32));
      await tester.tap(find.byKey(const Key('townEnterDoor')));
      await tester.pump();
      expect(controller.phase, TownPhase.wardrobe);

      await tester.tap(find.byKey(const Key('wardrobeCategory_hat')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('wardrobeItem_hat_cap')));
      await tester.tap(find.byKey(const Key('wardrobeItem_hat_cap')));
      await tester.pump();
      expect(controller.profile.avatar.hat, 'hat_cap');
      expect(controller.profile.coins, 30);

      // Tacı alacak altın yok: düğme kapalı.
      final crownButton = tester.widget<FilledButton>(
        find.byKey(const Key('wardrobeItem_hat_crown')),
      );
      expect(crownButton.onPressed, isNull);

      await tester.tap(find.byKey(const Key('skin_4')));
      await tester.pump();
      expect(controller.profile.avatar.skin, 4);

      // Geri: kasabaya dön.
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      expect(controller.phase, TownPhase.town);
    });

    testWidgets('market ve oda: mobilya al, envanterden odaya yerleştir',
        (tester) async {
      await openTown(tester);
      await tester.tap(find.byKey(const Key('townEnter')));
      await tester.pump();
      final controller = controllerOf(tester);
      controller.profile.coins = 100;

      // Market
      final market = controller.world.map.buildings
          .firstWhere((b) => b.kind == DoorKind.market);
      controller.world.teleport(market.doorX + 0.5, market.doorY + 0.5);
      await tester.pump(const Duration(milliseconds: 32));
      await tester.tap(find.byKey(const Key('townEnterDoor')));
      await tester.pump();
      expect(controller.phase, TownPhase.market);
      await tester.tap(find.byKey(const Key('marketBuy_furn_plant')));
      await tester.pump();
      expect(controller.profile.owned['furn_plant'], 1);
      expect(controller.profile.coins, 90);
      await tester.tap(find.byType(BackButton));
      await tester.pump();

      // Ev
      final home = controller.world.map.buildings
          .firstWhere((b) => b.kind == DoorKind.home);
      controller.world.teleport(home.doorX + 0.5, home.doorY + 0.5);
      await tester.pump(const Duration(milliseconds: 32));
      await tester.tap(find.byKey(const Key('townEnterDoor')));
      await tester.pump();
      expect(controller.phase, TownPhase.home);

      await tester.tap(find.byKey(const Key('roomInv_furn_plant')));
      await tester.pump();
      final roomFinder = find.byKey(const Key('roomTap'));
      final size = tester.getSize(roomFinder);
      final center = size.center(Offset.zero);
      final tile = IsoRoomView.tileAt(center, size);
      expect(tile, isNotNull);
      await tester.tapAt(tester.getTopLeft(roomFinder) + center);
      await tester.pump();

      final placed = controller.profile.room.items
          .where((i) => i.itemId == 'furn_plant')
          .toList();
      expect(placed.length, 1);
      expect(placed.first.x, tile!.$1);
      expect(placed.first.y, tile.$2);
      // Envanterden tükendi: çip kayboldu.
      expect(find.byKey(const Key('roomInv_furn_plant')), findsNothing);
    });

    testWidgets('oyun salonu: parkur başlar, süre/durum rozetleri görünür',
        (tester) async {
      await openTown(tester);
      await tester.tap(find.byKey(const Key('townEnter')));
      await tester.pump();
      final controller = controllerOf(tester);
      final arcade = controller.world.map.buildings
          .firstWhere((b) => b.kind == DoorKind.arcade);
      controller.world.teleport(arcade.doorX + 0.5, arcade.doorY + 0.5);
      await tester.pump(const Duration(milliseconds: 32));
      await tester.tap(find.byKey(const Key('townEnterDoor')));
      await tester.pump();
      expect(controller.phase, TownPhase.arcade);

      await tester.tap(find.byKey(const Key('arcadeStart_parkour')));
      await tester.pump();
      expect(controller.phase, TownPhase.miniGame);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('miniTime')), findsOneWidget);
      expect(find.textContaining('Çarpma'), findsOneWidget);

      controller.session!.finish();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('townMiniContinue')), findsOneWidget);
      await tester.tap(find.byKey(const Key('townMiniContinue')));
      await tester.pump();
      expect(controller.phase, TownPhase.arcade);
    });

    testWidgets('mini oyun yarışı: 1 kişi üç oyunu bitirir ve tebrik edilir',
        (tester) async {
      await openTown(tester);
      await tester.tap(find.text('1 Kişi'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('townContest')));
      await tester.pump();
      final controller = controllerOf(tester);
      expect(controller.phase, TownPhase.miniGame);

      for (var round = 0; round < townRoundsPerPlayer; round++) {
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byKey(const Key('miniTime')), findsOneWidget);
        controller.session!.finish();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(const Key('miniScore')), findsOneWidget);
        await tester.tap(find.byKey(const Key('townMiniContinue')));
        await tester.pump();
      }
      expect(controller.phase, TownPhase.finished);
      expect(find.text('Tebrikler, 1. Oyuncu!'), findsOneWidget);
    });

    testWidgets('dar ekranda (320 px) kasaba, dükkân, oda ve mini oyun taşmaz',
        (tester) async {
      await openTown(tester);
      tester.view.physicalSize = const Size(320, 640);
      await tester.pump();
      await tester.tap(find.byKey(const Key('townEnter')));
      await tester.pump();
      final controller = controllerOf(tester);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull, reason: 'kasaba');

      for (final phase in [
        TownPhase.wardrobe,
        TownPhase.market,
        TownPhase.home,
        TownPhase.arcade,
      ]) {
        controller.phase = phase;
        controller.notifyListeners();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull, reason: '$phase');
      }

      controller.startFreeMiniGame(MiniGameKind.treasure);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      controller.session!.finish();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: 'mini oyun sonucu');
    });

    /// Dünya-ekran noktasını, kameranın avatara kilitli olduğu tuval
    /// koordinatına çevirir (çizimle aynı dönüşüm).
    Offset localOf(TownWorld world, Size size, Offset worldScreen) =>
        (worldScreen - IsoWorldPainter.cameraCenter(world)) *
            IsoWorldView.zoomFor(size) +
        size.center(Offset.zero);

    test('dokunma hedefi: altın, sandık, bina ve zemin doğru kareye çözülür', () {
      final world = townWorld(spots: townCoinSpots);
      const size = Size(800, 600);
      final zoom = IsoWorldView.zoomFor(size);

      // Havada süzülen altının çizildiği yere dokunmak, altının karesini verir
      // (zemin karesine değil).
      final coin = world.coins.firstWhere((c) => c.x > 8 && c.y > 6);
      final coinLocal = localOf(
        world,
        size,
        IsoProjection.toScreen(coin.x, coin.y) + const Offset(0, -12),
      );
      expect(
        IsoWorldPainter.tapTarget(coinLocal, size, world, zoom),
        (coin.x.floor(), coin.y.floor()),
      );

      // Binanın çatısına dokunmak kapısını verir.
      final b = world.map.buildings.firstWhere((b) => b.kind == DoorKind.market);
      final roof = localOf(
        world,
        size,
        IsoProjection.toScreen(b.x + b.w / 2, b.y + b.h / 2) + const Offset(0, -40),
      );
      expect(
        IsoWorldPainter.tapTarget(roof, size, world, zoom),
        (b.doorX, b.doorY),
      );

      // Kapı paspasına dokunmak da kapıyı verir.
      final mat = localOf(
        world,
        size,
        IsoProjection.toScreen(b.doorX + 0.5, b.doorY + 0.5),
      );
      expect(
        IsoWorldPainter.tapTarget(mat, size, world, zoom),
        (b.doorX, b.doorY),
      );

      // Boş zemine dokunmak o zemin karesidir.
      final bare = TownWorld(map: buildTownMap(), random: Random(1), startX: 9.5, startY: 14.5);
      final ground = localOf(bare, size, IsoProjection.toScreen(12.5, 14.5));
      expect(IsoWorldPainter.tapTarget(ground, size, bare, zoom), (12, 14));
    });

    test('kontrolcü: kapının önünde aynı kapıya dokunmak içeri sokar', () {
      final controller = TownController(random: Random(1));
      controller.enterTown();
      final b = controller.world.map.buildings
          .firstWhere((b) => b.kind == DoorKind.home);
      // Uzaktayken dokunmak yalnızca yürütür.
      controller.tapTile(b.doorX, b.doorY);
      expect(controller.phase, TownPhase.town);
      expect(controller.world.hasPath, isTrue);

      controller.world.teleport(b.doorX + 0.5, b.doorY + 0.5);
      controller.tapTile(b.doorX, b.doorY);
      expect(controller.phase, TownPhase.home);
    });

    test('kontrolcü: mini oyunda dokun-yürü çalışır, bitmiş oyunda yok sayılır',
        () {
      final controller = TownController(random: Random(2));
      controller.startFreeMiniGame(MiniGameKind.stars);
      final world = controller.session!.world;
      controller.tapTile(9, 14);
      expect(world.hasPath, isTrue);

      world.teleport(world.spawnX, world.spawnY);
      controller.session!.finish();
      final before = world.hasPath;
      controller.tapTile(3, 7);
      expect(world.hasPath, before, reason: 'bitmiş oyunda yol kurulmaz');
    });

    testWidgets('fareyle: altına tıklayınca avatar yürüyüp toplar', (tester) async {
      await openTown(tester);
      await tester.tap(find.byKey(const Key('townEnter')));
      await tester.pump();
      final controller = controllerOf(tester);
      final world = controller.world;

      final tapArea = find.byKey(const Key('townWorldTap'));
      final size = tester.getSize(tapArea);
      final origin = tester.getTopLeft(tapArea);

      // Başlangıca en yakın altın.
      final coin = world.coins.reduce((a, b) {
        double d(WorldCoin c) =>
            (c.x - world.x) * (c.x - world.x) + (c.y - world.y) * (c.y - world.y);
        return d(a) <= d(b) ? a : b;
      });
      final before = controller.profile.coins;
      await tester.tapAt(
        origin +
            localOf(
              world,
              size,
              IsoProjection.toScreen(coin.x, coin.y) + const Offset(0, -12),
            ),
      );
      await tester.pump();
      expect(world.hasPath, isTrue, reason: 'altına yürümek için yol kurulmalı');

      for (var i = 0; i < 40 && coin.active; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(coin.active, isFalse, reason: 'altın toplanmalı');
      expect(controller.profile.coins, greaterThan(before));
    });

    testWidgets('fareyle: binaya tıkla → kapıya yürür, tekrar tıkla → içeri girer',
        (tester) async {
      await openTown(tester);
      await tester.tap(find.byKey(const Key('townEnter')));
      await tester.pump();
      final controller = controllerOf(tester);
      final world = controller.world;
      final b = world.map.buildings.firstWhere((b) => b.kind == DoorKind.arcade);

      final tapArea = find.byKey(const Key('townWorldTap'));
      final size = tester.getSize(tapArea);
      final origin = tester.getTopLeft(tapArea);

      Offset roof() => origin +
          localOf(
            world,
            size,
            IsoProjection.toScreen(b.x + b.w / 2, b.y + b.h / 2) +
                const Offset(0, -40),
          );

      await tester.tapAt(roof());
      await tester.pump();
      for (var i = 0; i < 80 && world.nearbyDoor?.kind != DoorKind.arcade; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(world.nearbyDoor?.kind, DoorKind.arcade);
      expect(controller.phase, TownPhase.town);

      await tester.tapAt(roof());
      await tester.pump();
      expect(controller.phase, TownPhase.arcade);
    });

    testWidgets('fareyle: yıldız yağmurunda yıldıza tıklayınca toplanır',
        (tester) async {
      await openTown(tester);
      await tester.tap(find.byKey(const Key('townEnter')));
      await tester.pump();
      final controller = controllerOf(tester);
      controller.startFreeMiniGame(MiniGameKind.stars);
      await tester.pump();
      final session = controller.session!;
      final world = session.world;

      final tapArea = find.byKey(const Key('townWorldTap'));
      final size = tester.getSize(tapArea);
      final origin = tester.getTopLeft(tapArea);

      final star = world.coins.reduce((a, b) {
        double d(WorldCoin c) =>
            (c.x - world.x) * (c.x - world.x) + (c.y - world.y) * (c.y - world.y);
        return d(a) <= d(b) ? a : b;
      });
      await tester.tapAt(
        origin +
            localOf(
              world,
              size,
              IsoProjection.toScreen(star.x, star.y) + const Offset(0, -12),
            ),
      );
      await tester.pump();
      for (var i = 0; i < 40 && session.score == 0; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(session.score, greaterThanOrEqualTo(10));
    });
  });
}

/// Platform ana menüsünden Elektrik Atölyesi'ne girer (katalogdaki 13. kart).
Future<void> _openElectricity(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 7200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Elektrik Atölyesi'));
  await tester.pumpAndSettle();
}

/// Platform ana menüsünden Bitki Laboratuvarı'na girer. Katalogdaki 12. kart;
/// görünümü uzatıyoruz ki kart ve oyun ekranındaki her düğme kaydırmadan
/// dokunulabilir olsun (bkz. _openMultiplication).
Future<void> _openPlantLab(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 6600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const GamePlatformApp());
  await tester.tap(find.text('Bitki Laboratuvarı'));
  await tester.pumpAndSettle();
}

class _FakeMoveSounds implements ChessMoveSounds {
  final calls = <String>[];
  bool disposed = false;

  @override
  void playNormalMove() => calls.add('normal');

  @override
  void playCaptureSound() => calls.add('capture');

  @override
  void playCheckSound() => calls.add('check');

  @override
  void dispose() => disposed = true;
}

class _FakeTownSounds implements TownSounds {
  final calls = <String>[];
  bool musicPlaying = false;
  bool disposed = false;

  @override
  void step() => calls.add('step');

  @override
  void coin() => calls.add('coin');

  @override
  void star() => calls.add('star');

  @override
  void doorNear() => calls.add('doorNear');

  @override
  void doorOpen() => calls.add('doorOpen');

  @override
  void purchase() => calls.add('purchase');

  @override
  void denied() => calls.add('denied');

  @override
  void placeItem() => calls.add('placeItem');

  @override
  void chest() => calls.add('chest');

  @override
  void bump() => calls.add('bump');

  @override
  void gameStart() => calls.add('gameStart');

  @override
  void win() => calls.add('win');

  @override
  void lose() => calls.add('lose');

  @override
  void startMusic() => musicPlaying = true;

  @override
  void stopMusic() => musicPlaying = false;

  @override
  void dispose() => disposed = true;
}
