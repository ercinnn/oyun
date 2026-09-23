import 'package:flutter/material.dart';

import '../models/town/shop_catalog.dart';

/// Mobilyanın market/envanter önizlemesi: odada kullanılan **aynı Blender
/// modelinin** izometrik render'ı (`assets/thumbs/<id>.png`, üretici
/// `tool/blender/build_furniture.py`'nin `render_thumbs`'u).
///
/// Neden hazır resim: liste içinde her satır için ayrı bir 3B sahne açmak
/// (9 WebGL bağlamı) hem pahalı hem gereksiz; önizlemenin odadaki modelle aynı
/// görünmesi yeterli. Resim yoksa eşyanın emojisine düşer, yani asset
/// gelmeden de arayüz çalışır.
class FurnitureThumb extends StatelessWidget {
  const FurnitureThumb({super.key, required this.item, this.size = 44});

  final ShopItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/thumbs/${item.id}.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Center(
          child: Text(item.emoji, style: TextStyle(fontSize: size * 0.62)),
        ),
      ),
    );
  }
}
