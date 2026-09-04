/// Bilgisayara karşı oynanan satrançta 1-5 arası zorluk seviyesi.
///
/// **Neden seviye = arama derinliği değil?** Motorun derinlik başına ölçülen
/// süresi (Dart VM, açılış/orta oyun): 1 ply ~15 ms, 2 ply ~30 ms, 3 ply
/// ~230 ms, 4 ply ~1.5 sn, 5 ply ~14 sn. Web'de (dart2js) bunun birkaç katı
/// olur ve arama tamamen senkron çalıştığı için o süre boyunca arayüz donar.
/// Bu yüzden seviye üç ayarı birlikte belirler:
///
/// - [searchDepth]: iteratif derinleşmenin ulaşmaya *çalışacağı* derinlik.
/// - [timeBudget]: aramanın üst sınırı. Bütçe dolduğunda o derinlik iptal
///   edilir ve tamamlanmış son derinliğin en iyi hamlesi oynanır — yani
///   yüksek seviyelerde bile arayüz sabit bir süreden fazla donmaz.
/// - [blunderChance]: yalnızca ilk iki seviyede > 0. Motoru "aptallaştırmanın"
///   en dürüst yolu: bazen rastgele bir geçerli hamle oynar, böylece yeni
///   başlayan biri gerçekten kazanabilir. Daha sığ arama tek başına yeterince
///   zayıf oynamıyordu (1 ply bile taş kazanmayı hep görür).
enum ChessDifficulty {
  cokKolay(level: 1, label: 'Çok Kolay', searchDepth: 1, blunderChance: 0.75),
  kolay(
    level: 2,
    label: 'Kolay',
    searchDepth: 2,
    timeBudgetMs: 300,
    blunderChance: 0.35,
  ),
  orta(level: 3, label: 'Orta', searchDepth: 3, timeBudgetMs: 700),
  zor(level: 4, label: 'Zor', searchDepth: 4, timeBudgetMs: 1500),
  cokZor(level: 5, label: 'Çok Zor', searchDepth: 5, timeBudgetMs: 3000);

  const ChessDifficulty({
    required this.level,
    required this.label,
    required this.searchDepth,
    this.timeBudgetMs = 0,
    this.blunderChance = 0.0,
  });

  /// Kullanıcıya gösterilen 1-5 arası seviye numarası.
  final int level;

  final String label;

  final int searchDepth;

  /// 0 = sınırsız (yalnızca en sığ seviyede, zaten milisaniyeler sürüyor).
  final int timeBudgetMs;

  /// 0.0-1.0 arası; motorun en iyi hamle yerine rastgele geçerli bir hamle
  /// oynama olasılığı.
  final double blunderChance;

  static ChessDifficulty fromLevel(int level) =>
      values.firstWhere((d) => d.level == level, orElse: () => orta);
}
