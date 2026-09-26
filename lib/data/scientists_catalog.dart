import 'package:flutter/material.dart';

import '../games/archimedes_game.dart';
import '../games/curie_game.dart';
import '../games/einstein_game.dart';
import '../games/fleming_game.dart';
import '../games/galileo_game.dart';
import '../games/newton_game.dart';
import '../games/tesla_game.dart';

/// Posterdeki ("Tarihi Değiştiren Ünlü Bilim İnsanları ve Buluşları", 3/A)
/// bilim insanları. [routeName] null olan henüz yapılmadı; seçim ekranında
/// "Yakında" olarak görünür. Yeni bir bilim insanının oyunu eklenince burada
/// route'u verilir ve `main.dart`'ın `onGenerateRoute`'una eklenir.
class Scientist {
  const Scientist({
    required this.id,
    required this.name,
    required this.discovery,
    required this.summary,
    required this.emoji,
    required this.color,
    this.routeName,
  });

  final String id;
  final String name;

  /// Kartta başlığın altında: buluşun kısa adı.
  final String discovery;
  final String summary;
  final String emoji;
  final Color color;
  final String? routeName;

  bool get available => routeName != null;
}

const List<Scientist> scientists = [
  Scientist(
    id: 'arsimet',
    name: 'Arşimet',
    discovery: 'Kaldırma kuvveti ve Arşimet vidası',
    summary: 'Suyun kaldırma kuvvetini ve döner vidayı keşfetti; suyu '
        'zahmetsizce yükseğe taşıdı, gemilerin neden yüzdüğünü açıkladı.',
    emoji: '🛁',
    color: Color(0xFF00838F),
    routeName: ArchimedesGame.routeName,
  ),
  Scientist(
    id: 'galileo',
    name: 'Galileo Galilei',
    discovery: 'Teleskop ve gökyüzü gözlemleri',
    summary: 'Güçlü bir teleskop yaptı; Dünya\'nın ve gezegenlerin Güneş '
        'etrafında döndüğünü gösterdi, Jüpiter\'in uydularını ilk o gördü.',
    emoji: '🔭',
    color: Color(0xFF283593),
    routeName: GalileoGame.routeName,
  ),
  Scientist(
    id: 'newton',
    name: 'Isaac Newton',
    discovery: 'Kütleçekim ve ışığın renkleri',
    summary: 'Düşen elmadan kütleçekimi keşfetti; beyaz ışığı prizmadan '
        'geçirip gökkuşağı renklerine ayırdı, hareketin kurallarını yazdı.',
    emoji: '🍎',
    color: Color(0xFF2E7D32),
    routeName: NewtonGame.routeName,
  ),
  Scientist(
    id: 'tesla',
    name: 'Nikola Tesla',
    discovery: 'Alternatif akım (AC)',
    summary: 'Evlerimizde kullandığımız alternatif akım sistemini geliştirdi; '
        'kablosuz enerji ve radyonun temellerini attı.',
    emoji: '⚡',
    color: Color(0xFFEF6C00),
    routeName: TeslaGame.routeName,
  ),
  Scientist(
    id: 'curie',
    name: 'Marie Curie',
    discovery: 'Radyoaktivite',
    summary: 'Radyum ve polonyumu keşfederek radyoaktiviteyi buldu; iki '
        'farklı alanda Nobel Ödülü kazanan ilk bilim insanı oldu.',
    emoji: '⚗️',
    color: Color(0xFF6A1B9A),
    routeName: CurieGame.routeName,
  ),
  Scientist(
    id: 'einstein',
    name: 'Albert Einstein',
    discovery: 'Görelilik ve E=mc²',
    summary: 'Zamanın ve uzayın bükülebileceğini söyleyen Görelilik '
        'Teorisi\'ni geliştirdi; E=mc² ile modern fiziğin kapısını açtı.',
    emoji: '🌌',
    color: Color(0xFF37474F),
    routeName: EinsteinGame.routeName,
  ),
  Scientist(
    id: 'fleming',
    name: 'Alexander Fleming',
    discovery: 'Penisilin',
    summary: 'Hastalık yapan bakterileri öldüren ilk antibiyotik penisilini '
        'keşfetti; milyonlarca insanın hayatını kurtardı.',
    emoji: '🧫',
    color: Color(0xFFC62828),
    routeName: FlemingGame.routeName,
  ),
];
