import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/profile_controller.dart';
import '../games/bombali_sayilar_game.dart';
import '../games/chess_game.dart';
import '../games/memory_match_game.dart';
import '../games/multiplication_game.dart';
import '../games/pattern_game.dart';
import '../games/puzzle_game.dart';
import '../games/reflex_game.dart';
import '../games/sequence_memory_game.dart';
import '../games/simon_game.dart';
import '../games/stroop_game.dart';
import '../models/game_catalog_entry.dart';
import '../theme/home_palette.dart';
import '../widgets/game_card.dart';
import '../widgets/home_backdrop.dart';
import '../widgets/platform_logo_mark.dart';
import '../widgets/stat_chip.dart';
import 'profile_screen.dart';

/// Platformda oynanabilir tüm oyunların listesi. Yeni bir oyun eklerken
/// buraya bir [GameCatalogEntry] daha eklenir.
const List<GameCatalogEntry> gameCatalog = [
  GameCatalogEntry(
    title: 'Bombalı Sayılar',
    description:
        'Her satırda 2 gizli bomba var. Hafızanı kullanarak 10 satırı '
        'da bombasız tamamla.',
    icon: Icons.grid_on,
    color: Colors.indigo,
    routeName: BombaliSayilarGame.routeName,
    skills: GameSkillRatings(zeka: 2, ingilizce: 0, iq: 1, hafiza: 5),
  ),
  GameCatalogEntry(
    title: 'Kart Eşleştirme',
    description:
        'Kapalı kartlar arasından eşleri bul. Eşleştirirsen sıra sende '
        'kalır, en çok çifti bulan kazanır.',
    icon: Icons.style,
    color: Colors.teal,
    routeName: MemoryMatchGame.routeName,
    skills: GameSkillRatings(zeka: 2, ingilizce: 3, iq: 1, hafiza: 5),
  ),
  GameCatalogEntry(
    title: 'Renk mi Kelime mi?',
    description:
        'Ekranda yazan kelimeyi değil, yazının rengini seç! Dikkatini '
        'topla, en çok doğru cevabı veren kazanır.',
    icon: Icons.palette,
    color: Colors.deepPurple,
    routeName: StroopGame.routeName,
    skills: GameSkillRatings(zeka: 3, ingilizce: 0, iq: 2, hafiza: 1),
  ),
  GameCatalogEntry(
    title: 'Dizi Hafızası',
    description:
        'Renkli kutular sırayla yanar, sen aynı sırayla tıkla! Dizi her '
        'turda uzar, en uzun diziyi hatırlayan kazanır.',
    icon: Icons.touch_app,
    color: Colors.orange,
    routeName: SequenceMemoryGame.routeName,
    skills: GameSkillRatings(zeka: 2, ingilizce: 0, iq: 2, hafiza: 5),
  ),
  GameCatalogEntry(
    title: 'Desen Tamamlama',
    description:
        'Sayı dizisindeki örüntüyü bul, sırada geleni seç! En çok doğru '
        'cevabı veren kazanır.',
    icon: Icons.psychology,
    color: Colors.blueGrey,
    routeName: PatternGame.routeName,
    skills: GameSkillRatings(zeka: 4, ingilizce: 0, iq: 5, hafiza: 1),
  ),
  GameCatalogEntry(
    title: 'Tepki Süresi',
    description:
        'Ekran yeşile dönünce olabildiğince hızlı dokun! Erken dokunma, '
        'cezası var. En düşük ortalama süre kazanır.',
    icon: Icons.bolt,
    color: Colors.red,
    routeName: ReflexGame.routeName,
    skills: GameSkillRatings(zeka: 1, ingilizce: 0, iq: 2, hafiza: 0),
  ),
  GameCatalogEntry(
    title: 'Simon Diyor ki',
    description:
        'Sadece "Simon dedi ki" ile başlayan talimatı uygula, değilse Pas '
        'Geç\'e bas! En çok doğru cevabı veren kazanır.',
    icon: Icons.record_voice_over,
    color: Colors.pink,
    routeName: SimonGame.routeName,
    skills: GameSkillRatings(zeka: 3, ingilizce: 0, iq: 2, hafiza: 1),
  ),
  GameCatalogEntry(
    title: 'Kayan Yapboz',
    description:
        'Sayıları sırayla dizmeye çalış! Boş kareye komşu bir sayıya '
        'dokunarak kaydır. En az hamlede tamamlayan kazanır.',
    icon: Icons.extension,
    color: Colors.cyan,
    routeName: PuzzleGame.routeName,
    skills: GameSkillRatings(zeka: 4, ingilizce: 0, iq: 4, hafiza: 2),
  ),
  GameCatalogEntry(
    title: 'Satranç',
    description:
        'Bilgisayara karşı ya da aynı cihazda karşılıklı klasik satranç '
        'oyna. Rok, geçerken alma ve terfi dahil tüm kurallarla!',
    icon: Icons.castle,
    color: Colors.brown,
    routeName: ChessGame.routeName,
    skills: GameSkillRatings(zeka: 5, ingilizce: 0, iq: 5, hafiza: 3),
  ),
  GameCatalogEntry(
    title: 'Çarpım Bahçesi',
    description:
        '3 × 4 demek, 4 tanesini üç kere almak demek! Nesne ızgaralarını '
        'say, kendi ızgaranı kur, çarpmanın mantığını kavra.',
    icon: Icons.calculate,
    color: Colors.green,
    routeName: MultiplicationGame.routeName,
    skills: GameSkillRatings(zeka: 5, ingilizce: 0, iq: 4, hafiza: 3),
  ),
];

