import 'package:flutter/material.dart';

import '../games/bombali_sayilar_game.dart';
import '../games/memory_match_game.dart';
import '../games/pattern_game.dart';
import '../games/reflex_game.dart';
import '../games/sequence_memory_game.dart';
import '../games/stroop_game.dart';
import '../models/game_catalog_entry.dart';
import '../widgets/skill_ratings_table.dart';

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
];

class GameCatalogScreen extends StatelessWidget {
  const GameCatalogScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Platformu')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: gameCatalog.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = gameCatalog[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context).pushNamed(entry.routeName),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: entry.color,
                          child: Icon(entry.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              SkillRatingsTable(ratings: entry.skills),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
