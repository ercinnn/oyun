import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bombali_sayilar/controllers/archimedes_controller.dart';
import 'package:bombali_sayilar/data/archimedes_objects.dart';
import 'package:bombali_sayilar/data/scientists_catalog.dart';
import 'package:bombali_sayilar/games/archimedes_game.dart';
import 'package:bombali_sayilar/games/scientists_game.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/science/scientist_phase.dart';
import 'package:bombali_sayilar/models/archimedes/archimedes_scene.dart';
import 'package:bombali_sayilar/models/archimedes/archimedes_screw.dart';
import 'package:bombali_sayilar/models/archimedes/archimedes_task.dart';
import 'package:bombali_sayilar/models/archimedes/buoyancy.dart';
import 'package:bombali_sayilar/models/archimedes/crown.dart';
import 'package:bombali_sayilar/screens/game_catalog_screen.dart';

/// GLB'nin JSON bölümünü saf Dart'ta okur (WebGL gerekmez); kök düğüm
/// adlarını ve tüm düğüm adlarını döndürür.
({Set<String> roots, Set<String> all}) _glbNodeNames(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(data.getUint32(0, Endian.little), 0x46546C67, reason: 'glTF sihirli sayısı');
  final length = data.getUint32(12, Endian.little);
  final gltf = jsonDecode(utf8.decode(bytes.sublist(20, 20 + length)))
      as Map<String, Object?>;
  final nodes = (gltf['nodes'] as List).cast<Map<String, Object?>>();
  final sceneRoots =
      ((gltf['scenes'] as List).first as Map<String, Object?>)['nodes'] as List;
  return (
    roots: {for (final i in sceneRoots) nodes[i as int]['name'] as String},
    all: {for (final n in nodes) n['name'] as String},
  );
}

