/// Mağaza kategorileri.
enum ShopCategory {
  hair('Saç'),
  outfit('Kıyafet'),
  hat('Şapka'),
  accessory('Aksesuar'),
  furniture('Mobilya');

  const ShopCategory(this.label);
  final String label;
}

/// Satın alınan/kuşanılan bir eşya. Fiyat 0 ise başlangıçta herkesin
/// elindedir. Mobilyada [width]×[depth] oda karosu kaplar (dönünce yer
/// değiştirir).
class ShopItem {
  const ShopItem({
    required this.id,
    required this.category,
    required this.name,
    required this.emoji,
    required this.price,
    this.width = 1,
    this.depth = 1,
    this.height = 0.6,
    this.colorValue = 0xFF90A4AE,
  });

  final String id;
  final ShopCategory category;
  final String name;
  final String emoji;
  final int price;

  /// Yalnızca mobilya için: karo genişliği/derinliği ve çizim yüksekliği
  /// (karo cinsinden) ve ana rengi.
  final int width;
  final int depth;
  final double height;
  final int colorValue;
}

/// Bütün eşyalar. Kimlikler avatar ([AvatarSpec]) ve oda düzeninde saklanır.
const List<ShopItem> shopCatalog = [
  // Saç
  ShopItem(id: 'hair_short', category: ShopCategory.hair, name: 'Kısa saç', emoji: '💇', price: 0),
  ShopItem(id: 'hair_long', category: ShopCategory.hair, name: 'Uzun saç', emoji: '👩', price: 0),
  ShopItem(id: 'hair_bun', category: ShopCategory.hair, name: 'Topuz', emoji: '🎀', price: 30),
  ShopItem(id: 'hair_spiky', category: ShopCategory.hair, name: 'Dikenli saç', emoji: '⚡', price: 30),
  ShopItem(id: 'hair_curly', category: ShopCategory.hair, name: 'Kıvırcık saç', emoji: '🌀', price: 40),
  // Kıyafet
  ShopItem(id: 'outfit_tee', category: ShopCategory.outfit, name: 'Tişört', emoji: '👕', price: 0),
  ShopItem(id: 'outfit_dress', category: ShopCategory.outfit, name: 'Elbise', emoji: '👗', price: 0),
  ShopItem(id: 'outfit_hoodie', category: ShopCategory.outfit, name: 'Kapüşonlu', emoji: '🧥', price: 50),
  ShopItem(id: 'outfit_suit', category: ShopCategory.outfit, name: 'Takım elbise', emoji: '🤵', price: 60),
  ShopItem(id: 'outfit_space', category: ShopCategory.outfit, name: 'Astronot', emoji: '🧑‍🚀', price: 120),
  // Şapka
  ShopItem(id: 'hat_none', category: ShopCategory.hat, name: 'Şapkasız', emoji: '🚫', price: 0),
  ShopItem(id: 'hat_cap', category: ShopCategory.hat, name: 'Kep', emoji: '🧢', price: 20),
  ShopItem(id: 'hat_party', category: ShopCategory.hat, name: 'Parti şapkası', emoji: '🥳', price: 40),
  ShopItem(id: 'hat_cowboy', category: ShopCategory.hat, name: 'Kovboy şapkası', emoji: '🤠', price: 60),
  ShopItem(id: 'hat_crown', category: ShopCategory.hat, name: 'Taç', emoji: '👑', price: 100),
  // Aksesuar
  ShopItem(id: 'acc_none', category: ShopCategory.accessory, name: 'Aksesuarsız', emoji: '🚫', price: 0),
  ShopItem(id: 'acc_glasses', category: ShopCategory.accessory, name: 'Gözlük', emoji: '👓', price: 25),
  ShopItem(id: 'acc_necklace', category: ShopCategory.accessory, name: 'Kolye', emoji: '📿', price: 30),
  ShopItem(id: 'acc_headphones', category: ShopCategory.accessory, name: 'Kulaklık', emoji: '🎧', price: 45),
  ShopItem(id: 'acc_wings', category: ShopCategory.accessory, name: 'Kanatlar', emoji: '🪽', price: 150),
  // Mobilya
  ShopItem(id: 'furn_bed', category: ShopCategory.furniture, name: 'Yatak', emoji: '🛏️', price: 0, width: 2, depth: 1, height: 0.55, colorValue: 0xFF7986CB),
  ShopItem(id: 'furn_rug', category: ShopCategory.furniture, name: 'Halı', emoji: '🟥', price: 0, width: 2, depth: 2, height: 0.04, colorValue: 0xFFE57373),
  ShopItem(id: 'furn_lamp', category: ShopCategory.furniture, name: 'Lamba', emoji: '💡', price: 0, height: 1.2, colorValue: 0xFFFFD54F),
  ShopItem(id: 'furn_sofa', category: ShopCategory.furniture, name: 'Koltuk', emoji: '🛋️', price: 50, width: 2, depth: 1, height: 0.65, colorValue: 0xFF26A69A),
  ShopItem(id: 'furn_table', category: ShopCategory.furniture, name: 'Masa', emoji: '🪑', price: 30, width: 2, depth: 1, height: 0.5, colorValue: 0xFF8D6E63),
  ShopItem(id: 'furn_plant', category: ShopCategory.furniture, name: 'Saksı çiçeği', emoji: '🪴', price: 10, height: 0.9, colorValue: 0xFF66BB6A),
  ShopItem(id: 'furn_tv', category: ShopCategory.furniture, name: 'Televizyon', emoji: '📺', price: 70, height: 0.9, colorValue: 0xFF455A64),
  ShopItem(id: 'furn_books', category: ShopCategory.furniture, name: 'Kitaplık', emoji: '📚', price: 40, height: 1.5, colorValue: 0xFFA1887F),
  ShopItem(id: 'furn_aquarium', category: ShopCategory.furniture, name: 'Akvaryum', emoji: '🐠', price: 90, height: 0.8, colorValue: 0xFF4FC3F7),
];

ShopItem? shopItemById(String id) {
  for (final item in shopCatalog) {
    if (item.id == id) return item;
  }
  return null;
}

/// Bir kategorideki eşyalar.
List<ShopItem> shopItemsIn(ShopCategory category) => [
  for (final item in shopCatalog)
    if (item.category == category) item,
];
