import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bombali_sayilar/controllers/newton_controller.dart';
import 'package:bombali_sayilar/data/newton_objects.dart';
import 'package:bombali_sayilar/games/newton_game.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/newton/cart.dart';
import 'package:bombali_sayilar/models/newton/falling.dart';
import 'package:bombali_sayilar/models/newton/newton_scene.dart';
import 'package:bombali_sayilar/models/newton/newton_task.dart';
import 'package:bombali_sayilar/models/newton/prism.dart';
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

Future<void> _openNewton(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamed(NewtonGame.routeName);
  await tester.pumpAndSettle();
}

NewtonController _controllerOf(WidgetTester tester) =>
    Provider.of<NewtonController>(
      tester.element(find.byKey(const Key('scientistScene'))),
      listen: false,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Newton modeli', () {
    test('havasız ortamda her cisim aynı sürede düşer', () {
      final t0 = fallTime(newtonFallingObjects.first, FallEnvironment.vacuum);
      expect(t0, closeTo(sqrt(2 * towerHeightM / 9.8), 1e-9));
      for (final o in newtonFallingObjects) {
        expect(fallTime(o, FallEnvironment.vacuum), t0, reason: o.id);
        expect(fallTime(o, FallEnvironment.moon), greaterThan(t0 * 2),
            reason: 'Ay\'da çekim zayıf, düşüş yavaş');
      }
    });

    test('havada: limit hızı küçük olan geç düşer, yol süreyle artar', () {
      for (final o in newtonFallingObjects) {
        final t = fallTime(o, FallEnvironment.air);
        expect(t, greaterThanOrEqualTo(fallTime(o, FallEnvironment.vacuum) - 1e-9),
            reason: o.id);
        expect(fallDistance(o, t, FallEnvironment.air), closeTo(towerHeightM, 1e-6),
            reason: '${o.id}: süre ile yol tutarlı');
        var previous = 0.0;
        for (var k = 1; k <= 20; k++) {
          final d = fallDistance(o, t * k / 20, FallEnvironment.air);
          expect(d, greaterThanOrEqualTo(previous));
          previous = d;
        }
      }
      final flat = fallingObjectById('paper_flat');
      final ball = fallingObjectById('paper_ball');
      expect(flat.massG, ball.massG, reason: 'aynı kâğıt');
      expect(fallWinner(flat, ball, FallEnvironment.air), 1);
      expect(fallWinner(flat, ball, FallEnvironment.vacuum), 2);
    });

    test('görev çiftleri: farklı çiftler havada ayrışır, aynı çiftler aynı anda düşer', () {
      for (final (a, b) in newtonDifferentPairs) {
        final ta = fallTime(fallingObjectById(a), FallEnvironment.air);
        final tb = fallTime(fallingObjectById(b), FallEnvironment.air);
        expect((ta - tb).abs(), greaterThan(0.5), reason: '$a-$b');
      }
      for (final (a, b, env) in newtonSameTimePairs) {
        expect(fallWinner(fallingObjectById(a), fallingObjectById(b), env), 2,
            reason: '$a-$b ${env.name}');
      }
    });

    test('prizma: kırmızıdan mora sapma artar; süzgeç ve ters prizma', () {
      for (var i = 1; i < spectrumColors.length; i++) {
        expect(deviationDeg(spectrumColors[i]),
            greaterThan(deviationDeg(spectrumColors[i - 1])));
      }
      expect(prismOutcome(LightSource.white, secondPrism: false).isRainbow, isTrue);
      expect(prismOutcome(LightSource.white, secondPrism: true).isWhite, isTrue);
      final red = prismOutcome(LightSource.red, secondPrism: false);
      expect(red.isRainbow, isFalse);
      expect(red.colors.single.id, 'red');
      // Tek renk ters prizmadan geçince beyaza dönmez.
      expect(prismOutcome(LightSource.blue, secondPrism: true).recombinedHex,
          spectrumColorById('blue').hex);
      expect(prismOutcome(LightSource.white, secondPrism: true).recombinedHex,
          0xFFFFFF);
    });

    test('araba: yük arttıkça, sürtünme arttıkça daha az gider', () {
      for (final push in PushStrength.values) {
        for (final surface in CartSurface.values) {
          var previous = double.infinity;
          for (var b = 0; b <= maxBoxes; b++) {
            final lane = CartLane(boxes: b, surface: surface);
            final d = cartStopDistance(lane, push);
            expect(d, lessThan(previous));
            previous = d;
            // Konum, yolculuğun sonunda gidilen yola eşit.
            expect(cartPositionAt(lane, push, cartTravelTime(lane, push)),
                closeTo(cartDistance(lane, push), 1e-6));
          }
        }
        expect(cartStopDistance(const CartLane(surface: CartSurface.ice), push),
            greaterThan(cartStopDistance(const CartLane(), push)));
        expect(cartStopDistance(const CartLane(), push),
            greaterThan(cartStopDistance(const CartLane(surface: CartSurface.carpet), push)));
      }
      const iceStrong = CartLane(surface: CartSurface.ice);
      expect(cartDistance(iceStrong, PushStrength.strong), trackLengthM,
          reason: 'buzda güçlü itilen araba tampona kadar gider');
    });

    test('3B modeller: her cismin ve düzeneğin GLB grubu var', () {
      final names = _glbNodeNames('assets/models/newton.glb');
      for (final id in [
        for (final o in newtonFallingObjects) o.modelId,
        'newton_tower', 'newton_tree', 'newton_figure', 'newton_room',
        'newton_table', 'newton_lamp', 'newton_prism', 'newton_screen',
        'newton_cart', 'newton_box', 'newton_launcher',
        // 3B görünümün adla aradığı iç düğümler.
        'Wheel0', 'Wheel1', 'Wheel2', 'Wheel3', 'Plunger', 'prism_glass',
      ]) {
        expect(names, contains(id),
            reason: '$id yok — tool/blender/build_newton.py çalıştırılıp '
                'yeniden dışa aktarılmalı');
      }
    });
  });

  group('Newton görevleri', () {
    test('6 görev, her türden 2; bir farklı bir aynı-anda düşme turu', () {
      for (var seed = 0; seed < 25; seed++) {
        final c = NewtonController(random: Random(seed))..startGame(['A']);
        final kinds = <NewtonTaskKind, int>{};
        final fallAnswers = <int>[];
        final prismQuestions = <PrismQuestion>{};
        final cartQuestions = <CartQuestion>{};
        while (c.phase == ScientistPhase.playing) {
          final t = c.currentTask;
          kinds[t.kind] = (kinds[t.kind] ?? 0) + 1;
          expect(t.correctIndex, inInclusiveRange(0, t.options.length - 1),
              reason: 'seed $seed ${t.prompt}');
          expect(t.options.toSet().length, t.options.length);
          switch (t) {
            case FallTask():
              fallAnswers.add(t.correctIndex);
              expect(t.correctIndex, fallWinner(t.a, t.b, t.environment));
            case PrismTask():
              prismQuestions.add(t.question);
              if (t.question == PrismQuestion.mostBent) {
                final best = t.colorChoices.reduce(
                  (a, b) => deviationDeg(a) >= deviationDeg(b) ? a : b,
                );
                expect(t.options[t.correctIndex], best.name);
              } else {
                expect(t.options[t.correctIndex], switch (t.question) {
                  PrismQuestion.whiteSplits => PrismTask.rainbow,
                  PrismQuestion.onlyRed => PrismTask.onlyRedText,
                  _ => PrismTask.recombinedWhite,
                });
              }
            case CartTask():
              cartQuestions.add(t.question);
              expect(t.correctIndex, isNot(2), reason: 'araba farkı belirgin olmalı');
              final da = cartDistance(t.laneA, t.push);
              final db = cartDistance(t.laneB, t.push);
              expect(t.correctIndex, da > db ? 0 : 1);
          }
          c.answer(t.correctIndex);
          c.continueAfterResult();
        }
        expect(c.phase, ScientistPhase.finished);
        for (final k in NewtonTaskKind.values) {
          expect(kinds[k], 2, reason: 'seed $seed $k');
        }
        expect(fallAnswers.where((i) => i == 2).length, 1, reason: 'seed $seed');
        expect(prismQuestions.length, 2, reason: 'iki farklı prizma sorusu');
        expect(cartQuestions, CartQuestion.values.toSet());
        expect(c.players.single.correctCount, newtonRoundsPerPlayer);
      }
    });

    test('sonuç sahnesi deneyi başlatır', () {
      final c = NewtonController(random: Random(2))..startGame(['A']);
      expect(c.scene.run, 0);
      c.answer(0);
      expect(c.scene.run, greaterThan(0));
      expect(c.scene.duration, greaterThan(0));
    });

    test('Keşif: ayar değişince deney sıfırlanır', () {
      final c = NewtonController()..startExplore();
      expect(c.scene.station, NewtonStation.fall);
      expect(c.scene.run, 0);
      c.dropObjects();
      expect(c.scene.run, 1);
      expect(c.fallDone, isTrue);
      c.setEnvironment(FallEnvironment.moon);
      expect(c.scene.run, 0);
      c.dropObjects();
      c.dropObjects();
      expect(c.scene.run, 2);

      c.setStation(NewtonStation.prism);
      expect(c.scene.run, 0);
      c.setLamp(true);
      expect(c.scene.run, 1);
      c.setLight(LightSource.red);
      expect(c.scene.prism.colors.single.id, 'red');

      c.setStation(NewtonStation.cart);
      c.pushCarts();
      expect(c.cartDone, isTrue);
      c.setLaneA(c.laneA.copyWith(boxes: 3));
      expect(c.cartDone, isFalse);
      expect(c.scene.laneA.boxes, 3);
    });
  });

  group('Newton ekranları', () {
    testWidgets('görevler 2B görünümde sonuç ekranına kadar oynanır', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openNewton(tester);
      expect(find.text('Newton\'un Laboratuvarı'), findsOneWidget);
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();
      for (var i = 0; i < newtonRoundsPerPlayer; i++) {
        expect(find.textContaining('Görev ${i + 1} /'), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistOption_0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('scientistExplanation')), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistContinue')));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Tebrikler'), findsOneWidget);
    });

    testWidgets('Keşif Laboratuvarı: bırak, feneri yak, arabaları it', (tester) async {
      tester.view.physicalSize = const Size(1000, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openNewton(tester);
      await tester.tap(find.byKey(const Key('scientistExplore')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('newtonB_hammer')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('newtonEnv_moon')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('newtonDrop')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('newtonFallResult')), findsOneWidget);
      expect(find.textContaining('aynı anda yere değdi'), findsOneWidget);

      await tester.tap(find.text('Prizma'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('newtonLamp')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Perdede 7 renk var'), findsOneWidget);
      await tester.tap(find.byKey(const Key('newtonSecondPrism')));
      await tester.pumpAndSettle();
      expect(find.textContaining('beyaz ışık'), findsWidgets);

      await tester.tap(find.text('İtme Pisti'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('newtonPush')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('newtonCartResult')), findsOneWidget);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scientistStart')), findsOneWidget);
    });

    testWidgets('dar ekranda (320 px) taşma yok', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openNewton(tester);
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
      final controller = _controllerOf(tester);
      controller.startExplore();
      await tester.pumpAndSettle();
      for (final s in NewtonStation.values) {
        controller.setStation(s);
        await tester.pumpAndSettle();
      }
    });
  });
}
