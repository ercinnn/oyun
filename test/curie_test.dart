import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bombali_sayilar/controllers/curie_controller.dart';
import 'package:bombali_sayilar/data/curie_samples.dart';
import 'package:bombali_sayilar/games/curie_game.dart';
import 'package:bombali_sayilar/main.dart';
import 'package:bombali_sayilar/models/curie/curie_scene.dart';
import 'package:bombali_sayilar/models/curie/curie_task.dart';
import 'package:bombali_sayilar/models/curie/geiger.dart';
import 'package:bombali_sayilar/models/curie/shielding.dart';
import 'package:bombali_sayilar/models/curie/therapy.dart';
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

Future<void> _openCurie(WidgetTester tester) async {
  await tester.pumpWidget(const GamePlatformApp());
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamed(CurieGame.routeName);
  await tester.pumpAndSettle();
}

CurieController _controllerOf(WidgetTester tester) =>
    Provider.of<CurieController>(
      tester.element(find.byKey(const Key('scientistScene'))),
      listen: false,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Curie modeli', () {
    test('sayaç: ters kare kuralı, arka plan, cevher uranyumdan güçlü', () {
      final radium = curieSampleById('radium');
      final near = countsPerSecond(radium, 10) - backgroundCps;
      final far = countsPerSecond(radium, 20) - backgroundCps;
      expect(far / near, closeTo(0.25, 1e-9));
      expect(countsPerSecond(null, 10), backgroundCps);
      expect(countsPerSecond(curieSampleById('salt'), 10), backgroundCps);
      expect(curieSampleById('pitchblende').cpsAt10cm,
          greaterThan(curieSampleById('uranium').cpsAt10cm),
          reason: 'Curie\'yi yeni elementlere götüren ipucu');
      final ids = curieSamples.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(curieSamples.where((s) => s.radioactive).length, greaterThanOrEqualTo(3));
      expect(curieSamples.where((s) => !s.radioactive).length, 2);
    });

    test('kalkanlar: alfa kâğıtta, beta alüminyumda, gama kurşunda durur', () {
      expect(thinnestStopper(RayType.alpha), Shield.paper);
      expect(thinnestStopper(RayType.beta), Shield.aluminum);
      expect(thinnestStopper(RayType.gamma), Shield.lead);
      for (final r in RayType.values) {
        expect(transmission(r, Shield.none), 1);
        // Daha kalın kalkan daha az geçirir.
        expect(transmission(r, Shield.aluminum), lessThanOrEqualTo(transmission(r, Shield.paper)));
        expect(transmission(r, Shield.lead), lessThanOrEqualTo(transmission(r, Shield.aluminum)));
      }
    });

    test('tedavi: tümör hep tam doz alır; 3+ farklı yön güvenli, aynı yön değil', () {
      for (var n = 1; n <= curieMaxBeams; n++) {
        final spread = computeDose(spreadBeams(n));
        expect(spread.tumorDose, closeTo(targetDose, 1e-9), reason: 'n=$n');
        expect(spread.safe, n >= 3, reason: 'n=$n uzak doz ${spread.maxHealthyDose}');
        final stacked = computeDose(stackedBeams(n));
        expect(stacked.safe, isFalse, reason: 'aynı yönden $n ışın');
      }
    });

    test('3B modeller: gruplar ve iç düğümler GLB\'de', () {
      final names = _glbNodeNames('assets/models/curie.glb');
      for (final id in [
        for (final s in curieSamples) s.modelId,
        'curie_figure', 'curie_lab', 'curie_counter', 'curie_probe',
        'curie_source', 'curie_bed', 'curie_gantry',
        'Needle', 'sample_glow',
      ]) {
        expect(names, contains(id),
            reason: '$id yok — tool/blender/build_curie.py çalıştırılmalı');
      }
    });
  });

  group('Curie görevleri', () {
    test('6 görev, her türden 2; doğru cevap modelden', () {
      for (var seed = 0; seed < 30; seed++) {
        final c = CurieController(random: Random(seed))..startGame(['A']);
        final kinds = <CurieTaskKind, int>{};
        final types = <Type>{};
        while (c.phase == ScientistPhase.playing) {
          final t = c.currentTask;
          kinds[t.kind] = (kinds[t.kind] ?? 0) + 1;
          types.add(t.runtimeType);
          expect(t.correctIndex, inInclusiveRange(0, t.options.length - 1),
              reason: 'seed $seed ${t.prompt}');
          expect(t.options.toSet().length, t.options.length, reason: t.prompt);
          switch (t) {
            case FindSampleTask():
              expect(t.samples.where((s) => s.radioactive).length, 1);
              expect(t.samples[t.correctIndex].radioactive, isTrue);
            case DistanceTask():
              expect(t.options[t.correctIndex],
                  t.toCm == 20 ? DistanceTask.quarter : DistanceTask.ninth);
            case StopperTask():
              expect(t.options[t.correctIndex], thinnestStopper(t.ray).label);
            case IdentifyRayTask():
              expect(t.options[t.correctIndex], t.ray.label);
            case BeamPlanTask():
              final safeCount = t.plans.where((p) => computeDose(p).safe).length;
              expect(safeCount, 1, reason: 'tek bir güvenli plan olmalı');
            case DoseSumTask():
              expect(t.choices[t.correctIndex], t.count * t.strength);
          }
          c.answer(t.correctIndex);
          c.continueAfterResult();
        }
        expect(c.phase, ScientistPhase.finished);
        for (final k in CurieTaskKind.values) {
          expect(kinds[k], 2, reason: 'seed $seed $k');
        }
        expect(types.length, 6, reason: 'seed $seed');
        expect(c.players.single.correctCount, curieRoundsPerPlayer);
      }
    });

    test('Keşif: numune seç/bırak, kalkan, tedavi', () {
      final c = CurieController()..startExplore();
      expect(c.scene.geigerCps, backgroundCps);
      final radium = curieSampleById('radium');
      c.pickSample(radium);
      expect(c.scene.geigerCps, greaterThan(100));
      c.setDistance(500);
      expect(c.distanceCm, counterMaxCm);
      c.pickSample(radium); // aynı numuneye tekrar: sayaç kalkar
      expect(c.sample, isNull);

      c.setStation(CurieStation.shield);
      c.setRay(RayType.beta);
      c.setShield(Shield.aluminum);
      expect(c.scene.shieldCps, backgroundCps);

      c.setStation(CurieStation.therapy);
      expect(c.scene.dose.tumorDose, 0, reason: 'ışınlar kapalı');
      c.setBeamsOn(true);
      c.setBeamCount(4);
      expect(c.scene.dose.safe, isTrue);
      c.setSpread(false);
      expect(c.scene.dose.safe, isFalse);
    });
  });

  group('Curie ekranları', () {
    testWidgets('görevler 2B görünümde sonuç ekranına kadar oynanır', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openCurie(tester);
      expect(find.text('Curie\'nin Laboratuvarı'), findsOneWidget);
      await tester.tap(find.text('1 Kişi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scientistStart')));
      await tester.pumpAndSettle();
      for (var i = 0; i < curieRoundsPerPlayer; i++) {
        expect(find.textContaining('Görev ${i + 1} /'), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistOption_0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('scientistExplanation')), findsOneWidget);
        await tester.tap(find.byKey(const Key('scientistContinue')));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Tebrikler'), findsOneWidget);
    });

    testWidgets('Laboratuvar: sayaç, kalkan, tedavi', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openCurie(tester);
      await tester.tap(find.byKey(const Key('scientistExplore')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('curieGeigerMeter')), findsOneWidget);
      await tester.tap(find.byKey(const Key('curieSample_radium')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Işıma yapıyor!'), findsOneWidget);
      await tester.tap(find.byKey(const Key('curieSample_salt')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Arka plandan pek farkı yok'), findsOneWidget);

      await tester.tap(find.text('Kalkanlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('curieShield_paper')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kalkan ışını durdurdu!'), findsOneWidget);

      await tester.tap(find.text('Işınla Tedavi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('curieBeamsOn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sağlıklı doku çok ışın aldı'), findsOneWidget);
      _controllerOf(tester).setBeamCount(5);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sağlıklı doku korundu!'), findsOneWidget);
      expect(find.byKey(const Key('curieDoseMap')), findsOneWidget);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scientistStart')), findsOneWidget);
    });

    testWidgets('dar ekranda (320 px) taşma yok', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openCurie(tester);
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
      for (final s in CurieStation.values) {
        c.setStation(s);
        await tester.pumpAndSettle();
      }
    });
  });
}
