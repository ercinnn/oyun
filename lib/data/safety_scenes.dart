/// Güvenlik dedektifi sahnesi: günlük bir davranış, güvenli mi tehlikeli mi.
class SafetyScene {
  const SafetyScene({
    required this.emoji,
    required this.text,
    required this.safe,
    required this.explanation,
  });

  final String emoji;
  final String text;
  final bool safe;
  final String explanation;
}

/// Bir cihazın gücü (watt); tasarruf sorularında kullanılır.
class Appliance {
  const Appliance(this.name, this.emoji, this.watts);

  final String name;
  final String emoji;
  final int watts;
}

/// Sahneler elle yazılmıştır. Yalnızca "yapma / yap" davranışlarını öğretir;
/// taklit edilebilecek bir deney tarifi içermez. Bilgi ilkokul düzeyindedir.
const List<SafetyScene> safetyScenes = [
  SafetyScene(
    emoji: '💦',
    text: 'Ali ıslak elleriyle prize takılı bir fişe dokunuyor.',
    safe: false,
    explanation:
        'Su elektriği iletir. Islak elle elektrikli eşyaya dokunmak çok tehlikelidir; önce eller kurulanmalıdır.',
  ),
  SafetyScene(
    emoji: '🔩',
    text: 'Ece prizin deliğine bir çivi sokuyor.',
    safe: false,
    explanation:
        'Prizler tehlikelidir; içine hiçbir şey sokulmaz. Metal bir cisim elektriği iletir ve çok kötü bir kazaya yol açar.',
  ),
  SafetyScene(
    emoji: '🔌',
    text: 'Tek bir uzatma kablosuna aynı anda ütü, ısıtıcı ve saç kurutma makinesi takılmış.',
    safe: false,
    explanation:
        'Bir prize çok fazla güçlü cihaz takılırsa kablo aşırı ısınır ve yangın çıkabilir.',
  ),
  SafetyScene(
    emoji: '🧵',
    text: 'Kablosunun içindeki teller görünecek kadar yıpranmış bir ütü kullanılıyor.',
    safe: false,
    explanation:
        'Yıpranmış kablo elektriği dışarı sızdırabilir. Böyle bir cihaz kullanılmaz; bir yetişkine söylenir.',
  ),
  SafetyScene(
    emoji: '🪁',
    text: 'Mert uçurtmasını yüksek gerilim hatlarının hemen yakınında uçuruyor.',
    safe: false,
    explanation:
        'Uçurtma ipi ya da uçurtma elektrik teline değerse büyük tehlike oluşur. Uçurtma açık, telsiz bir alanda uçurulur.',
  ),
  SafetyScene(
    emoji: '⚡',
    text: 'Yere düşmüş bir elektrik teli görüp ona dokunmaya çalışmak.',
    safe: false,
    explanation:
        'Yerdeki tele asla yaklaşılmaz. Uzaktan bir yetişkine ve elektrik firmasına haber verilir.',
  ),
  SafetyScene(
    emoji: '🪢',
    text: 'Fişi çıkarmak için kablosundan asılarak çekmek.',
    safe: false,
    explanation:
        'Kablodan çekmek telleri koparabilir. Fiş, gövdesinden tutularak çıkarılır.',
  ),
  SafetyScene(
    emoji: '🛁',
    text: 'Açık bir elektrikli cihazı banyoda suyun yanına koymak.',
    safe: false,
    explanation:
        'Su ile elektrik birlikte çok tehlikelidir. Elektrikli cihazlar suyun yanından uzak tutulur.',
  ),
  SafetyScene(
    emoji: '🧤',
    text: 'Kuru elle fişi gövdesinden tutup prizden çıkarmak.',
    safe: true,
    explanation:
        'Doğru! Eller kuru olmalı ve fiş kablosundan değil gövdesinden tutulmalıdır.',
  ),
  SafetyScene(
    emoji: '🧸',
    text: 'Küçük kardeşin odasındaki prizlerin koruyucu kapakla kapatılması.',
    safe: true,
    explanation:
        'Prize kapak takmak küçük çocukların prizle oynamasını engeller; güvenli bir davranıştır.',
  ),
  SafetyScene(
    emoji: '🔋',
    text: 'Kullanılmayan bir cihazın fişini prizden çekmek.',
    safe: true,
    explanation:
        'Kullanmadığın cihazın fişini çekmek hem güvenlidir hem de elektrik tasarrufu sağlar.',
  ),
  SafetyScene(
    emoji: '👩‍🔧',
    text: 'Kıvılcım çıkaran bozuk bir cihazı kendin açmak yerine bir yetişkine göstermek.',
    safe: true,
    explanation:
        'Bozuk cihazlara kendi başına dokunma; yetişkine söylemek en güvenli yoldur.',
  ),
  SafetyScene(
    emoji: '🚧',
    text: '"Yüksek gerilim, tehlike" levhasını görünce oradan uzak durmak.',
    safe: true,
    explanation:
        'Uyarı levhalarını ciddiye almak seni korur; tehlikeli yerlerden uzak durulur.',
  ),
];

/// Cihaz gücü tablosu (yaklaşık, ilkokul düzeyinde).
const List<Appliance> appliances = [
  Appliance('LED ampul', '💡', 9),
  Appliance('Telefon şarjı', '📱', 10),
  Appliance('Televizyon', '📺', 100),
  Appliance('Buzdolabı', '🧊', 150),
  Appliance('Dizüstü bilgisayar', '💻', 60),
  Appliance('Mikrodalga fırın', '🍲', 1000),
  Appliance('Elektrikli süpürge', '🧹', 1200),
  Appliance('Saç kurutma makinesi', '💇', 1800),
  Appliance('Ütü', '👔', 2000),
];
