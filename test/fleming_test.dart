import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bombali_sayilar/controllers/fleming_controller.dart';
import 'package:bombali_sayilar/games/fleming_game.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/fleming/fleming_scene.dart';
import 'package:bombali_sayilar/models/fleming/fleming_task.dart';
import 'package:bombali_sayilar/models/fleming/hygiene.dart';
import 'package:bombali_sayilar/models/fleming/petri.dart';
import 'package:bombali_sayilar/models/fleming/resistance.dart';
import 'package:bombali_sayilar/models/science/scientist_phase.dart';

Set<String> _glbNodeNames(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  final length = data.getUint32(12, Endian.little);
  final gltf = jsonDecode(utf8.decode(bytes.sublist(20, 20 + length)))
      as Map<String, Object?>;
  return {
    for (final n in (gltf['nodes'] as List).cast<Map<String, Object?>>())
      n['name'] as String,
  };
}

Future<void> _openFleming(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamed(FlemingGame.routeName);
  await tester.pumpAndSettle();
}

FlemingController _controllerOf(WidgetTester tester) =>
    Provider.of<FlemingController>(
      tester.element(find.byKey(const Key('scientistScene'))),
      listen: false,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Fleming modeli', () {
    test('petri: küflü kapta temiz halka, kontrol kabında hepsi büyür', () {
      expect(livingColonies(0, mold: true), 0);
      expect(livingColonies(5, mold: false), petriColonyCount);
      expect(livingColonies(5, mold: true), lessThan(petriColonyCount));
      var previous = petriColonyCount;
      for (var d = 1; d <= petriMaxDays; d++) {
        final n = livingColonies(d.toDouble(), mold: true);
        expect(n, lessThanOrEqualTo(previous), reason: 'halka genişledikçe azalır');
        previous = n;
      }
      for (final c in petriColonies) {
        expect(c.x * c.x + c.y * c.y, lessThanOrEqualTo(0.81), reason: 'kabın içinde');
      }
    });

    test('temizlik: kapalı ve dokunulmamış kap temiz; kirli el en çok', () {
      expect(hygieneColonies(lidOpen: false, hand: HandTouch.none), 0);
      expect(hygieneColonies(lidOpen: false, hand: HandTouch.unwashed),
          greaterThan(hygieneColonies(lidOpen: false, hand: HandTouch.washed)));
      final counts = flemingHygieneSetups.map((s) => s.colonies).toList();
      expect(counts.toSet().length, counts.length, reason: 'düzenekler ayırt edilebilir');
    });

    test('ilaç: tam süre temizler; erken bırakınca dayanıklılar artar', () {
      expect(finalPopulation(fullCourseDays).cleared, isTrue);
      for (final t in [3, 4, 5]) {
        final end = finalPopulation(t);
        expect(end.cleared, isFalse, reason: 'T=$t');
        expect(end.resistantShare,
            greaterThan(simulateTreatment(t).first.resistantShare), reason: 'T=$t');
      }
      expect(antibioticWorks(Pathogen.bacteria), isTrue);
      expect(antibioticWorks(Pathogen.virus), isFalse);
    });

    test('3B modeller: gruplar ve iç düğümler GLB\'de', () {
      final names = _glbNodeNames('assets/models/fleming.glb');
      for (final id in [
        'fleming_figure', 'fleming_lab', 'fleming_dish', 'fleming_microscope',
        'fleming_sink', 'fleming_bottle', 'Lid', 'agar', 'fld_base_glass', 'fld_lid_glass',
      ]) {
        expect(names, contains(id),
            reason: '$id yok — tool/blender/build_fleming.py çalıştırılmalı');
      }
    });
  });

  group('Fleming görevleri', () {
    test('6 görev, her türden 2; doğru cevap modelden', () {
      for (var seed = 0; seed < 30; seed++) {
        final c = FlemingController(random: Random(seed))..startGame(['A']);
        final kinds = <FlemingTaskKind, int>{};
        final types = <Type>{};
        while (c.phase == ScientistPhase.playing) {
          final t = c.currentTask;
          kinds[t.kind] = (kinds[t.kind] ?? 0) + 1;
          types.add(t.runtimeType);
          expect(t.correctIndex, inInclusiveRange(0, t.options.length - 1),
              reason: 'seed $seed ${t.prompt}');
          expect(t.options.toSet().length, t.options.length, reason: t.prompt);
          switch (t) {
            case ZoneTask():
              expect(t.options[t.correctIndex], ZoneTask.clear);
            case ControlDishTask():
              expect(t.correctIndex, 0, reason: 'küflü kapta daha az');
            case DirtiestDishTask():
              final best = t.setups.map((s) => s.colonies).reduce(max);
              expect(t.setups[t.correctIndex].colonies, best);
            case ColonyCountTask():
              expect(t.choices[t.correctIndex], t.setup.colonies);
            case StopEarlyTask():
              expect(t.options[t.correctIndex], StopEarlyTask.returns);
            case VirusTask():
              expect(t.correctIndex, antibioticWorks(t.pathogen) ? 0 : 1);
          }
          c.answer(t.correctIndex);
          c.continueAfterResult();
        }
        expect(c.phase, ScientistPhase.finished);
        for (final k in FlemingTaskKind.values) {
          expect(kinds[k], 2, reason: 'seed $seed $k');
        }
        expect(types.length, 6, reason: 'seed $seed');
        expect(c.players.single.correctCount, flemingRoundsPerPlayer);
      }
    });

    test('Keşif: gün, kapak/el, ilaç süresi', () {
      final c = FlemingController()..startExplore();
      c.setDay(99);
      expect(c.day, petriMaxDays);
      c.setStation(FlemingStation.hygiene);
      c.setLid(true);
      c.setHand(HandTouch.unwashed);
      expect(c.scene.hygieneCount, 0, reason: 'bekletilmeden koloni yok');
      c.incubate();
      expect(c.scene.hygieneCount, openLidColonies + HandTouch.unwashed.colonies);
      c.setHand(HandTouch.washed);
      expect(c.incubated, isFalse, reason: 'ayar değişince yeniden beklet');
      c.setStation(FlemingStation.medicine);
      c.setTreatmentDays(99);
      expect(c.treatmentDays, fullCourseDays);
      c.runCourse();
      expect(c.scene.medicineDay, observedDays);
    });
  });

  group('Fleming ekranları', () {
    testWidgets('görevler 2B görünümde sonuç ekranına kadar oynanır', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openFleming(tester);
      expect(find.text('Fleming\'in Laboratuvarı'), findsOneWidget);
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();
      for (var i = 0; i < flemingRoundsPerPlayer; i++) {
        expect(find.textContaining('Görev ${i + 1} /'), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistOption_0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('scientistExplanation')), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistContinue')));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Tebrikler'), findsOneWidget);
    });

    testWidgets('Laboratuvar: petri, temizlik, ilaç', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openFleming(tester);
      await tester.tap(find.byKey(const Key('scientistExplore')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('flemingNextDay')));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('temiz bir halka'), findsOneWidget);

      await tester.tap(find.text('Temizlik'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('flemingHand_unwashed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('flemingIncubate')));
      await tester.pumpAndSettle();
      expect(find.textContaining('${HandTouch.unwashed.colonies} koloni üredi'), findsOneWidget);

      await tester.tap(find.text('Doğru İlaç'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('flemingRunCourse')));
      await tester.pumpAndSettle();
      expect(find.textContaining('İlaç erken bırakıldı'), findsOneWidget);
      _controllerOf(tester).setTreatmentDays(fullCourseDays);
      _controllerOf(tester).runCourse();
      await tester.pumpAndSettle();
      expect(find.textContaining('bakteri kalmadı'), findsOneWidget);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scientistStart')), findsOneWidget);
    });

    testWidgets('dar ekranda (320 px) taşma yok', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openFleming(tester);
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('scientistStart')));
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.ensureVisible(find.byKey(const Key('scientistOption_1')));
        await tester.tap(find.byKey(const Key('scientistOption_1')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('scientistContinue')));
        await tester.tap(find.byKey(const Key('scientistContinue')));
        await tester.pumpAndSettle();
      }
      final c = _controllerOf(tester);
      c.startExplore();
      await tester.pumpAndSettle();
      for (final s in FlemingStation.values) {
        c.setStation(s);
        await tester.pumpAndSettle();
      }
    });
  });
}
