import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bombali_sayilar/controllers/galileo_controller.dart';
import 'package:bombali_sayilar/games/galileo_game.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/galileo/galileo_scene.dart';
import 'package:bombali_sayilar/models/galileo/galileo_task.dart';
import 'package:bombali_sayilar/models/galileo/jupiter.dart';
import 'package:bombali_sayilar/models/galileo/solar.dart';
import 'package:bombali_sayilar/models/galileo/telescope.dart';
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

Future<void> _openGalileo(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamed(GalileoGame.routeName);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Galileo modeli', () {
    test('teleskop: büyütme bölüm, net tüp fark (içbükey göz merceği)', () {
      expect(magnification(90, 5), 18);
      expect(sharpTubeCm(90, 5), 85);
      expect(isSharp(90, 5, 85), isTrue);
      expect(isSharp(90, 5, 95), isFalse, reason: 'toplam, Kepler teleskobudur');
      for (final fo in objectiveLensesCm) {
        for (final fe in eyepieceLensesCm) {
          final t = sharpTubeCm(fo, fe);
          expect(t, inInclusiveRange(tubeMinCm, tubeMaxCm),
              reason: '$fo/$fe: net tüp kaydırıcıyla bulunabilmeli');
        }
      }
    });

    test('Jüpiter: yakın uydu daha hızlı; periyot sonunda aynı yerde', () {
      for (var i = 1; i < jupiterMoons.length; i++) {
        expect(jupiterMoons[i].distance, greaterThan(jupiterMoons[i - 1].distance));
        expect(jupiterMoons[i].periodDays, greaterThan(jupiterMoons[i - 1].periodDays));
      }
      for (final m in jupiterMoons) {
        expect(m.skyX(m.periodDays), closeTo(m.skyX(0), 1e-9));
        expect(m.skyX(0).abs(), lessThanOrEqualTo(m.distance));
      }
      expect(notebookSketch(0), contains('O'));
      expect(notebookSketch(0), isNot(notebookSketch(1)),
          reason: 'uydular geceden geceye yer değiştirir');
    });

    test('"Uydu nereye gitti?" soruları hep açık bir yanda biter', () {
      for (final m in jupiterMoons) {
        for (final k in galileoMoonNights[m.id]!) {
          final t = MoonWhereTask(m, k);
          expect(moonSide(m, t.startNight), MoonSide.right,
              reason: '${m.id}: başlangıçta sağda');
          expect(m.skyX(t.startNight), closeTo(m.distance, 1e-6),
              reason: '${m.id}: en sağda');
          final x = m.skyX(t.startNight + k);
          expect(x.abs(), greaterThan(m.distance * 0.5),
              reason: '${m.id} +$k: sonuç belirsiz olmamalı');
        }
      }
    });

    test('Güneş sistemi: yakın gezegen daha hızlı; Venüs evreleri', () {
      for (var i = 1; i < planets.length; i++) {
        expect(planets[i].periodDays, greaterThan(planets[i - 1].periodDays));
      }
      final near = venusFromEarth(0, 20 * pi / 180);
      final far = venusFromEarth(0, 160 * pi / 180);
      expect(near.phase, VenusPhase.crescent);
      expect(far.phase, VenusPhase.full);
      expect(near.relativeSize, greaterThan(far.relativeSize * 3),
          reason: 'hilal Venüs çok daha büyük görünür');
      for (var d = 0.0; d < 600; d += 17) {
        final v = venusOnDay(d);
        expect(v.litFraction, inInclusiveRange(0.0, 1.0));
      }
    });

    test('3B modeller: gruplar ve iç düğümler GLB\'de', () {
      final names = _glbNodeNames('assets/models/galileo.glb');
      for (final id in [
        'galileo_figure', 'galileo_telescope', 'galileo_balcony', 'galileo_desk',
        'galileo_jupiter', 'TubeTilt', 'DrawTube',
      ]) {
        expect(names, contains(id),
            reason: '$id yok — tool/blender/build_galileo.py çalıştırılmalı');
      }
    });
  });

  group('Galileo görevleri', () {
    test('6 görev, her türden 2; doğru cevap modelden', () {
      for (var seed = 0; seed < 25; seed++) {
        final c = GalileoController(random: Random(seed))..startGame(['A']);
        final kinds = <GalileoTaskKind, int>{};
        final types = <Type>{};
        while (c.phase == ScientistPhase.playing) {
          final t = c.currentTask;
          kinds[t.kind] = (kinds[t.kind] ?? 0) + 1;
          types.add(t.runtimeType);
          expect(t.correctIndex, inInclusiveRange(0, t.options.length - 1),
              reason: 'seed $seed ${t.prompt}');
          expect(t.options.toSet().length, t.options.length);
          switch (t) {
            case MagnifyTask():
              final m = t.pairs.map((p) => magnification(p.$1, p.$2)).toList();
              expect(m[t.correctIndex], m.reduce(max));
            case FocusTask():
              expect(t.choices[t.correctIndex], sharpTubeCm(t.objectiveCm, t.eyepieceCm));
            case FastestMoonTask():
              expect(t.moons[t.correctIndex].periodDays,
                  t.moons.map((m) => m.periodDays).reduce(min));
            case MoonWhereTask():
              expect(t.correctIndex, isNot(2));
            case FastestPlanetTask():
              expect(t.options3[t.correctIndex].periodDays,
                  t.options3.map((p) => p.periodDays).reduce(min));
            case VenusPhaseTask():
              expect(t.questionScene.showVenusView, isFalse,
                  reason: 'cevap sorudan önce görünmemeli');
              expect(t.resultScene(0).showVenusView, isTrue);
          }
          c.answer(t.correctIndex);
          c.continueAfterResult();
        }
        expect(c.phase, ScientistPhase.finished);
        for (final k in GalileoTaskKind.values) {
          expect(kinds[k], 2, reason: 'seed $seed $k');
        }
        expect(types.length, 6, reason: 'seed $seed: altı farklı soru türü');
        expect(c.players.single.correctCount, galileoRoundsPerPlayer);
      }
    });

    test('Keşif: tüp, geceler, defter ve günler', () {
      final c = GalileoController()..startExplore();
      expect(c.scene.station, GalileoStation.telescope);
      c.setObjective(120);
      c.setEyepiece(10);
      c.setTube(500);
      expect(c.tubeCm, tubeMaxCm);
      c.setTube(110);
      expect(c.scene.focusError, 0);

      c.setStation(GalileoStation.jupiter);
      c.sketchTonight();
      c.sketchTonight(); // aynı gece iki kez çizilmez
      expect(c.notebook.length, 1);
      for (var i = 0; i < 12; i++) {
        c.nextNight();
        c.sketchTonight();
      }
      expect(c.notebook.length, galileoNotebookLimit);
      expect(c.scene.nights, 12);

      c.setStation(GalileoStation.solar);
      c.advanceDays(30);
      c.advanceDays(30);
      expect(c.scene.day, 60);
      expect(c.scene.showVenusView, isTrue);
    });
  });

  group('Galileo ekranları', () {
    testWidgets('görevler 2B görünümde sonuç ekranına kadar oynanır', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openGalileo(tester);
      expect(find.text('Galileo\'nun Gözlemevi'), findsOneWidget);
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();
      for (var i = 0; i < galileoRoundsPerPlayer; i++) {
        expect(find.textContaining('Görev ${i + 1} /'), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistOption_0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('scientistExplanation')), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistContinue')));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Tebrikler'), findsOneWidget);
    });

    testWidgets('Gözlemevi: odakla, deftere çiz, günleri ilerlet', (tester) async {
      tester.view.physicalSize = const Size(1000, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openGalileo(tester);
      await tester.tap(find.byKey(const Key('scientistExplore')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('galileoEyepiece')), findsOneWidget);
      expect(find.textContaining('Bulanık'), findsOneWidget);
      final c = Provider.of<GalileoController>(
        tester.element(find.byKey(const Key('scientistScene'))),
        listen: false,
      );
      c.setTube(85);
      await tester.pumpAndSettle();
      expect(find.textContaining('Görüntü net!'), findsOneWidget);
      expect(find.textContaining('Net!'), findsWidgets);

      await tester.tap(find.text('Jüpiter\'in Uyduları'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('galileoStrip')), findsOneWidget);
      await tester.tap(find.byKey(const Key('galileoSketch')));
      await tester.tap(find.byKey(const Key('galileoNextNight')));
      await tester.tap(find.byKey(const Key('galileoSketch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('galileoNote_0')), findsOneWidget);
      expect(find.byKey(const Key('galileoNote_1')), findsOneWidget);

      await tester.tap(find.text('Güneş Sistemi'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('galileoVenusView')), findsOneWidget);
      await tester.tap(find.byKey(const Key('galileoPlus30')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gün: 30'), findsOneWidget);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scientistStart')), findsOneWidget);
    });

    testWidgets('dar ekranda (320 px) taşma yok', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openGalileo(tester);
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
      final c = Provider.of<GalileoController>(
        tester.element(find.byKey(const Key('scientistScene'))),
        listen: false,
      );
      c.startExplore();
      await tester.pumpAndSettle();
      for (final s in GalileoStation.values) {
        c.setStation(s);
        await tester.pumpAndSettle();
      }
    });
  });
}