/// Oyunu hub'a girmeden doğrudan Arşimet route'unda açar.
Future<void> _openArchimedes(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.pushNamed(ArchimedesGame.routeName);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Arşimet modeli', () {
    test('yüzme ⇔ yoğunluk < 1; yüzen cisim yoğunluğu kadar gömülür', () {
      for (final o in archimedesObjects) {
        expect(o.floats, o.massG / o.volumeCm3 < 1, reason: o.id);
        if (o.floats) {
          expect(o.displacedCm3, closeTo(o.massG, 1e-9),
              reason: '${o.id}: yüzen cisim kendi ağırlığı kadar su iter');
        } else {
          expect(o.displacedCm3, o.volumeCm3, reason: o.id);
        }
      }
      expect(archimedesObjectById('wood').floats, isTrue);
      expect(archimedesObjectById('stone').floats, isFalse);
      expect(archimedesObjectById('ice').submergedFraction, greaterThan(0.9));
    });

    test('oyun hamuru: aynı kütle, top batar kase yüzer', () {
      final ball = archimedesObjectById('clay_ball');
      final bowl = archimedesObjectById('clay_bowl');
      expect(ball.massG, bowl.massG);
      expect(ball.floats, isFalse);
      expect(bowl.floats, isTrue);
    });

    test('su seviyesi: 100 cm³ = 1 cm, kap ağzını aşmaz', () {
      final stone = archimedesObjectById('stone');
      expect(stone.waterRiseCm, closeTo(1.5, 1e-9));
      expect(tankWaterLevelCm([stone]), closeTo(tankStartWaterCm + 1.5, 1e-9));
      expect(tankWaterLevelCm(List.filled(100, stone)), tankHeightCm);
    });

    test('taç: aynı ağırlıkta sahte taç daha çok su taşırır', () {
      expect(goldCrown.massG, fakeCrown.massG);
      expect(fakeCrown.displacedCm3, greaterThan(goldCrown.displacedCm3 + 8));
      expect(goldCrown.floats, isFalse);
      expect(fakeCrown.floats, isFalse);
    });

    test('gemi: maxCrates sandıkta yüzer, bir fazlasında batar', () {
      final maxes = <int>{};
      for (final boat in archimedesBoats) {
        expect(boat.maxCrates, greaterThan(0), reason: boat.id);
        expect(boat.sinks(boat.maxCrates), isFalse, reason: boat.id);
        expect(boat.sinks(boat.maxCrates + 1), isTrue, reason: boat.id);
        expect(boat.draftCm(1), greaterThan(boat.draftCm(0)));
        maxes.add(boat.maxCrates);
      }
      expect(maxes.length, archimedesBoats.length,
          reason: 'gemilerin kapasiteleri birbirinden farklı olmalı');
    });

    test('vida: çok yatık yetişmez, çok dik su dökülür, orta açı en iyisi', () {
      expect(screwReachesField(15), isFalse);
      expect(screwLitresPerTurn(15), 0);
      expect(screwLitresPerTurn(70), 0);
      expect(screwLitresPerTurn(30), greaterThan(screwLitresPerTurn(45)));
      expect(screwTurnsToFill(70), isNull);
      for (final set in archimedesScrewAngleSets) {
        final turns = [for (final a in set) screwTurnsToFill(a)];
        final valid = turns.whereType<int>().toList()..sort();
        expect(valid, isNotEmpty, reason: '$set');
        if (valid.length > 1) {
          expect(valid[0], lessThan(valid[1]),
              reason: '$set: tek bir en iyi açı olmalı');
        }
        expect(ScrewTask(set).correctIndex, greaterThanOrEqualTo(0));
      }
    });

    test('cisim tablosu: kimlikler tekil, en az 3 yüzen ve 3 batan', () {
      final ids = archimedesObjects.map((o) => o.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(archimedesObjects.where((o) => o.floats).length, greaterThanOrEqualTo(3));
      expect(archimedesObjects.where((o) => !o.floats).length, greaterThanOrEqualTo(3));
    });

    test('3B modeller: her cismin, taçların, gemilerin ve düzeneğin GLB grubu var', () {
      final names = _glbNodeNames('assets/models/archimedes.glb');
      final required = [
        for (final o in archimedesObjects) o.modelId,
        goldCrown.modelId,
        fakeCrown.modelId,
        for (final b in archimedesBoats) 'arch_boat_${b.id}',
        'arch_tank',
        'arch_beaker',
        'arch_crate',
        'arch_screw',
        'arch_field',
        'arch_lab',
        'arch_archimedes',
      ];
      for (final id in required) {
        expect(names.roots, contains(id),
            reason: '$id için GLB grubu yok — tool/blender/build_archimedes.py '
                'çalıştırılıp yeniden dışa aktarılmalı');
      }
      // 3B görünüm bu iç düğümleri adla arar.
      expect(names.all, containsAll(['ScrewRotor', 'Sprouts']));
    });

    test('sayı biçimi Türkçe ondalık virgülü kullanır', () {
      expect(formatTr(1.5), '1,5');
      expect(formatTr(2.0), '2');
      expect(formatTr(51.8, digits: 0), '52');
    });
  });

  group('Arşimet görevleri', () {
    ArchimedesController playAll(ArchimedesController c, {bool correct = true}) {
      while (c.phase == ScientistPhase.playing ||
          c.phase == ScientistPhase.turnTransition) {
        if (c.phase == ScientistPhase.turnTransition) {
          c.acknowledgeTurnTransition();
          continue;
        }
        final task = c.currentTask;
        c.answer(correct ? task.correctIndex : (task.correctIndex + 1) % task.options.length);
        c.continueAfterResult();
      }
      return c;
    }

    test('her oyuncu 8 görev görür, her türden tam 2, biri taç', () {
      for (var seed = 0; seed < 20; seed++) {
        final c = ArchimedesController(random: Random(seed))..startGame(['A']);
        final kinds = <ArchimedesTaskKind, int>{};
        var crowns = 0;
        var floats = 0;
        while (c.phase == ScientistPhase.playing) {
          final t = c.currentTask;
          kinds[t.kind] = (kinds[t.kind] ?? 0) + 1;
          if (t is CrownTask) crowns++;
          if (t is FloatSinkTask && t.object.floats) floats++;
          expect(t.correctIndex, inInclusiveRange(0, t.options.length - 1));
          expect(t.options.toSet().length, t.options.length, reason: 'seçenekler tekil');
          c.answer(t.correctIndex);
          c.continueAfterResult();
        }
        expect(c.phase, ScientistPhase.finished);
        for (final k in ArchimedesTaskKind.values) {
          expect(kinds[k], 2, reason: 'seed $seed, $k');
        }
        expect(crowns, 1, reason: 'seed $seed');
        expect(floats, 1, reason: 'seed $seed: bir yüzen, bir batan cisim');
        expect(c.players.single.correctCount, archimedesRoundsPerPlayer);
      }
    });

    test('doğru cevap modelden gelir', () {
      final c = ArchimedesController(random: Random(3))..startGame(['A']);
      while (c.phase == ScientistPhase.playing) {
        final t = c.currentTask;
        switch (t) {
          case FloatSinkTask():
            expect(t.correctIndex, t.object.floats ? 0 : 1);
          case DisplacementTask():
            expect(t.a.displacedCm3, isNot(t.b.displacedCm3));
            final bigger = t.a.displacedCm3 > t.b.displacedCm3 ? 0 : 1;
            expect(t.correctIndex, bigger);
          case CrownTask():
            final fakeIndex = t.fakeIsA ? 0 : 1;
            expect(t.correctIndex, fakeIndex);
          case BoatTask():
            expect(t.choices[t.correctIndex], t.boat.maxCrates);
            expect(t.choices.every((n) => n >= 1), isTrue);
          case ScrewTask():
            final best = t.angles[t.correctIndex];
            for (final a in t.angles) {
              final turns = screwTurnsToFill(a);
              if (turns != null) {
                expect(screwTurnsToFill(best)!, lessThanOrEqualTo(turns));
              }
            }
        }
        c.answer(t.correctIndex);
        c.continueAfterResult();
      }
    });

    test('sonuç gösterilirken ikinci cevap sayılmaz, tur ilerlemez', () {
      final c = ArchimedesController(random: Random(1))..startGame(['A']);
      final task = c.currentTask;
      c.answer(task.correctIndex);
      expect(c.showingResult, isTrue);
      expect(c.players.single.roundsPlayed, 1);
      c.answer((task.correctIndex + 1) % task.options.length);
      expect(c.players.single.roundsPlayed, 1);
      expect(c.lastAnswerCorrect, isTrue);
      expect(identical(c.currentTask, task), isTrue);
      // Sonuç sahnesi deneyi oynatır (revision artar).
      expect(c.scene.revision, greaterThan(0));
      c.continueAfterResult();
      expect(c.showingResult, isFalse);
      expect(c.scene.revision, 0);
    });

    test('iki oyuncu: devir ekranı, sıralama ve yeniden başlatma', () {
      final c = ArchimedesController(random: Random(7))..startGame(['Ada', 'Can']);
      for (var i = 0; i < archimedesRoundsPerPlayer; i++) {
        c.answer(c.currentTask.correctIndex);
        c.continueAfterResult();
      }
      expect(c.phase, ScientistPhase.turnTransition);
      expect(c.currentPlayer.name, 'Can');
      c.acknowledgeTurnTransition();
      playAll(c, correct: false);
      expect(c.phase, ScientistPhase.finished);
      expect(c.rankedByCorrect.first.name, 'Ada');
      expect(c.rankedByCorrect.last.correctCount, 0);
      c.restart();
      expect(c.phase, ScientistPhase.setup);
    });

    test('Keşif: cisim bırakma, gemi batması ve vida', () {
      final c = ArchimedesController()..startExplore();
      expect(c.phase, ScientistPhase.explore);
      final stone = archimedesObjectById('stone');
      c.selectObject(stone);
      c.dropSelected();
      c.dropSelected(); // aynı cisim ikinci kez eklenmez
      expect(c.tankObjects, [stone]);
      expect(c.scene.tanks.single.held, isNull);
      expect(c.scene.tanks.single.waterLevelCm, closeTo(11.5, 1e-9));
      for (final id in ['wood', 'cork', 'apple', 'ball']) {
        c.selectObject(archimedesObjectById(id));
        c.dropSelected();
      }
      expect(c.tankObjects.length, archimedesTankCapacity);
      c.emptyTank();
      expect(c.tankObjects, isEmpty);

      c.setStation(ArchimedesStation.boat);
      final boat = archimedesBoats.first;
      c.selectBoat(boat);
      for (var i = 0; i < 20; i++) {
        c.addCrate();
      }
      expect(c.exploreCrates, boat.maxCrates + 1, reason: 'batınca yük eklenmez');
      expect(boat.sinks(c.exploreCrates), isTrue);
      c.removeCrate();
      expect(boat.sinks(c.exploreCrates), isFalse);

      c.setStation(ArchimedesStation.screw);
      c.setScrewAngle(70);
      c.turnCrank(5);
      expect(c.fieldLitres, 0);
      c.setScrewAngle(25);
      c.turnCrank(100);
      expect(c.fieldLitres, fieldNeedLitres);
      c.turnCrank(-3);
      expect(c.screwTurns, 105);
      expect(c.scene.station, ArchimedesStation.screw);
    });
  });

  group('Bilim İnsanları ekranları', () {
    testWidgets('katalogda kart var; hub 7 bilim insanını gösterir, hepsi oynanabilir',
        (tester) async {
      expect(gameCatalog.any((e) => e.routeName == ScientistsGame.routeName), isTrue);
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const GamePlatformApp());
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pushNamed(ScientistsGame.routeName);
      await tester.pumpAndSettle();

      expect(scientists.length, 7);
      for (final s in scientists) {
        expect(find.byKey(Key('scientist_${s.id}')), findsOneWidget);
      }
      expect(scientists.where((s) => s.available).map((s) => s.id), ['arsimet', 'galileo', 'newton', 'tesla', 'curie', 'einstein', 'fleming']);
      expect(find.text('Yakında'), findsNothing);

      await tester.tap(find.byKey(const Key('scientist_arsimet')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scientistStart')), findsOneWidget);
    });

    testWidgets('görevler 2B görünümde sonuç ekranına kadar oynanır', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openArchimedes(tester);
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();

      for (var i = 0; i < archimedesRoundsPerPlayer; i++) {
        expect(find.textContaining('Görev ${i + 1} /'), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistOption_0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('scientistExplanation')), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistContinue')));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Tebrikler'), findsOneWidget);
      expect(find.textContaining('/ $archimedesRoundsPerPlayer doğru'), findsOneWidget);
    });

    testWidgets('Keşif Atölyesi: cismi bırakınca su seviyesi yükselir, kol vidayı çevirir',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openArchimedes(tester);
      await tester.tap(find.byKey(const Key('scientistExplore')));
      await tester.pumpAndSettle();

      expect(find.text('Su seviyesi: 10 cm (başta 10 cm)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('archObj_stone')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('archimedesDrop')));
      await tester.pumpAndSettle();
      expect(find.text('Su seviyesi: 11,5 cm (başta 10 cm)'), findsOneWidget);
      expect(find.textContaining('battı'), findsOneWidget);

      await tester.tap(find.text('Gemi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archimedesCratePlus')));
      await tester.pumpAndSettle();
      expect(find.text('1 sandık'), findsOneWidget);

      await tester.tap(find.text('Arşimet Vidası'));
      await tester.pumpAndSettle();
      expect(find.text('Tarla: 0 / 20 litre'), findsOneWidget);
      // Kolu saat yönünde iki tam tur çevir.
      final crank = find.byKey(const Key('archimedesCrank'));
      final center = tester.getCenter(crank);
      final gesture = await tester.startGesture(center + const Offset(50, 0));
      for (var step = 1; step <= 48; step++) {
        final a = step * 2 * pi / 24;
        await gesture.moveTo(center + Offset(cos(a), sin(a)) * 50);
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Tarla: 0 / 20 litre'), findsNothing,
          reason: 'kol çevrilince tarlaya su gitmeli (30°)');

      // Geri tuşu kurulum ekranına döner.
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scientistStart')), findsOneWidget);
    });

    testWidgets('dar ekranda (320 px) taşma yok', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openArchimedes(tester);
      // Katalog kartları 320 px'te zaten taşıyor (CLAUDE.md), bu yüzden oyuna
      // geniş görünümde girip sonra daraltıyoruz.
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('scientistStart')));
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.ensureVisible(find.byKey(const Key('scientistOption_1')));
        await tester.tap(find.byKey(const Key('scientistOption_1')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('scientistContinue')));
        await tester.tap(find.byKey(const Key('scientistContinue')));
        await tester.pumpAndSettle();
      }
      // Keşif ekranı da dar ekranda açılabilmeli.
      final controller = Provider.of<ArchimedesController>(
        tester.element(find.byKey(const Key('scientistScene'))),
        listen: false,
      );
      controller.startExplore();
      await tester.pumpAndSettle();
      for (final s in ArchimedesStation.values) {
        controller.setStation(s);
        await tester.pumpAndSettle();
      }
    });
  });
}
