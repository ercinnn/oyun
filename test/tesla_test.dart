import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bombali_sayilar/controllers/tesla_controller.dart';
import 'package:bombali_sayilar/games/tesla_game.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/science/scientist_phase.dart';
import 'package:bombali_sayilar/models/tesla/generator.dart';
import 'package:bombali_sayilar/models/tesla/tesla_scene.dart';
import 'package:bombali_sayilar/models/tesla/tesla_task.dart';
import 'package:bombali_sayilar/models/tesla/transmission.dart';
import 'package:bombali_sayilar/models/tesla/wireless.dart';

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

Future<void> _openTesla(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamed(TeslaGame.routeName);
  await tester.pumpAndSettle();
}

TeslaController _controllerOf(WidgetTester tester) =>
    Provider.of<TeslaController>(
      tester.element(find.byKey(const Key('scientistScene'))),
      listen: false,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Tesla modeli', () {
    test('jeneratör: AC artı-eksi gider, pil sabit; hız parlaklığı artırır', () {
      final f = 2.0;
      final samples = [
        for (var i = 0; i < 100; i++) voltsAt(PowerSource.generator, f, i / 100),
      ];
      expect(samples.reduce(max), closeTo(peakVolts(f), 0.1));
      expect(samples.reduce(min), closeTo(-peakVolts(f), 0.1));
      for (var i = 0; i < 10; i++) {
        expect(voltsAt(PowerSource.battery, f, i / 10), batteryVolts);
      }
      expect(bulbBrightness(PowerSource.generator, 2),
          greaterThan(bulbBrightness(PowerSource.generator, 1)));
      expect(bulbBrightness(PowerSource.generator, 0), 0);
      expect(ledPattern(PowerSource.battery, 1), LedPattern.steady);
      expect(ledPattern(PowerSource.generator, 1), LedPattern.alternating);
      expect(ledPattern(PowerSource.generator, 0), LedPattern.none);
    });

    test('hat: yüksek gerilim daha az kayıp; uzak şehir alçak gerilimde karanlık', () {
      for (final d in cityDistancesKm) {
        var previous = -1.0;
        for (final t in secondaryTurnsOptions) {
          final w = deliveredWatts(lineVolts(t), d);
          expect(w, greaterThan(previous), reason: '$d km $t sarım');
          previous = w;
        }
      }
      expect(housesLit(lineVolts(10), 50), 0);
      expect(housesLit(lineVolts(1000), 50), cityHouses);
      expect(transformerOut(200, 10, 100), 2000);
      expect(transformerOut(2000, 100, 10), 200);
    });

    test('gerilim görevlerinin uzaklıklarında tek bir en iyi seçenek var', () {
      for (final d in teslaVoltageTaskDistancesKm) {
        final houses = [for (final t in secondaryTurnsOptions) housesLit(lineVolts(t), d)];
        final best = houses.reduce(max);
        expect(houses.where((h) => h == best).length, 1, reason: '$d km: $houses');
      }
    });

    test('kablosuz: aynı frekansta en parlak, uzaklaştıkça söner, kapalıyken 0', () {
      expect(resonance(200, 200), 1);
      expect(resonance(200, 100), lessThan(0.1));
      expect(fieldStrength(3), lessThan(fieldStrength(1)));
      expect(
        lampBrightness(coilOn: false, transmitterKHz: 200, receiverKHz: 200, distanceM: 1),
        0,
      );
      final near = lampBrightness(coilOn: true, transmitterKHz: 200, receiverKHz: 200, distanceM: 1);
      expect(lampLit(near), isTrue);
      final detuned = lampBrightness(coilOn: true, transmitterKHz: 200, receiverKHz: 120, distanceM: 1);
      expect(lampLit(detuned), isFalse, reason: 'keşif ayarsız başlar');
    });

    test('3B modeller: gruplar ve boyanan iç parçalar GLB\'de', () {
      final names = _glbNodeNames('assets/models/tesla.glb');
      for (final id in [
        'tesla_figure', 'tesla_lab', 'tesla_generator', 'tesla_bulb', 'tesla_leds',
        'tesla_battery', 'tesla_scope', 'tesla_plant', 'tesla_transformer',
        'tesla_pylon', 'tesla_house', 'tesla_coil', 'tesla_lamp',
        'Rotor', 'bulb_glass', 'led_red', 'led_green', 'window0', 'window1', 'lamp_tube',
      ]) {
        expect(names, contains(id),
            reason: '$id yok — tool/blender/build_tesla.py çalıştırılmalı');
      }
    });
  });

  group('Tesla görevleri', () {
    test('6 görev, her türden 2; doğru cevap modelden', () {
      for (var seed = 0; seed < 30; seed++) {
        final c = TeslaController(random: Random(seed))..startGame(['A']);
        final kinds = <TeslaTaskKind, int>{};
        final types = <Type>{};
        while (c.phase == ScientistPhase.playing) {
          final t = c.currentTask;
          kinds[t.kind] = (kinds[t.kind] ?? 0) + 1;
          types.add(t.runtimeType);
          expect(t.correctIndex, inInclusiveRange(0, t.options.length - 1),
              reason: 'seed $seed ${t.prompt}');
          expect(t.options.toSet().length, t.options.length, reason: t.prompt);
          switch (t) {
            case SpeedTask():
              expect(t.options[t.correctIndex], SpeedTask.brighter);
            case LedTask():
              expect(t.options[t.correctIndex], ledPattern(t.source, 1).label);
            case VoltageTask():
              expect(t.turnChoices[t.correctIndex], secondaryTurnsOptions.last);
            case TransformerTask():
              expect(t.choices[t.correctIndex], transformerOut(t.inputVolts, t.primary, t.secondary));
            case LampDistanceTask():
              expect(t.options[t.correctIndex],
                  t.toM > t.fromM ? LampDistanceTask.dimmer : LampDistanceTask.brighter);
            case TuningTask():
              expect(t.choices[t.correctIndex], t.transmitterKHz);
          }
          c.answer(t.correctIndex);
          c.continueAfterResult();
        }
        expect(c.phase, ScientistPhase.finished);
        for (final k in TeslaTaskKind.values) {
          expect(kinds[k], 2, reason: 'seed $seed $k');
        }
        expect(types.length, 6, reason: 'seed $seed');
        expect(c.players.single.correctCount, teslaRoundsPerPlayer);
      }
    });

    test('Keşif: kaynak, hız, hat ve bobin ayarları sahneye geçer', () {
      final c = TeslaController()..startExplore();
      expect(c.scene.station, TeslaStation.generator);
      c.setSpeed(9);
      expect(c.turnsPerSecond, maxTurnsPerSecond);
      c.setSource(PowerSource.battery);
      expect(c.scene.source, PowerSource.battery);

      c.setStation(TeslaStation.transmission);
      c.setDistance(50);
      c.setSecondaryTurns(1000);
      expect(c.scene.houses, cityHouses);

      c.setStation(TeslaStation.wireless);
      expect(c.scene.lampLevel, 0);
      c.setCoil(true);
      c.setReceiver(200);
      c.setLampDistance(0.5);
      expect(lampLit(c.scene.lampLevel), isTrue);
      c.setLampDistance(10);
      expect(c.lampDistanceM, lampMaxM);
    });
  });

  group('Tesla ekranları', () {
    testWidgets('görevler 2B görünümde sonuç ekranına kadar oynanır', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openTesla(tester);
      expect(find.text('Tesla\'nın Laboratuvarı'), findsOneWidget);
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();
      for (var i = 0; i < teslaRoundsPerPlayer; i++) {
        expect(find.textContaining('Görev ${i + 1} /'), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistOption_0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('scientistExplanation')), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistContinue')));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Tebrikler'), findsOneWidget);
    });

    testWidgets('Laboratuvar: pil/jeneratör, şehir, kablosuz lamba', (tester) async {
      tester.view.physicalSize = const Size(1000, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openTesla(tester);
      await tester.tap(find.byKey(const Key('scientistExplore')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('teslaScope')), findsOneWidget);
      expect(find.textContaining('sırayla yanıp sönüyor'), findsOneWidget);
      await tester.tap(find.byKey(const Key('teslaSource_battery')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Doğru akım'), findsOneWidget);

      await tester.tap(find.text('Şehre Elektrik'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('teslaCity')), findsOneWidget);
      await tester.tap(find.byKey(const Key('teslaDistance_50')));
      await tester.pumpAndSettle();
      expect(find.textContaining('0/10 ev yandı'), findsOneWidget);
      await tester.tap(find.byKey(const Key('teslaTurns_1000')));
      await tester.pumpAndSettle();
      expect(find.textContaining('10/10 ev yandı'), findsOneWidget);

      await tester.tap(find.text('Tesla Bobini'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('teslaCoilSwitch')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lamba sönük'), findsWidgets);
      _controllerOf(tester).setReceiver(200);
      await tester.pumpAndSettle();
      expect(find.textContaining('Lamba yanıyor'), findsWidgets);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scientistStart')), findsOneWidget);
    });

    testWidgets('dar ekranda (320 px) taşma yok', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openTesla(tester);
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
      for (final s in TeslaStation.values) {
        c.setStation(s);
        await tester.pumpAndSettle();
      }
    });
  });
}
