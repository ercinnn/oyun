import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bombali_sayilar/controllers/einstein_controller.dart';
import 'package:bombali_sayilar/games/einstein_game.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/einstein/einstein_scene.dart';
import 'package:bombali_sayilar/models/einstein/einstein_task.dart';
import 'package:bombali_sayilar/models/einstein/mass_energy.dart';
import 'package:bombali_sayilar/models/einstein/spacetime.dart';
import 'package:bombali_sayilar/models/einstein/time_dilation.dart';
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

Future<void> _openEinstein(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamed(EinsteinGame.routeName);
  await tester.pumpAndSettle();
}

EinsteinController _controllerOf(WidgetTester tester) =>
    Provider.of<EinsteinController>(
      tester.element(find.byKey(const Key('scientistScene'))),
      listen: false,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Einstein modeli', () {
    test('bilye: deterministik; Dünya\'da üç sonuç da görülür, ağır kütle yakalar', () {
      expect(simulateMarble(CentralMass.earth, LaunchSpeed.slow).fate, MarbleFate.fallsIn);
      expect(simulateMarble(CentralMass.earth, LaunchSpeed.medium).fate, MarbleFate.orbits);
      expect(simulateMarble(CentralMass.earth, LaunchSpeed.fast).fate, MarbleFate.escapes);
      expect(simulateMarble(CentralMass.sun, LaunchSpeed.medium).fate, MarbleFate.fallsIn);
      final a = simulateMarble(CentralMass.sun, LaunchSpeed.fast);
      final b = simulateMarble(CentralMass.sun, LaunchSpeed.fast);
      expect(a.path.length, b.path.length);
      expect(a.path.last, b.path.last);
      // Yörüngede bilye kaçış ve düşme sınırları arasında kalır.
      for (final (x, y) in simulateMarble(CentralMass.earth, LaunchSpeed.medium).path) {
        final r = sqrt(x * x + y * y);
        expect(r, inInclusiveRange(captureRadius, escapeRadius));
      }
      expect(sheetDepth(CentralMass.neutron, 1), greaterThan(sheetDepth(CentralMass.earth, 1)));
    });

    test('zaman: γ ve ikizler', () {
      expect(lorentzGamma(0), 1);
      expect(shipYears(10, 0.6), closeTo(8, 1e-9));
      expect(shipYears(10, 0.8), closeTo(6, 1e-9));
      for (var i = 1; i < shipSpeeds.length; i++) {
        expect(lorentzGamma(shipSpeeds[i]), greaterThan(lorentzGamma(shipSpeeds[i - 1])));
      }
    });

    test('E=mc²: 1 g ≈ 8 000 ev; odun yakmaktan kat kat fazla; doğrusal', () {
      expect(massEnergyJoules(1), closeTo(9e13, 1e6));
      expect(homesPowered(1), closeTo(8182, 1));
      expect(massEnergyJoules(2) / massEnergyJoules(1), closeTo(2, 1e-12));
      expect(homesPowered(1), greaterThan(homesFromBurning(1e6) * 1000));
      expect(cityHousesLit(1), 82);
      expect(cityHousesLit(100), cityHouseCount);
      expect(friendlyNumber(8181.8), '8 182');
      expect(friendlyNumber(0.82), '0,8');
      expect(friendlyNumber(2.5e6), '2,5 milyon');
      expect(formatGrams(0.01), '0,01');
      expect(formatGrams(0.0001), '0,0001');
      expect(formatGrams(1), '1');
      expect(burningPhrase(1), 'bir evin elektriğine bile yetmezdi');
    });

    test('3B modeller: gruplar ve iç düğümler GLB\'de', () {
      final names = _glbNodeNames('assets/models/einstein.glb');
      for (final id in [
        'einstein_figure', 'einstein_board', 'einstein_frame', 'einstein_clock',
        'einstein_ship', 'einstein_pedestal', 'einstein_house', 'einstein_campfire',
        'window', 'flame', 'eb_formula',
      ]) {
        expect(names, contains(id),
            reason: '$id yok — tool/blender/build_einstein.py çalıştırılmalı');
      }
    });
  });

  group('Einstein görevleri', () {
    test('6 görev, her türden 2; doğru cevap modelden', () {
      for (var seed = 0; seed < 30; seed++) {
        final c = EinsteinController(random: Random(seed))..startGame(['A']);
        final kinds = <EinsteinTaskKind, int>{};
        final types = <Type>{};
        while (c.phase == ScientistPhase.playing) {
          final t = c.currentTask;
          kinds[t.kind] = (kinds[t.kind] ?? 0) + 1;
          types.add(t.runtimeType);
          expect(t.correctIndex, inInclusiveRange(0, t.options.length - 1),
              reason: 'seed $seed ${t.prompt}');
          expect(t.options.toSet().length, t.options.length, reason: t.prompt);
          switch (t) {
            case FateTask():
              expect(t.options[t.correctIndex], simulateMarble(t.center, t.speed).fate.label);
            case OrbitWhichTask():
              final orbiting = CentralMass.values
                  .where((m) => simulateMarble(m, t.speed).fate == MarbleFate.orbits);
              expect(orbiting.length, 1, reason: 'tek bir doğru cevap');
            case ShipAgeTask():
              expect(t.choices[t.correctIndex], closeTo(shipYears(10, t.speed), 1e-9));
            case SlowestClockTask():
              expect(t.speeds[t.correctIndex], t.speeds.reduce(max));
            case MassVsWoodTask():
              expect(t.options[t.correctIndex], MassVsWoodTask.mass);
            case ScaleMassTask():
              expect(t.options[t.correctIndex], '${t.factor} katına');
          }
          c.answer(t.correctIndex);
          c.continueAfterResult();
        }
        expect(c.phase, ScientistPhase.finished);
        for (final k in EinsteinTaskKind.values) {
          expect(kinds[k], 2, reason: 'seed $seed $k');
        }
        expect(types.length, 6, reason: 'seed $seed');
        expect(c.players.single.correctCount, einsteinRoundsPerPlayer);
      }
    });

    test('Keşif: ayar değişince deney sıfırlanır', () {
      final c = EinsteinController()..startExplore();
      expect(c.scene.run, 0);
      c.launch();
      expect(c.scene.run, 1);
      c.setCenter(CentralMass.sun);
      expect(c.scene.run, 0);
      c.setStation(EinsteinStation.clock);
      c.startVoyage();
      expect(c.voyaged, isTrue);
      c.setShipSpeed(0.99);
      expect(c.voyaged, isFalse);
      c.setStation(EinsteinStation.energy);
      c.setGrams(1);
      c.convert();
      expect(c.scene.housesLit, 82);
    });
  });

  group('Einstein ekranları', () {
    testWidgets('görevler 2B görünümde sonuç ekranına kadar oynanır', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openEinstein(tester);
      expect(find.text('Einstein\'ın Laboratuvarı'), findsOneWidget);
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();
      for (var i = 0; i < einsteinRoundsPerPlayer; i++) {
        expect(find.textContaining('Görev ${i + 1} /'), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistOption_0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('scientistExplanation')), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistContinue')));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Tebrikler'), findsOneWidget);
    });

    testWidgets('Laboratuvar: bilye, yolculuk, enerji', (tester) async {
      tester.view.physicalSize = const Size(1000, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openEinstein(tester);
      await tester.tap(find.byKey(const Key('scientistExplore')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('einsteinLaunch')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bilye etrafında döner'), findsOneWidget);

      await tester.tap(find.text('Işık Saati'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('einsteinVoyage')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gemi: 6 yıl'), findsOneWidget);

      await tester.tap(find.text('E=mc²'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('einsteinMass_clip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('einsteinConvert')));
      await tester.pumpAndSettle();
      expect(find.textContaining('8 182 evin'), findsWidgets);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scientistStart')), findsOneWidget);
    });

    testWidgets('dar ekranda (320 px) taşma yok', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openEinstein(tester);
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
      for (final s in EinsteinStation.values) {
        c.setStation(s);
        await tester.pumpAndSettle();
      }
    });
  });
}
