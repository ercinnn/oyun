import 'package:flutter/material.dart';

/// Bir oyunun beş beceri alanını (Zeka, İngilizce, IQ, Hafıza, Dikkat) ne
/// kadar geliştirdiğini 0-5 arası puanlar; ana menüdeki
/// `widgets/skill_ratings_table.dart`'ın `SkillRatingsTable`'ı bu puanları
/// yıldız satırları olarak çizer. 5 = çok geliştirir, 0 = hiç geliştirmez.
///
/// **Dikkat, Zeka'dan ayrı bir eksen**: Zeka strateji/planlama/genel zihinsel
/// çaba ölçer, Dikkat ise sürekli odaklanma ve dürtü kontrolü — Renk mi
/// Kelime mi?, Simon Diyor ki ve Tepki Süresi'nin 5 alması bu yüzden (üçü de
/// birebir dikkat/tepki-engelleme testi), Satranç'ın 5 yerine 4 alması da
/// bu yüzden (uzun soluklu yoğunlaşma ister ama Stroop tarzı anlık dürtü
/// engellemesi değil).
class GameSkillRatings {
  const GameSkillRatings({
    required this.zeka,
    required this.ingilizce,
    required this.iq,
    required this.hafiza,
    required this.dikkat,
  });

  final int zeka;
  final int ingilizce;
  final int iq;
  final int hafiza;
  final int dikkat;

  /// Oyunun en yüksek puanlı becerisini ana menü kartındaki küçük etikete
  /// ("HAFIZA ODAKLI" gibi) uygun biçimde döndürür. Etiket bilerek yıldız
  /// tablosundaki beş isimden birini kullanır (yorum katmaz), böylece hemen
  /// altındaki tabloyla hiçbir zaman çelişemez. Eşitlikte Hafıza → IQ →
  /// Dikkat → Zeka → İngilizce sırası kazanır; İngilizce yalnızca Kart
  /// Eşleştirme'de 0'dan büyük olduğu için pratikte en sonda kalır.
  String get dominantSkillLabel {
    final best = [
      hafiza,
      iq,
      dikkat,
      zeka,
      ingilizce,
    ].reduce((a, b) => a > b ? a : b);
    if (hafiza == best) return 'HAFIZA ODAKLI';
    if (iq == best) return 'IQ ODAKLI';
    if (dikkat == best) return 'DİKKAT ODAKLI';
    if (zeka == best) return 'ZEKA ODAKLI';
    return 'İNGİLİZCE ODAKLI';
  }
}

/// Platform ana menüsünde gösterilen tek bir oyunu tanımlar: kart üzerindeki
/// görsel bilgiler ve o oyuna gidecek route adı. Yeni bir oyun eklemek,
/// [gameCatalog] listesine yeni bir [GameCatalogEntry] eklemek ve
/// `main.dart`'taki `onGenerateRoute`'a ilgili route'u tanımlamak demektir.
class GameCatalogEntry {
  const GameCatalogEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.routeName,
    required this.skills,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String routeName;
  final GameSkillRatings skills;
}
