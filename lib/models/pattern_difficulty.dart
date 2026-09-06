/// Diziler'de hangi kural tipinin kullanıldığını belirleyen üç zorluk
/// seviyesi.
///
/// `MultiplicationDifficulty` (bkz. `models/multiplication_difficulty.dart`)
/// ile aynı ruhta, ama alanları daha yalın: oradaki seviyeler arasındaki fark
/// sadece bir sayı tavanıyken, buradaki fark **kullanılan kural tipinin
/// kendisi** — bu yüzden sayısal alanlar yerine `PatternController` her
/// seviye için ayrı bir üretim metoduna dallanıyor
/// (`_generateKolayTerms`/`_generateOrtaTerms`/`_generateZorTerms`).
enum PatternDifficulty {
  kolay(
    label: 'Kolay',
    hint: 'Çarpım tablosunu pekiştirir: 2-9 tablosundan artan diziler',
  ),
  orta(label: 'Orta', hint: 'Artan/azalan diziler ve katlanan örüntüler'),
  zor(label: 'Zor', hint: 'Büyük sayılar, katlanan ve bölünen örüntüler');

  const PatternDifficulty({required this.label, required this.hint});

  final String label;

  /// Kurulum ekranında seviyenin altında gösterilen açıklama — tooltip değil,
  /// her zaman görünen bir metin (bkz. `PatternSetupScreen`), çünkü "Kolay"ın
  /// çarpım tablosunu pekiştirdiği bilgisi dokunmatik cihazlarda kolayca
  /// keşfedilemeyecek bir tooltip'e gömülmemeli.
  final String hint;
}
