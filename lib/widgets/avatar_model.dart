import 'dart:math';

import 'package:flutter/material.dart' show Color;
import 'package:three_js/three_js.dart' as three;

import '../models/town/avatar_spec.dart';
import 'avatar_3d.dart' show AvatarRig;

/// Blender'da modellenmiş karakter (`assets/models/character.glb`,
/// üretici: `tool/blender/build_character.py`). Tüm mağaza varyantları modelin
/// içinde isimli gruplar olarak durur; [tryBuild] seçilen kombinasyonu bırakıp
/// gerisini sahneden **kaldırır** ve `Skin/Hair/Outfit…` malzemelerini kişinin
/// renkleriyle boyar. Model yüklenemezse null döner; çağıran kod ilkel şekillerle
/// kurulan `Avatar3D`'ye düşer.
///
/// Varyant düğümleri `hair_*`/`outfit_*`/`hat_*`/`acc_*` adlıdır; aynı varyantın
/// farklı pivota ait parçaları `outfit_space@head` gibi `@parça` taşır.
class AvatarModel implements AvatarRig {
  AvatarModel._(
    this.root, {
    required three.Object3D? legL,
    required three.Object3D? legR,
    required three.Object3D? armL,
    required three.Object3D? armR,
    required three.Object3D? body,
    required three.Object3D? head,
    required three.Object3D? wingL,
    required three.Object3D? wingR,
  }) : _legL = legL,
       _legR = legR,
       _armL = armL,
       _armR = armR,
       _body = body,
       _head = head,
       _wingL = wingL,
       _wingR = wingR;

  @override
  final three.Object3D root;
  final three.Object3D? _legL,
      _legR,
      _armL,
      _armR,
      _body,
      _head,
      _wingL,
      _wingR;

  static const _hairIds = {
    'hair_short',
    'hair_long',
    'hair_bun',
    'hair_spiky',
    'hair_curly',
  };
  static const _outfitIds = {
    'outfit_tee',
    'outfit_dress',
    'outfit_hoodie',
    'outfit_suit',
    'outfit_space',
  };
  static const _hatIds = {'hat_cap', 'hat_party', 'hat_cowboy', 'hat_crown'};
  static const _accIds = {
    'acc_glasses',
    'acc_necklace',
    'acc_headphones',
    'acc_wings',
  };

  /// Şapka takılıyken şapkadan taşan saç parçaları gizlenir.
  static const _bulkyHair = {'hair_bun', 'hair_spiky', 'hair_curly'};

  static three.Object3D? _template;
  static bool _loading = false;

  /// Modeli bir kez yükler (başarısızsa sessizce vazgeçer; oyun bozulmaz).
  static Future<void> preload() async {
    if (_template != null || _loading) return;
    _loading = true;
    try {
      final gltf = await three.GLTFLoader()
          .setPath('assets/models/')
          .fromAsset('character.glb');
      _template = gltf?.scene;
    } catch (_) {
      _template = null;
    } finally {
      _loading = false;
    }
  }

  static int _hex(Color c) => c.toARGB32() & 0xFFFFFF;

  static int _mix(int color, int other, double t) {
    int ch(int shift) {
      final a = (color >> shift) & 255, b = (other >> shift) & 255;
      return (a + (b - a) * t).round().clamp(0, 255);
    }

    return (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }

  /// Seçilen kombinasyon için karakter; model yüklenmediyse null.
  static AvatarModel? tryBuild(AvatarSpec spec) {
    final template = _template;
    if (template == null) return null;
    final root = template.clone(true);

    // Kalacak varyant kimlikleri.
    final keep = {spec.hairStyle, spec.outfit, spec.hat, spec.accessory};
    final hasHat = _hatIds.contains(spec.hat);

    final toRemove = <three.Object3D>[];
    root.traverse((o) {
      final base = o.name.split('.').first.split('@').first;
      final isVariant =
          _hairIds.contains(base) ||
          _outfitIds.contains(base) ||
          _hatIds.contains(base) ||
          _accIds.contains(base);
      if (!isVariant) return;
      final removeIt =
          !keep.contains(base) || (hasHat && _bulkyHair.contains(base));
      if (removeIt) toRemove.add(o);
    });
    for (final o in toRemove) {
      o.parent?.remove(o);
    }

    // Renkler.
    final skin = _hex(skinPalette[spec.skin % skinPalette.length]);
    final hair = _hex(hairPalette[spec.hairColor % hairPalette.length]);
    final outfit = _hex(outfitPalette[spec.outfitColor % outfitPalette.length]);
    final tints = <String, int>{
      'Skin': skin,
      'SkinDark': _mix(skin, 0x000000, 0.18),
      'Hair': hair,
      'Outfit': outfit,
      'OutfitLight': _mix(outfit, 0xFFFFFF, 0.25),
      'OutfitDark': _mix(outfit, 0x000000, 0.22),
    };
    final materials = <String, three.MeshStandardMaterial>{};
    root.traverse((o) {
      o.castShadow = true;
      if (o is! three.Mesh) return;
      final name = o.material?.name ?? '';
      final tint = tints[name];
      if (tint == null) return;
      o.material = materials.putIfAbsent(
        name,
        () => three.MeshStandardMaterial.fromMap({
          'color': tint,
          'roughness': 0.85,
        }),
      );
    });

    return AvatarModel._(
      root,
      legL: root.getObjectByName('LegL'),
      legR: root.getObjectByName('LegR'),
      armL: root.getObjectByName('ArmL'),
      armR: root.getObjectByName('ArmR'),
      body: root.getObjectByName('Body'),
      head: root.getObjectByName('Head'),
      wingL: root.getObjectByName('WingL'),
      wingR: root.getObjectByName('WingR'),
    );
  }

  @override
  void update(double time, bool moving, {double phase = 0}) {
    final swing = moving ? sin(time * 11 + phase) : 0.0;
    _legL?.rotation.x = swing * 0.75;
    _legR?.rotation.x = -swing * 0.75;
    final breathe = sin(time * 2 + phase) * 0.03;
    _armL?.rotation.x = -swing * 0.85;
    _armR?.rotation.x = swing * 0.85;
    _armL?.rotation.z = -0.09 - (moving ? 0 : 0.02 + breathe);
    _armR?.rotation.z = 0.09 + (moving ? 0 : 0.02 + breathe);
    _body?.rotation.x = moving ? 0.07 : 0;
    _body?.position.y = moving ? 0 : breathe * 0.4;
    _head?.rotation.z = moving ? swing * 0.04 : sin(time * 1.3 + phase) * 0.025;
    final flap =
        sin(time * (moving ? 13 : 3.5) + phase) * (moving ? 0.35 : 0.14);
    _wingL?.rotation.y = flap;
    _wingR?.rotation.y = -flap;
  }
}