/// Platformun künyesi: hem giriş ekranı hem ana menü aynı üç rozeti gösterir,
/// böylece kullanıcı daha giriş yapmadan platformda ne olduğunu görür. Oyun
/// sayısı [gameCatalog]'dan okunur — yeni oyun eklendiğinde iki ekranda da
/// kendiliğinden güncellenir.
List<Widget> platformStatChips() => [
  StatChip(
    icon: Icons.grid_view_rounded,
    label: '${gameCatalog.length} oyun',
  ),
  const StatChip(icon: Icons.people_alt_outlined, label: '1-2 oyuncu'),
  const StatChip(icon: Icons.insights_outlined, label: '4 beceri alanı'),
];

/// Platformun ana sayfası: koyu bir "konsol paneli" görünümünde oyun
/// kataloğu.
///
/// Ekran, platformun açık `MaterialApp.theme`'i yerine kendi koyu temasını
/// ([homeThemeData]) yerel bir [Theme] ile kendi alt ağacına uygular — oyun
/// ekranları platform temasıyla olduğu gibi kalır (bkz. CLAUDE.md,
/// "Theming": aynı yerel-tema deseni Bombalı Sayılar'da da var).
///
/// [AppBar] yok, yerine kaydırılmayan bir [_TopBar] var: katalog kök route
/// olduğu için geri butonuna ihtiyaç duymuyor ve başlık + profil düğmesi liste
/// kaydırılırken de yerinde kalıyor.
class GameCatalogScreen extends StatelessWidget {
  const GameCatalogScreen({super.key});

  static const routeName = '/';

  /// Kart ızgarasının kırılma noktaları ve sabit kart yüksekliği. Yükseklik
  /// sabit, çünkü değişken yükseklikli kartlar yan yana dizildiğinde tırtıklı
  /// bir ızgara oluşuyor; kart içeriği bu yüksekliğe göre sınırlandırılmış
  /// durumda (bkz. `GameCard`).
  static const _twoColumnWidth = 720.0;
  static const _threeColumnWidth = 1080.0;
  static const _cardHeight = 234.0;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: homeThemeData(),
      child: Scaffold(
        backgroundColor: HomePalette.backdropTop,
        body: HomeBackdrop(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  children: [
                    const _TopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Hero(),
                            const SizedBox(height: 22),
                            _GameGrid(),
                            const SizedBox(height: 18),
                            const _FooterNote(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const PlatformLogoMark(),
          const SizedBox(width: 12),
          const Text(
            'Oyun Platformu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: HomePalette.textPrimary,
            ),
          ),
          const Spacer(),
          Tooltip(
            message: profile.hasName ? profile.name : 'Profil',
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () =>
                    Navigator.of(context).pushNamed(ProfileScreen.routeName),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: HomePalette.outline),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 20,
                    color: HomePalette.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final greeting = profile.hasName
        ? 'Hoş geldin, ${profile.name}.'
        : 'Hoş geldin.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF3DDC97),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'OYUN KÜTÜPHANESİ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: HomePalette.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: HomePalette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const Text(
            'Bir oyun seç ve başla. Her oyun zeka, IQ, hafıza ve İngilizce '
            'becerilerini farklı ölçüde çalıştırır.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: HomePalette.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: platformStatChips(),
        ),
      ],
    );
  }
}

/// Kartların responsive ızgarası. `shrinkWrap` + `NeverScrollableScrollPhysics`
/// ile dış [SingleChildScrollView]'in içinde yaşar: 9 kart için tembel kurulum
/// gerekmiyor ve bu sayede kartların hepsi her zaman kurulu oluyor (küçük
/// görünümlerde ve widget testlerinde de).
class _GameGrid extends StatelessWidget {
  const _GameGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= GameCatalogScreen._threeColumnWidth
            ? 3
            : width >= GameCatalogScreen._twoColumnWidth
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: GameCatalogScreen._cardHeight,
          ),
          itemCount: gameCatalog.length,
          itemBuilder: (context, index) {
            final entry = gameCatalog[index];
            return GameCard(
              entry: entry,
              index: index,
              onTap: () => Navigator.of(context).pushNamed(entry.routeName),
            );
          },
        );
      },
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: HomePalette.textMuted),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Her karttaki yıldızlar, o oyunun dört beceri alanını ne kadar '
            'geliştirdiğini gösterir.',
            style: TextStyle(fontSize: 12, color: HomePalette.textMuted),
          ),
        ),
      ],
    );
  }
}
