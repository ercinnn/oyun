import '../models/chess_lesson.dart';

/// Satranç dersleri (Başlangıç / Orta / İleri). Tüm metinler elle yazılmış
/// Türkçe cümlelerdir — değişken bir kelimeye ek getirilmez. Pozisyonlar FEN
/// ile, hamleler 'e2e4' biçiminde verilir; `test/widget_test.dart` her
/// pozisyonun okunduğunu ve kabul edilen her hamlenin yasal olduğunu doğrular.
const _start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
const _afterE4E5 =
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2';

const List<ChessLesson> chessLessons = [
  // ───────────────────────── BAŞLANGIÇ ─────────────────────────
  ChessLesson(
    id: 'b1',
    level: ChessLessonLevel.baslangic,
    title: 'Tahta ve taşlar',
    summary: 'Kareler, koordinatlar ve başlangıç dizilimi',
    steps: [
      LessonInfoStep(
        fen: _start,
        highlights: ['a1'],
        text:
            'Satranç tahtası 8×8 = 64 karedir. Sütunlar soldan sağa a-h harfleriyle, '
            'sıralar beyazın tarafından 1-8 sayılarıyla adlandırılır. Vurgulu kare a1: '
            'beyazın sol alt köşesi.',
      ),
      LessonQuizStep(
        fen: _start,
        question: 'Beyazın sağ alt köşesindeki kare (h1) hangi renktir?',
        options: ['Koyu', 'Açık'],
        correctIndex: 1,
        explanation:
            'Sağ alt köşe her zaman açık renklidir. Kolay hatırlamak için: beyaz sağda.',
      ),
      LessonInfoStep(
        fen: _start,
        highlights: ['d1', 'd8'],
        text:
            'Vezir kendi rengini sever: beyaz vezir açık karede (d1), siyah vezir koyu '
            'karede (d8) başlar. Şah her zaman vezirin yanındadır.',
      ),
      LessonInfoStep(
        fen: _start,
        text:
            'Her oyuncunun 16 taşı vardır: 8 piyon, 2 kale, 2 at, 2 fil, 1 vezir ve 1 şah. '
            'Arka sırada soldan sağa kale, at, fil, vezir, şah, fil, at, kale dizilir. '
            'Piyonlar hemen önlerinde durur.',
      ),
      LessonQuizStep(
        question: 'Bir satranç tahtasında kaç kare vardır?',
        options: ['32', '64', '81'],
        correctIndex: 1,
        explanation: '8 sütun × 8 sıra = 64 kare, yarısı açık yarısı koyu.',
      ),
      LessonMoveStep(
        fen: _start,
        prompt: 'İlk hamleni yap: e2 piyonunu iki kare ilerleterek e4\'e götür.',
        accepted: ['e2e4'],
        highlights: ['e2'],
        success:
            'Harika! Önce taşa, sonra gideceği kareye dokunarak hamle yaparsın. e4 merkezde '
            'güçlü bir karedir.',
        wrong:
            'Bu hamle olur ama hedef değildi. e2 piyonunu seçip e4 karesine dokun.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b2',
    level: ChessLessonLevel.baslangic,
    title: 'Taşların hareketi',
    summary: 'Kale, fil, vezir, at, şah ve piyon nasıl gider',
    steps: [
      LessonInfoStep(
        fen: '8/8/3P4/8/1p1R4/8/8/8 w - - 0 1',
        highlights: ['d4'],
        text:
            'Kale düz gider: yatay ve dikey, istediği kadar kare. Kendi taşının üstünden '
            'geçemez ve üstüne çıkamaz. Rakip taşı görürse onu alarak orada durabilir.',
      ),
      LessonMarkStep(
        fen: '8/8/3P4/8/1p1R4/8/8/8 w - - 0 1',
        pieceSquare: 'd4',
        prompt:
            'Kalenin (d4) gidebileceği tüm kareleri işaretle, sonra "Kontrol et"e bas. '
            'Beyaz piyon kendi taşın, siyah piyon rakip taşı.',
        success:
            'Doğru! d6\'daki kendi piyonun yolu kesiyor, b4\'teki rakip piyonu ise alabilirsin.',
      ),
      LessonInfoStep(
        fen: '8/8/8/8/8/8/8/2B5 w - - 0 1',
        highlights: ['c1'],
        text:
            'Fil çapraz gider, istediği kadar kare. Hep aynı renkli karelerde kalır: '
            'c1 koyu bir kare olduğu için bu fil hep koyu karelerde gezer.',
      ),
      LessonMarkStep(
        fen: '8/8/8/8/8/8/8/2B5 w - - 0 1',
        pieceSquare: 'c1',
        prompt: 'Filin (c1) gidebileceği tüm kareleri işaretle.',
        success: 'Tamam! Fil iki çaprazda toplam 7 kareye gidebilir.',
      ),
      LessonInfoStep(
        fen: '3p4/8/8/8/8/8/8/3Q4 w - - 0 1',
        highlights: ['d1'],
        text:
            'Vezir en güçlü taştır: kale ile filin hareketini birleştirir. Düz ve çapraz, '
            'istediği kadar kare gider.',
      ),
      LessonMoveStep(
        fen: '3p4/8/8/8/8/8/8/3Q4 w - - 0 1',
        prompt: 'Veziri kullanarak d8\'deki siyah piyonu al.',
        accepted: ['d1d8'],
        success: 'Vezir tek hamlede tahtanın öbür ucuna gitti. Piyon senin.',
        wrong: 'Vezir bunu da yapabilir ama hedef d8 karesindeki piyon.',
      ),
      LessonInfoStep(
        fen: _start,
        highlights: ['b1'],
        text:
            'At L şeklinde gider: iki kare düz, bir kare yana. Ata özel bir yetenek: '
            'diğer taşların üzerinden atlayabilir. Bu yüzden oyunun başında ilk çıkan taşlardandır.',
      ),
      LessonMarkStep(
        fen: _start,
        pieceSquare: 'b1',
        prompt:
            'Başlangıç dizilimindeki atın (b1) gidebileceği kareleri işaretle. '
            'Kendi piyonlarının üstüne çıkamaz.',
        success: 'Evet: a3 ve c3. d2\'de kendi piyonun var.',
      ),
      LessonInfoStep(
        fen: '8/8/8/8/4K3/8/8/8 w - - 0 1',
        highlights: ['e4'],
        text:
            'Şah her yöne gider ama sadece bir kare. Şah en önemli taştır: onu kaybedersen '
            'oyun biter. Rakibin saldırdığı bir kareye gidemez.',
      ),
      LessonMarkStep(
        fen: '8/8/8/8/4K3/8/8/8 w - - 0 1',
        pieceSquare: 'e4',
        prompt: 'Şahın (e4) gidebileceği tüm kareleri işaretle.',
        success: 'Şah çevresindeki 8 kareden herhangi birine gidebilir.',
      ),
      LessonInfoStep(
        fen: '8/8/8/8/8/8/4P3/8 w - - 0 1',
        highlights: ['e2'],
        text:
            'Piyon sadece ileri gider, bir kare. İlk hamlesinde istersen iki kare gidebilir. '
            'Piyon önündeki taşı alamaz; ama çaprazındaki rakip taşı alabilir. '
            'Geri gitmez.',
      ),
      LessonMarkStep(
        fen: '8/8/8/8/8/8/4P3/8 w - - 0 1',
        pieceSquare: 'e2',
        prompt: 'Başlangıçtaki piyonun (e2) gidebileceği kareleri işaretle.',
        success: 'Doğru: e3 ve e4. İlk hamlede iki kare gitme hakkı var.',
      ),
      LessonMoveStep(
        fen: '8/8/8/8/8/3p4/4P3/8 w - - 0 1',
        prompt: 'Piyon çapraz alır. e2 piyonuyla d3\'teki siyah piyonu al.',
        accepted: ['e2d3'],
        success: 'Piyon yürürken düz, alırken çapraz gider.',
        wrong: 'Piyon düz ilerleyerek taş alamaz. Çapraza bak: d3.',
      ),
      LessonQuizStep(
        question: 'Hangi taş diğer taşların üzerinden atlayabilir?',
        options: ['Kale', 'Fil', 'At', 'Vezir'],
        correctIndex: 2,
        explanation: 'Sadece at atlar. Diğer taşlar yolları açıksa gidebilir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b3',
    level: ChessLessonLevel.baslangic,
    title: 'Şah, mat ve pat',
    summary: 'Şah çekmek, kurtulmak ve oyunun bitişi',
    steps: [
      LessonInfoStep(
        fen: '4k3/8/8/8/8/8/4R3/4K3 b - - 0 1',
        highlights: ['e2'],
        text:
            'Bir taş rakip şaha saldırırsa buna şah denir. Burada beyaz kale e8\'deki '
            'siyah şaha şah çekiyor (kırmızı parlama). Şah çekilen oyuncu hemen çaresine bakmalı.',
      ),
      LessonInfoStep(
        text:
            'Şahtan kurtulmanın üç yolu var: 1) Şahı saldırıdan kaçırmak. 2) Saldıran taşı almak. '
            '3) Araya bir taşını koyup yolu kapatmak. Hiçbiri yoksa oyun biter: buna mat denir.',
      ),
      LessonMoveStep(
        fen: '4r2k/8/8/8/8/8/3B4/4K3 w - - 0 1',
        prompt:
            'Beyaz şah çekilmiş durumda (siyah kale e8). Şahı kaçırmak yerine '
            'bir taşla yolu kapat: fili araya koy.',
        accepted: ['d2e3'],
        success: 'Fil e3\'e gitti ve kale ile şah arasına girdi. Şah güvende.',
        wrong: 'Bu geçerli bir hamle ama hedef araya taş koymaktı: fil ile e3.',
      ),
      LessonMoveStep(
        fen: '6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1',
        prompt: 'Mat et! Siyah şahın önü kendi piyonlarıyla kapalı. Kaleyi son sıraya götür.',
        anyMate: true,
        success:
            'Şah mat! Şah saldırı altında ve kaçamıyor. Buna "son sıra matı" denir.',
        wrong: 'Bu mat değil. Siyah şahın kaçış karelerine bak: kendi piyonları önünü kapatıyor.',
      ),
      LessonInfoStep(
        fen: 'k7/2Q5/1K6/8/8/8/8/8 b - - 0 1',
        text:
            'Pat: Sıradaki oyuncunun şahı tehdit altında değil ama yapabileceği hiç yasal hamle yok. '
            'Pat, matın aksine beraberliktir! Burada siyah şah a8\'de sıkışmış, oynayacak yeri yok.',
      ),
      LessonMoveStep(
        fen: 'k7/8/1K6/8/8/8/8/2Q5 w - - 0 1',
        prompt: 'Mat et ama pat yapma! Vezir c7\'ye giderse pat olur.',
        anyMate: true,
        success: 'Vezir c8: şah çekiyor ve kaçış yok. Mat!',
        wrong: 'Dikkat: bu hamle mat yapmıyor. Vezir c7\'ye giderse pat olur, mat için vezirle şah çekmelisin.',
      ),
      LessonQuizStep(
        question:
            'Şahın tehdit altında değil ama oynayabileceğin hiçbir yasal hamlen yok. Sonuç ne olur?',
        options: ['Kaybedersin', 'Berabere (pat)', 'Oyun devam eder'],
        correctIndex: 1,
        explanation: 'Buna pat denir ve oyun berabere biter.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b4',
    level: ChessLessonLevel.baslangic,
    title: 'Özel hamleler',
    summary: 'Rok, geçerken alma ve piyon terfisi',
    steps: [
      LessonInfoStep(
        fen: 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
        highlights: ['e1', 'h1'],
        text:
            'Rok: şah iki kare kaleye doğru gider, kale de şahın üstünden atlayıp yanına gelir. '
            'Şahı korumaya alırken kaleyi de oyuna sokar. Kural: şah ve o kale hiç oynamamış olmalı, '
            'aralarında taş olmamalı, şah şahta olmamalı ve geçtiği kareler saldırı altında olmamalı.',
      ),
      LessonMoveStep(
        fen: 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
        prompt: 'Kısa rok yap: şahı iki kare sağa (g1) götür.',
        accepted: ['e1g1'],
        success: 'Kısa rok! Kale f1\'e atladı ve şah köşede güvende.',
        wrong: 'Rok için şahı seçip iki kare yana, g1\'e götür.',
      ),
      LessonMoveStep(
        fen: 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
        prompt: 'Şimdi uzun rok yap: şahı iki kare sola (c1) götür.',
        accepted: ['e1c1'],
        success: 'Uzun rok! Kale d1\'e geldi.',
        wrong: 'Uzun rok için şahı iki kare sola, c1\'e götür.',
      ),
      LessonInfoStep(
        fen: '7k/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
        highlights: ['d5', 'e5'],
        text:
            'Geçerken alma (en passant): siyah piyon d7\'den d5\'e iki kare atlayıp beyaz piyonun '
            'yanından geçti. Beyaz piyon sanki bir kare yürümüş gibi onu çaprazdan (d6) alabilir. '
            'Bu hak sadece hemen sonraki hamlede geçerli.',
      ),
      LessonMoveStep(
        fen: '7k/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
        prompt: 'e5 piyonuyla d5 piyonunu geçerken al: e5\'ten d6\'ya git.',
        accepted: ['e5d6'],
        success: 'Piyon d6\'ya gitti ve d5\'teki piyon tahtadan kalktı.',
        wrong: 'Geçerken almak için piyonu e5\'ten d6\'ya götür.',
      ),
      LessonInfoStep(
        text:
            'Terfi: bir piyon tahtanın öbür ucuna (8. sıra) ulaşırsa vezir, kale, fil ya da ata dönüşür. '
            'Çoğunlukla vezir seçilir. Bu derste terfi otomatik vezir olur.',
      ),
      LessonMoveStep(
        fen: '8/4P3/8/8/8/8/8/k3K3 w - - 0 1',
        prompt: 'Piyonu son sıraya götür ve terfi ettir.',
        accepted: ['e7e8'],
        highlights: ['e7'],
        success: 'Piyon vezir oldu! Tek piyonla oyunu değiştirdin.',
        wrong: 'Piyonu bir kare ileri, e8\'e götür.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b5',
    level: ChessLessonLevel.baslangic,
    title: 'Taş değerleri ve takas',
    summary: 'Hangi taş kaç puan, takas ne zaman iyi',
    steps: [
      LessonInfoStep(
        text:
            'Taşların yaklaşık değerleri: piyon 1, at 3, fil 3, kale 5, vezir 9 puan. '
            'Şahın değeri yok, çünkü kaybedilmez. Takas yaparken bu sayıları karşılaştır.',
      ),
      LessonQuizStep(
        question: 'Bir vezir kaç piyona denk gelir?',
        options: ['3', '5', '9'],
        correctIndex: 2,
        explanation: 'Vezir 9 puandır, yani yaklaşık 9 piyon eder.',
      ),
      LessonMoveStep(
        fen: '4k3/8/8/3q4/8/2N5/8/4K3 w - - 0 1',
        prompt: 'Bedava taş var! Rakibin vezirini at ile al.',
        accepted: ['c3d5'],
        success: 'Vezir 9 puan, at 3 puan: 6 puan kâr ettin.',
        wrong: 'At c3\'ten d5\'e gidip veziri alabilir.',
      ),
      LessonQuizStep(
        fen: '4k3/8/2p5/3p4/8/8/3Q4/4K3 w - - 0 1',
        question:
            'Vezirle d5 piyonunu almak iyi bir fikir mi? (c6 piyonu d5\'i koruyor.)',
        options: ['Evet, bir piyon kazanırım', 'Hayır, piyon veziri alır'],
        correctIndex: 1,
        explanation:
            'Korunan bir taşı almadan önce koruyanı say. 1 puanlık piyon için 9 puanlık vezir kaybedilir.',
      ),
      LessonQuizStep(
        question: 'Kale (5) ile fili (3) takas etmek sana ne getirir?',
        options: ['2 puan kaybettirir', '2 puan kazandırır', 'Fark yok'],
        correctIndex: 0,
        explanation:
            'Kale verip fil almak 2 puan kaybettirir. Buna "kaliteyi feda etmek" denir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b6',
    level: ChessLessonLevel.baslangic,
    title: 'Temel kurallar ve beraberlik',
    summary: 'Sıra, beraberlik durumları ve yetersiz materyal',
    steps: [
      LessonInfoStep(
        text:
            'Beyaz başlar ve sırayla oynanır. Bir hamle yapmak zorundasın, pas geçemezsin. '
            'Şahın alınmaz: şah tehdit altındaysa hemen çözmelisin, oyun mat ile biter.',
      ),
      LessonQuizStep(
        question: 'Rakibin şahını yiyebilir misin?',
        options: ['Evet', 'Hayır, şah asla alınmaz; oyun mat ile biter'],
        correctIndex: 1,
        explanation: 'Şah çekilince rakip bunu çözmek zorundadır. Çözemezse mat olur.',
      ),
      LessonQuizStep(
        question:
            '50 hamle kuralı: Her iki taraf da piyon oynamadan ve taş almadan 50\'şer hamle yaparsa ne olur?',
        options: ['Beyaz kazanır', 'Oyun berabere biter', 'Oyun devam etmek zorunda'],
        correctIndex: 1,
        explanation: 'Oyun ilerlemiyorsa berabere ilan edilir.',
      ),
      LessonQuizStep(
        question: 'Aynı pozisyon üç kez ortaya çıkarsa ne olur?',
        options: ['Oyun berabere biter', 'Sıradaki kaybeder', 'Oyun sıfırlanır'],
        correctIndex: 0,
        explanation:
            'Üç kez tekrar (üçlü tekrar) beraberlik sebebidir. Sürekli şah çekip durmak bu yüzden beraberlik getirebilir.',
      ),
      LessonQuizStep(
        fen: 'k7/8/8/8/8/8/8/K6N w - - 0 1',
        question: 'Beyazın sadece bir atı var. Bu pozisyonda mat yapılabilir mi?',
        options: ['Evet', 'Hayır, materyal yetersiz: oyun berabere'],
        correctIndex: 1,
        explanation:
            'Şah + tek at (ya da tek fil) ile mat yapılamaz. Böyle durumlarda oyun berabere biter.',
      ),
    ],
  ),

  // ───────────────────────── ORTA ─────────────────────────
  ChessLesson(
    id: 'o1',
    level: ChessLessonLevel.orta,
    title: 'Açılış ilkeleri',
    summary: 'Merkez, gelişme ve rok',
    steps: [
      LessonInfoStep(
        fen: _start,
        highlights: ['d4', 'e4', 'd5', 'e5'],
        text:
            'Açılışta üç ilke: 1) Merkezi (vurgulu 4 kare) piyonlarla ve taşlarla kontrol et. '
            '2) Taşlarını çabucak oyuna sok: önce at ve filler. '
            '3) Şahını rok ile güvene al. Aynı taşla tekrar tekrar oynama, erken vezir çıkarma.',
      ),
      LessonMoveStep(
        fen: _start,
        prompt: 'Merkezi al: bir merkez piyonunu iki kare ilerlet (e4 ya da d4).',
        accepted: ['e2e4', 'd2d4'],
        success: 'Güzel: piyonun merkezi tutuyor ve fil ile vezire yol açıyor.',
        wrong: 'İlk hamlede merkez piyonlarından (e ya da d) birini iki kare ilerlet.',
      ),
      LessonMoveStep(
        fen: _afterE4E5,
        prompt: 'Taşını geliştir: bir atı oyuna sok.',
        accepted: ['g1f3', 'b1c3'],
        success: 'At merkeze bakıyor ve rok için yolu açtı.',
        wrong: 'Şimdi bir at çıkarma zamanı: g1 ya da b1\'deki atı oynat.',
      ),
      LessonMoveStep(
        fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
        prompt: 'Filini geliştir: f1\'deki fili aktif bir kareye çıkar (c4 ya da b5).',
        accepted: ['f1c4', 'f1b5'],
        success: 'Fil artık uzun çapraza bakıyor ve rok için f1 kareyi boşalttı.',
        wrong: 'Fili c4 ya da b5 karesine çıkar.',
      ),
      LessonMoveStep(
        fen: 'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
        prompt: 'Şahını güvene al: kısa rok yap.',
        accepted: ['e1g1'],
        success: 'Rok tamam: şah güvende, kale oyunda. Açılışın üç ilkesini tamamladın.',
        wrong: 'Şahı iki kare sağa, g1\'e götür.',
      ),
      LessonQuizStep(
        question: 'Erken vezir çıkarmak neden risklidir?',
        options: [
          'Vezir yavaş bir taştır',
          'Rakip taşlarını geliştirirken vezirini kovalar ve zaman kazanır',
          'Vezir hiç çıkamaz',
        ],
        correctIndex: 1,
        explanation:
            'Vezir değerli olduğu için rakip taşlarıyla tehdit edip onu kovalayabilir; sen zaman kaybedersin.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o2',
    level: ChessLessonLevel.orta,
    title: 'Temel taktikler',
    summary: 'Çatal, çivileme, şiş ve keşif',
    steps: [
      LessonInfoStep(
        text:
            'Taktik, birkaç hamlelik kısa bir plan ile materyal kazanmaktır. En sık dört taktik: '
            'çatal, çivileme, şiş ve keşif. Her birini tahtada deneyeceksin.',
      ),
      LessonInfoStep(
        fen: 'r3k3/8/8/3N4/8/8/8/4K3 w - - 0 1',
        text:
            'Çatal: tek bir taşla aynı anda iki (ya da daha fazla) taşa saldırmak. '
            'Rakip ikisini birden kurtaramaz. Ata çok yakışır.',
      ),
      LessonMoveStep(
        fen: 'r3k3/8/8/3N4/8/8/8/4K3 w - - 0 1',
        prompt: 'Atı öyle bir kareye oyna ki hem şaha hem kaleye (a8) saldırsın.',
        accepted: ['d5c7'],
        success: 'At c7: şah çekiyor ve kaleye de saldırıyor. Şah kaçınca kaleyi alırsın.',
        wrong: 'Aradığın kare c7: oradan e8 ve a8 birlikte tehdit altında.',
      ),
      LessonInfoStep(
        text:
            'Çivileme: bir taşı, arkasındaki daha değerli taşı (çoğunlukla şahı) korumak için '
            'yerinden oynatamayacak duruma getirmek. Şahın önündeki taş oynarsa şah ortaya çıkar; bu yasak.',
      ),
      LessonMoveStep(
        fen: 'r3k3/8/2n5/8/8/8/8/4KB2 w - - 0 1',
        prompt: 'Fili b5\'e götürerek c6 atını şahına karşı çivile.',
        accepted: ['f1b5'],
        success: 'At artık hareket edemez: oynarsa şah açığa çıkar.',
        wrong: 'Fil, f1\'den b5\'e gidebilir: b5, c6 ve e8 aynı çaprazda.',
      ),
      LessonInfoStep(
        text:
            'Şiş çivilemenin tersidir: değerli taşa saldırırsın, o kaçınca arkasındaki daha az '
            'değerli taşı alırsın. Şah ya da vezir önde durur, arkasında bir taş bekler.',
      ),
      LessonMoveStep(
        fen: '3k2q1/8/8/8/8/8/8/R3K3 w - - 0 1',
        prompt: 'Kaleyi a8\'e götür: şah çekiyor, şah kaçınca arkasındaki vezire ulaşacaksın.',
        accepted: ['a1a8'],
        success: 'Şah yer değiştirmek zorunda, sonra kale vezire ulaşır. İşte şiş!',
        wrong: 'Kale a-hattından a8\'e gidip şah çeker, arkasında da vezir (g8) var.',
      ),
      LessonInfoStep(
        text:
            'Keşif: bir taşı hareket ettirince arkasındaki taşın hattını açarsın. '
            'Hareket eden taş da bir tehdit yaratırsa rakip iki şeyle birden uğraşır.',
      ),
      LessonMoveStep(
        fen: '4k3/8/2q5/4N3/8/8/8/4RK2 w - - 0 1',
        prompt: 'Atla veziri al: hem vezir kalkacak hem de kale keşif şahı çekecek.',
        accepted: ['e5c6'],
        success: 'At vezirin yerinde, kale şah çekiyor. Rakibin cevabı yok, sıra sende.',
        wrong: 'At e5\'ten c6\'daki veziri alabilir ve arkasından kale açılır.',
      ),
      LessonQuizStep(
        question: 'Tek taşla iki taşa birden saldırmaya ne denir?',
        options: ['Çatal', 'Çivileme', 'Rok'],
        correctIndex: 0,
        explanation: 'Çatal: rakip ikisini birden kurtaramaz.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o3',
    level: ChessLessonLevel.orta,
    title: 'Mat kalıpları',
    summary: 'Son sıra, boğulmuş mat ve kale merdiveni',
    steps: [
      LessonInfoStep(
        text:
            'Matların birçok tekrar eden kalıbı vardır. Bunları tanırsan tahtada mat fırsatını '
            'hemen görürsün. Şimdi üç kalıba bakalım.',
      ),
      LessonInfoStep(
        fen: '3r2k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
        text:
            'Son sıra matı: şahın önü kendi piyonlarıyla kapalıysa, son sıradaki bir kale ya da vezir '
            'mat eder. Bunu önlemek için oyunda şahına bir kaçış karesi ("mendil") aç.',
      ),
      LessonMoveStep(
        fen: '3r2k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1',
        prompt: 'Kaleyle son sıra matı yap.',
        anyMate: true,
        success: 'Kale d8\'de kaleyi aldı ve şah üç piyonuyla sıkıştığı için kaçamadı.',
        wrong: 'Bu mat değil. d-hattının sonuna, rakip kalenin olduğu kareye bak.',
      ),
      LessonInfoStep(
        fen: '6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1',
        text:
            'Boğulmuş mat: şahın etrafı kendi taşlarıyla dolu ve bir at şah çekiyor. At tek taştır ki '
            'kendi hattında olmayan saldırılara izin verir; şahın kaçış karesi kalmayınca mat olur.',
      ),
      LessonMoveStep(
        fen: '6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1',
        prompt: 'Atla boğulmuş mat yap.',
        anyMate: true,
        success: 'At f7: şah çekiyor ve h8 şahının etrafı kendi taşlarıyla dolu. Boğulmuş mat!',
        wrong: 'At g5\'ten f7\'ye giderse şah çeker ve etraf kapalı.',
      ),
      LessonInfoStep(
        fen: '7k/R7/8/8/8/8/8/1R2K3 w - - 0 1',
        text:
            'İki kale merdiveni: iki kale birbirini takip ederek şahı tahtanın kenarına iter. '
            'Biri sırayı (7.) tutar, diğeri şah çeker; sonra roller değişir.',
      ),
      LessonMoveStep(
        fen: '7k/R7/8/8/8/8/8/1R2K3 w - - 0 1',
        prompt: 'Merdiven matını bitir.',
        anyMate: true,
        success: 'Kale a7 ikinci sırayı kapatıyor, kale b8 şah çekiyor. Mat!',
        wrong: 'Kalelerden biri 7. sırayı kapatıyor, diğerini son sıraya götür.',
      ),
      LessonQuizStep(
        question: 'Son sıra matında şah neden kaçamaz?',
        options: [
          'Kendi piyonları önünü kapatır',
          'Şah sadece yatay gider',
          'Kale onu bağlar',
        ],
        correctIndex: 0,
        explanation: 'Piyonlar şahın kaçış karelerini kendisi kapatıyor.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o4',
    level: ChessLessonLevel.orta,
    title: 'Basit son oyunlar',
    summary: 'Vezir ve kale ile mat, terfi, muhalefet',
    steps: [
      LessonInfoStep(
        text:
            'Son oyun: tahtada az taş kaldığında şah artık saldıran bir taştır. Şahını merkeze getir, '
            'piyonlarını terfiye götür ve rakip şahı kenara sıkıştır.',
      ),
      LessonMoveStep(
        fen: '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1',
        prompt: 'Vezir ve şah birlikte mat ediyor: matı bul.',
        anyMate: true,
        success: 'Vezir g7\'de şah tarafından korunuyor, şah alamaz. Mat!',
        wrong: 'Veziri şahının korumasında olduğu bir kareye koy: g7.',
      ),
      LessonMoveStep(
        fen: '7k/8/6K1/8/8/8/8/R7 w - - 0 1',
        prompt: 'Kale ve şah ile mat et.',
        anyMate: true,
        success: 'Şahın g7 ve h7\'yi kapattı, kale son sırayı. Mat!',
        wrong: 'Kaleyi son sıraya (8.) götür, şahın diğer kaçış karelerini kapatıyor.',
      ),
      LessonMoveStep(
        fen: '8/2P5/8/8/8/8/k7/4K3 w - - 0 1',
        prompt: 'Piyonu terfi ettir: tek hamlede son sıraya git.',
        accepted: ['c7c8'],
        success: 'Yeni bir vezirin var, kazanmak artık kolay.',
        wrong: 'Piyon c7\'den c8\'e gider.',
      ),
      LessonInfoStep(
        fen: '8/8/4k3/8/4K3/8/8/8 w - - 0 1',
        highlights: ['e4', 'e6'],
        text:
            'Muhalefet: iki şah arasında tek bir kare kalıp karşı karşıya gelirse, sırası gelen taraf '
            'geri çekilmek zorundadır. Muhalefeti alan taraf yani hamle sırası olmayan taraf güçlüdür.',
      ),
      LessonQuizStep(
        fen: '8/8/4k3/8/4K3/8/8/8 w - - 0 1',
        question: 'Şahlar bir kare arayla karşı karşıya ve sıra beyazda. Muhalefet kimde?',
        options: ['Beyazda (sıra onda)', 'Siyahta'],
        correctIndex: 1,
        explanation:
            'Muhalefet hamle sırası olmayan tarafta olur: beyaz şah yön değiştirmek zorunda kalır.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o5',
    level: ChessLessonLevel.orta,
    title: 'Hata kontrolü',
    summary: 'Her hamleden önce dört soru',
    steps: [
      LessonInfoStep(
        text:
            'Çoğu oyun, taktik bilmeyenden çok "bakmayan" oyuncunun hatasıyla biter. Her hamleden önce '
            'kendine sor: 1) Rakip son hamlesiyle neyi tehdit ediyor? 2) Hangi taşlarım korumasız? '
            '3) Bu hamleyi yaparsam neyi açıkta bırakırım? 4) Rakibin şah çekebileceği ya da taş alabileceği '
            'hamleler var mı?',
      ),
      LessonMoveStep(
        fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 4 4',
        prompt:
            'Siyahın sırası. Beyaz f7\'de mat tehdit ediyor ama vezirini korumasız bırakmış. '
            'Rakibin hatasını cezalandır.',
        accepted: ['f6h5'],
        success:
            'At vezirini aldı ve tehdit ortadan kalktı. Hem savundun hem 9 puan kazandın.',
        wrong: 'Vezir h5\'te bedava duruyor: f6\'daki at ona saldırabilir.',
      ),
      LessonQuizStep(
        question: 'Bir taşı hamle yapmadan önce neden kontrol etmelisin: "Bu taş korumasız mı?"',
        options: [
          'Çünkü korumasız taş bedavaya alınabilir',
          'Çünkü korumasız taş hareket edemez',
          'Çünkü kurallar öyle der',
        ],
        correctIndex: 0,
        explanation: 'Korumasız bir taşa saldırıldığında onu kurtarmak için hamle harcarsın.',
      ),
    ],
  ),

  // ───────────────────────── İLERİ ─────────────────────────
  ChessLesson(
    id: 'a1',
    level: ChessLessonLevel.ileri,
    title: 'Piyon yapısı',
    summary: 'İkili, izole ve geçer piyon',
    steps: [
      LessonInfoStep(
        text:
            'Piyonlar geri gitmez, bu yüzden yapıları oyunun karakterini belirler. '
            'Piyon yapısındaki zayıflıklar son oyuna kadar taşınır.',
      ),
      LessonInfoStep(
        fen: '4k3/8/8/8/8/2P5/2P1PPPP/4K3 w - - 0 1',
        highlights: ['c2', 'c3'],
        text:
            'İkili piyon: aynı sütunda iki piyon üst üste. Birbirini koruyamazlar ve daha az hareket '
            'edebilirler. Genelde zayıflıktır.',
      ),
      LessonInfoStep(
        fen: '4k3/pp3ppp/8/8/3P4/8/PP3PPP/4K3 w - - 0 1',
        highlights: ['d4'],
        text:
            'İzole piyon: yanındaki sütunlarda kendi piyonu yok. Onu piyonla koruyamazsın, bu yüzden '
            'taşlarınla korumak zorunda kalırsın.',
      ),
      LessonInfoStep(
        fen: '4k3/1pp5/8/4P3/8/8/8/4K3 w - - 0 1',
        highlights: ['e5'],
        text:
            'Geçer piyon: önünde ve yan sütunlarında karşı piyon yok, yani terfiye giden yolu açık. '
            'Son oyunlarda en büyük silahtır: "geçer piyon iterilmek ister".',
      ),
      LessonQuizStep(
        fen: '4k3/1pp5/8/4P3/8/8/8/4K3 w - - 0 1',
        question: 'e5 piyonu neden geçer piyondur?',
        options: [
          'Çünkü ilerde d, e ve f sütunlarında karşı piyon yok',
          'Çünkü orta karede duruyor',
          'Çünkü şah onu koruyor',
        ],
        correctIndex: 0,
        explanation: 'Karşı piyonlar b ve c sütunlarında; e5\'in yolunu kesemezler.',
      ),
      LessonMoveStep(
        fen: '4k3/8/8/4P3/8/8/8/4K3 w - - 0 1',
        prompt: 'Geçer piyonu terfiye doğru bir kare ilerlet.',
        accepted: ['e5e6'],
        success: 'Piyon e6\'da ve şah onu destekliyor. Terfi yakın.',
        wrong: 'Piyon sadece ileri gider: e5\'ten e6\'ya.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a2',
    level: ChessLessonLevel.ileri,
    title: 'Pozisyonel kavramlar',
    summary: 'Açık hat, fil çifti, iyi fil ve mevzi',
    steps: [
      LessonInfoStep(
        fen: 'r3k2r/pp3ppp/8/8/8/8/PP3PPP/R3K2R w - - 0 1',
        highlights: ['d1', 'd8'],
        text:
            'Açık hat: içinde hiç piyon olmayan sütun. Kaleler açık hatlarda en güçlüdür: '
            'buradan rakibin arka sırasına ulaşırlar.',
      ),
      LessonMoveStep(
        fen: 'r3k2r/pp3ppp/8/8/8/8/PP3PPP/R3K2R w - - 0 1',
        prompt: 'Kaleni açık bir hatta koy (c ya da d sütunu).',
        accepted: ['a1d1', 'a1c1'],
        success: 'Kale açık hatta! Rakip kalesiyle de karşılaşabilir.',
        wrong: 'Kalelerden a1\'dekini c1 ya da d1\'e taşı.',
      ),
      LessonInfoStep(
        text:
            'Fil çifti: iki filin de duruyorsa hem açık hem koyu karelerde etkilisin. Açık pozisyonlarda '
            'iki fil genellikle bir fil ile bir ata üstün gelir.',
      ),
      LessonQuizStep(
        question: 'Fil çiftinin avantajı nedir?',
        options: [
          'İki fil de hızlı gider',
          'İki farklı renkli karede saldırı gücü',
          'Fil çifti rok yapabilir',
        ],
        correctIndex: 1,
        explanation: 'Bir fil sadece kendi rengindeki karelere gider; iki fil tahtanın tamamını kapsar.',
      ),
      LessonInfoStep(
        fen: '4k3/1p4p1/8/3N4/2P1P3/8/8/4K3 w - - 0 1',
        highlights: ['d5'],
        text:
            'Mevzi (üs): rakibin piyonuyla atılamayacak, senin piyonlarınla korunan bir kare. '
            'Burada d5 karesindeki at siyah piyonlarla kovulamaz; o kare bir üstür.',
      ),
      LessonQuizStep(
        question: 'Kendi piyonlarınla aynı renkli karelerde duran fil için ne denir?',
        options: ['İyi fil', 'Kötü fil'],
        correctIndex: 1,
        explanation:
            'Piyonlarınla aynı renkteki karelerde duran fil kendi piyonlarınca sıkışır; buna "kötü fil" denir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a3',
    level: ChessLessonLevel.ileri,
    title: 'Gelişmiş taktikler',
    summary: 'Çift şah ve feda ederek açma',
    steps: [
      LessonInfoStep(
        fen: '4k3/8/8/8/4N3/8/8/4RK2 w - - 0 1',
        highlights: ['e4', 'e1'],
        text:
            'Çift şah: tek hamleyle iki taş birden şah çeker. Ata bir keşif hareketi yaptırırsan kale '
            've at aynı anda şah çeker. Rakip yalnızca şahını oynatarak kurtulabilir: araya taş koyamaz '
            've iki saldırganı birden alamaz.',
      ),
      LessonMoveStep(
        fen: '4k3/8/8/8/4N3/8/8/4RK2 w - - 0 1',
        prompt: 'Atı öyle bir kareye götür ki hem at hem kale şah çeksin.',
        accepted: ['e4d6', 'e4f6'],
        success: 'Çift şah! Rakip şahı oynatmak zorunda; kalan taşlarını sonra toplarsın.',
        wrong: 'Atı d6 ya da f6\'ya götür: oradan e8\'e şah çeker, kale de arkadan çeker.',
      ),
      LessonQuizStep(
        question: 'Çift şahtan kurtulmanın tek yolu nedir?',
        options: ['Araya taş koymak', 'Şahı oynatmak', 'Saldıranlardan birini almak'],
        correctIndex: 1,
        explanation: 'Aynı anda iki saldırgan olduğu için sadece şahını kaçırabilirsin.',
      ),
      LessonInfoStep(
        text:
            'Savurma ve feda: bir rakip taşı, önemli bir taşı koruma görevinden uzaklaştırmak için taş '
            'feda edersin (savurma). Yükü fazla olan bir savunmacıyı (aşırı yüklenmiş taş) aynı yöntemle çökertirsin. '
            'İyi taktik oyuncusu "feda edersem ne kazanırım?" diye sürekli düşünür.',
      ),
      LessonQuizStep(
        question: 'Bir taşı feda etmek ne zaman mantıklıdır?',
        options: [
          'Her zaman, çünkü saldırmak iyidir',
          'Karşılığında mat, daha değerli taş ya da kesin bir üstünlük geliyorsa',
          'Hiçbir zaman',
        ],
        correctIndex: 1,
        explanation: 'Feda bir yatırımdır: karşılığında daha büyük bir kazanç hesaplamalısın.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a4',
    level: ChessLessonLevel.ileri,
    title: 'Son oyun teorisi',
    summary: 'Lucena, Philidor ve kale son oyunları',
    steps: [
      LessonInfoStep(
        text:
            'Kale + piyon son oyunları en sık görülenlerdir. Bilinen iki temel konum var: '
            'Lucena (kazanmayı bilmek) ve Philidor (beraberliği kurtarmayı bilmek).',
      ),
      LessonInfoStep(
        text:
            'Lucena: piyonu 7. sırada olan taraf şahı piyonun önünde, rakip şah kenara itilmiş durumdaysa '
            'kazanır. Yöntem "köprü kurmak": kaleni 4. sıraya getirip şahının arkasına '
            'siper yaparak yandan gelen şahlardan korunmak.',
      ),
      LessonInfoStep(
        text:
            'Philidor: savunan taraf kalesini kendi 3. sırasında tutar. Böylece rakip şah piyonun '
            'önünden çıkamaz. Piyon 6. sıraya çıkınca savunan kale arkadan sürekli şah çeker.',
      ),
      LessonQuizStep(
        question: 'Lucena konumunda kazanmak için hangi yöntem kullanılır?',
        options: ['Köprü kurmak', 'Pat aramak', 'Rakip fili almak'],
        correctIndex: 0,
        explanation: 'Kale ile 4. sırada köprü kurup şahı yandan gelen şahlardan korursun.',
      ),
      LessonQuizStep(
        question: 'Kale son oyunlarında kaleyi nereye koymak genelde iyidir?',
        options: [
          'Piyonun önüne',
          'Piyonun arkasına',
          'Tahtanın ortasına',
        ],
        correctIndex: 1,
        explanation:
            'Kale piyonun arkasında hem koruyan hem ilerledikçe daha çok kareyi kontrol eden bir konumdadır (Tarrasch kuralı).',
      ),
      LessonQuizStep(
        question: 'Uzak muhalefet nedir?',
        options: [
          'Şahların aynı sütunda, aralarında çift sayıda kare varken karşı karşıya gelmesi',
          'Şahların yan yana durması',
          'Rakip şahın kenardan uzaklaşması',
        ],
        correctIndex: 0,
        explanation:
            'Şahlar aynı sütunda 3, 5 kare gibi aralıklarla dururken de muhalefet vardır; buna uzak muhalefet denir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a5',
    level: ChessLessonLevel.ileri,
    title: 'Plan yapma',
    summary: 'Pozisyonu değerlendirip plan kurmak',
    steps: [
      LessonInfoStep(
        text:
            'Plansız oynamak, sürekli tepki vermektir. Pozisyonu şu sırayla değerlendir: '
            '1) Materyal (kim önde?), 2) Şah güvenliği, 3) Merkez ve alan, 4) Taşların aktifliği, '
            '5) Piyon yapısı. En zayıf noktayı bul, planını ona göre kur.',
      ),
      LessonQuizStep(
        question: 'Bir taş üstünlüğün varsa genel plan ne olmalı?',
        options: [
          'Takas yapıp pozisyonu sadeleştirmek',
          'Rastgele saldırmak',
          'Şahı merkeze çıkarmak',
        ],
        correctIndex: 0,
        explanation:
            'Öndeysen takaslar rakibin karşı oyununu azaltır ve üstünlüğün daha da büyür.',
      ),
      LessonQuizStep(
        question: 'Rakibin şahı rok yapmamış ve merkez açıksa ne yapmak mantıklıdır?',
        options: [
          'Hızla saldırıya geçmek',
          'Piyon hamleleri yapıp beklemek',
          'Vezirleri takas etmek',
        ],
        correctIndex: 0,
        explanation:
            'Merkezde açıkta kalan bir şah, taşlar hızla geliştirilirse ciddi tehdit altına girer.',
      ),
      LessonInfoStep(
        fen: '4k3/1p4p1/8/8/2P1P3/2N5/8/4K3 w - - 0 1',
        highlights: ['c3', 'd5'],
        text:
            'Örnek plan: zayıf kareyi (d5) ele geçir. Rakibin b ve g piyonları dışında piyonu yok; d5 '
            'karesini hiçbir piyon vuramaz. Atını oraya yerleştir.',
      ),
      LessonMoveStep(
        fen: '4k3/1p4p1/8/8/2P1P3/2N5/8/4K3 w - - 0 1',
        prompt: 'Atı d5 üssüne yerleştir.',
        accepted: ['c3d5'],
        success:
            'İşte plan: at kalıcı bir üste oturdu ve merkezdeki piyonların onu koruyor.',
        wrong: 'At c3\'ten d5\'e gidebilir.',
      ),
    ],
  ),
];
