import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bombali_sayilar/controllers/archimedes_controller.dart';
import 'package:bombali_sayilar/controllers/curie_controller.dart';
import 'package:bombali_sayilar/controllers/newton_controller.dart';
import 'package:bombali_sayilar/controllers/profile_controller.dart';
import 'package:bombali_sayilar/data/archimedes_objects.dart';
import 'package:bombali_sayilar/data/science_sound_clips.dart';
import 'package:bombali_sayilar/data/scientists_catalog.dart';
import 'package:bombali_sayilar/games/archimedes_game.dart';
import 'package:bombali_sayilar/games/curie_game.dart';
import 'package:bombali_sayilar/games/einstein_game.dart';
import 'package:bombali_sayilar/games/fleming_game.dart';
import 'package:bombali_sayilar/games/galileo_game.dart';
import 'package:bombali_sayilar/games/newton_game.dart';
import 'package:bombali_sayilar/games/tesla_game.dart';
import 'package:bombali_sayilar/models/science/scientist_phase.dart';
import 'package:bombali_sayilar/services/audio/clip_synth.dart';
import 'package:bombali_sayilar/services/scientist_sounds.dart';

/// Çalınan sesleri kaydeden sahte ses servisi.
class _FakeSounds implements ScientistSounds {
  final played = <ScienceSound>[];
  bool loaded = false;

  @override
  bool enabled = true;

  @override
  Future<void> load() async => loaded = true;

  @override
  void play(ScienceSound sound) => played.add(sound);

  @override
  void dispose() {}
}

Future<void> _pumpNewton(WidgetTester tester, NewtonController controller) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider.value(value: controller),
      ],
      child: const MaterialApp(home: NewtonGameRoot()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Bilim insanı sesleri', () {
    test('her sesin bir klibi var; klipler duyulur ve sessiz biter', () {
      for (final sound in ScienceSound.values) {
        final clip = scienceSoundClips[sound];
        expect(clip, isNotNull, reason: '$sound klibi yok');
        final samples = renderClip(clip!);
        expect(samples, isNotEmpty, reason: '$sound');
        final peak = samples.map((s) => s.abs()).reduce(max);
        expect(peak, greaterThan(0.05), reason: '$sound duyulmuyor');
        expect(peak, lessThanOrEqualTo(1.0), reason: '$sound');
        expect(samples.last.abs(), lessThan(0.02), reason: '$sound tıkla bitiyor');
      }
    });

    test('görev akışı: doğru, yanlış, sıra devri, bitiş', () {
      final sounds = _FakeSounds();
      final c = NewtonController(random: Random(3))..attachSounds(sounds);
      c.startGame(['A', 'B']);
      c.answer(c.currentTask.correctIndex);
      expect(sounds.played.last, ScienceSound.correct);
      c.continueAfterResult();
      c.answer((c.currentTask.correctIndex + 1) % c.currentTask.options.length);
      expect(sounds.played.last, ScienceSound.wrong);
      c.continueAfterResult();
      while (c.phase == ScientistPhase.playing) {
        c.answer(0);
        c.continueAfterResult();
      }
      expect(c.phase, ScientistPhase.turnTransition);
      expect(sounds.played.last, ScienceSound.turn);
      c.acknowledgeTurnTransition();
      while (c.phase == ScientistPhase.playing) {
        c.answer(0);
        c.continueAfterResult();
      }
      expect(c.phase, ScientistPhase.finished);
      expect(sounds.played.last, ScienceSound.fanfare);
    });

    test('ses kapalıyken hiçbir şey çalmaz; ses yoksa sessiz çalışır', () {
      final sounds = _FakeSounds();
      final c = ArchimedesController()..attachSounds(sounds);
      expect(c.soundOn, isTrue);
      c.toggleSound();
      expect(c.soundOn, isFalse);
      c.startExplore();
      c.dropSelected();
      expect(sounds.played, isEmpty);

      final silent = ArchimedesController()..startExplore();
      expect(silent.hasSounds, isFalse);
      silent.dropSelected();
      expect(silent.tankObjects, hasLength(1));
    });

    test('deney sesleri: Arşimet kabı, gemi batışı, vida; Curie sayacı', () {
      final sounds = _FakeSounds();
      final a = ArchimedesController()..attachSounds(sounds);
      a.startExplore();
      a.dropSelected();
      expect(sounds.played.last, ScienceSound.splash);
      a.emptyTank();
      expect(sounds.played.last, ScienceSound.bubbles);

      a.selectBoat(archimedesBoats.first);
      final boat = archimedesBoats.first;
      for (var i = 0; i < boat.maxCrates; i++) {
        a.addCrate();
        expect(sounds.played.last, ScienceSound.knock);
      }
      a.addCrate();
      expect(boat.sinks(a.exploreCrates), isTrue);
      expect(sounds.played.last, ScienceSound.bubbles, reason: 'gemi battı');

      a.setScrewAngle(30);
      sounds.played.clear();
      for (var i = 0; i < 400 && a.fieldLitres < 1e9; i++) {
        a.turnCrank(0.25);
        if (sounds.played.contains(ScienceSound.ding)) break;
      }
      expect(sounds.played, contains(ScienceSound.trickle));
      expect(sounds.played.where((s) => s == ScienceSound.ding), hasLength(1),
          reason: 'tarla dolunca bir kez zil');

      final curie = CurieController()..attachSounds(sounds);
      curie.geigerClick();
      expect(sounds.played.last, ScienceSound.geiger);
    });
  });

  group('Bilim insanının adı', () {
    test('her oyunun ayarı kendi bilim insanını taşır', () {
      final configs = {
        archimedesConfig: archimedesScientist,
        newtonConfig: newtonScientist,
        galileoConfig: galileoScientist,
        teslaConfig: teslaScientist,
        curieConfig: curieScientist,
        einsteinConfig: einsteinScientist,
        flemingConfig: flemingScientist,
      };
      for (final entry in configs.entries) {
        expect(entry.key.scientist.id, entry.value.id);
      }
      expect(configs.values.map((s) => s.id).toSet(), hasLength(scientists.length));
    });

    testWidgets('kurulum, görev ve keşif ekranlarında ad etiketi var', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = NewtonController();
      await _pumpNewton(tester, controller);
      Finder badgeName() => find.descendant(
        of: find.byKey(const Key('scientistNameBadge')),
        matching: find.text(newtonScientist.name),
      );
      expect(badgeName(), findsOneWidget);

      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();
      expect(badgeName(), findsOneWidget);
      // Etiket sahnenin sol üst köşesinde.
      final scene = tester.getRect(find.byKey(const Key('scientistScene')));
      final badge = tester.getRect(find.byKey(const Key('scientistNameBadge')));
      expect(badge.left - scene.left, lessThan(20));
      expect(badge.top - scene.top, lessThan(20));

      controller.startExplore();
      await tester.pumpAndSettle();
      expect(badgeName(), findsOneWidget);
    });

    testWidgets('ses düğmesi yalnızca ses varken görünür ve sesi kapatır', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpNewton(tester, NewtonController());
      expect(find.byKey(const Key('scientistSoundToggle')), findsNothing);

      final sounds = _FakeSounds();
      final controller = NewtonController()..attachSounds(sounds);
      await _pumpNewton(tester, controller);
      expect(sounds.loaded, isTrue);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      await tester.tap(find.byKey(const Key('scientistSoundToggle')));
      await tester.pumpAndSettle();
      expect(sounds.enabled, isFalse);
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
    });
  });
}
