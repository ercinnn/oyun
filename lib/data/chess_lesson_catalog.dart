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

  ChessLesson(
    id: 'b7',
    level: ChessLessonLevel.baslangic,
    title: 'Notasyon okumayı öğren',
    summary: 'Hamle yazımı: e4, Af3, x, +, # ve rok',
    steps: [
      LessonInfoStep(
        fen: _start,
        text:
            'Satranç hamleleri kısa bir yazıyla kaydedilir; buna notasyon denir. Oyundaki hamle '
            'geçmişi paneli de bu yazıyı kullanır. Piyon hamlesinde yalnızca varış karesi yazılır: '
            '"e4" demek piyon e4 karesine gitti demektir.',
      ),
      LessonInfoStep(
        text:
            'Diğer taşlar harfle başlar: Ş = şah, V = vezir, K = kale, F = fil, A = at. '
            '"Af3" at f3 karesine gitti, "Fc4" fil c4 karesine gitti demektir.',
      ),
      LessonInfoStep(
        text:
            'Özel işaretler: x = taş aldı ("Axd5" at d5\'teki taşı aldı), + = şah, # = mat, '
            '0-0 = kısa rok, 0-0-0 = uzun rok, =V = piyon vezire terfi etti ("e8=V").',
      ),
      LessonQuizStep(
        question: '"Af3" hamlesinde hangi taş oynadı?',
        options: ['At', 'Fil', 'Kale'],
        correctIndex: 0,
        explanation: 'A harfi attır. f3 de gittiği karedir.',
      ),
      LessonQuizStep(
        question: '"Fxc6+" ne anlama gelir?',
        options: [
          'Fil c6\'daki taşı aldı ve şah çekti',
          'Fil c6\'ya gitti ve mat etti',
          'Fil c6\'ya gitti, hiçbir şey olmadı',
        ],
        correctIndex: 0,
        explanation: 'x yeme, + şah demektir. Mat olsaydı # yazılırdı.',
      ),
      LessonMoveStep(
        fen: _afterE4E5,
        prompt: 'Notasyondaki "Af3" hamlesini yap.',
        accepted: ['g1f3'],
        highlights: ['g1'],
        success: 'Doğru. A = at, f3 = hedef kare.',
        wrong: 'Af3 demek g1\'deki atı f3 karesine oynamak demektir.',
      ),
      LessonMoveStep(
        fen: _afterE4E5,
        prompt: 'Şimdi "Fc4" hamlesini yap.',
        accepted: ['f1c4'],
        highlights: ['f1'],
        success: 'Güzel. F = fil, c4 = hedef kare.',
        wrong: 'Fc4 demek f1\'deki fili c4 karesine oynamak demektir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b8',
    level: ChessLessonLevel.baslangic,
    title: 'Vezir ve kale ile mat',
    summary: 'Tek taşın şahla birlikte mat etmesi ve pattan kaçınma',
    steps: [
      LessonInfoStep(
        text:
            'Vezir ya da kale, kendi şahının yardımıyla rakip şahı mat edebilir. Fikir şudur: '
            'kendi şahın rakip şahın kaçış karelerini kapatır, taşın ise şah çeker.',
      ),
      LessonInfoStep(
        fen: '7k/8/6K1/8/8/8/Q7/8 w - - 0 1',
        highlights: ['g6', 'a2'],
        text:
            'Beyaz şah g6\'da h7 ve g7 karelerini kapatıyor. Geriye g8 kaçış karesi kalıyor; '
            'vezir son sıraya gelirse hem şah çeker hem g8\'i kapatır.',
      ),
      LessonMoveStep(
        fen: '7k/8/6K1/8/8/8/Q7/8 w - - 0 1',
        prompt: 'Vezirle mat yap.',
        anyMate: true,
        success: 'Va8 mat! Şah çekiliyor, g7 ve h7 beyaz şah tarafından kapalı.',
        wrong: 'Bu mat değil. Vezir son sıraya (8. sıra) gitmeli.',
      ),
      LessonInfoStep(
        fen: 'k7/8/1K6/8/8/8/8/7R w - - 0 1',
        highlights: ['b6', 'h1'],
        text:
            'Kale de aynı işi yapar. Beyaz şah b6\'da a7 ve b7 karelerini kapatıyor. Kale son sıraya '
            'giderse b8 de kapanır.',
      ),
      LessonMoveStep(
        fen: 'k7/8/1K6/8/8/8/8/7R w - - 0 1',
        prompt: 'Kaleyle mat yap.',
        anyMate: true,
        success: 'Kh8 mat! Kale son sırayı, şah da diğer kareleri kapattı.',
        wrong: 'Kale h1\'den h8\'e gidince son sıradaki şahı mat eder.',
      ),
      LessonMoveStep(
        fen: 'k7/8/1K6/8/8/8/8/6Q1 w - - 0 1',
        prompt: 'Dikkat: rakip şaha hiç hamle bırakmadan (pat) beraberlik olur. Pat olmadan mat yap.',
        anyMate: true,
        success: 'Vg8 mat. Şah çekildi, kaçış karesi kalmadığı için mat oldu, pat değil.',
        wrong: 'Bu mat değil. Vezir g8\'e giderse son sırayı kapatıp şah çeker.',
      ),
      LessonQuizStep(
        question: 'Şah çekilmiyor ama rakibin hiç yasal hamlesi de yoksa sonuç ne olur?',
        options: ['Mat, sen kazanırsın', 'Pat, oyun berabere biter', 'Oyun devam eder'],
        correctIndex: 1,
        explanation:
            'Buna pat denir ve beraberliktir. Üstün olduğunda rakip şaha bir kaçış karesi bırakmayı unutma.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b9',
    level: ChessLessonLevel.baslangic,
    title: 'Şahı korumak',
    summary: 'Şah çekilince üç savunma: kaç, araya gir, yakala',
    steps: [
      LessonInfoStep(
        text:
            'Şahın tehdit altındaysa (şah çekildiyse) hemen bir şey yapmak zorundasın. '
            'Üç yol var: 1) Şahı kaçırmak, 2) Araya bir taş koymak, 3) Şah çeken taşı almak. '
            'Hiçbiri mümkün değilse oyun mattır.',
      ),
      LessonMoveStep(
        fen: '4r2k/8/8/8/8/8/8/4K3 w - - 0 1',
        prompt: 'Siyah kale şah çekiyor. Şahını güvenli bir kareye kaçır.',
        accepted: ['e1d1', 'e1f1', 'e1d2', 'e1f2'],
        highlights: ['e8'],
        success: 'Şah e-sütunundan çıktı, artık kale onu vuramaz.',
        wrong: 'Şahı e-sütunundan çıkar: d ya da f sütunundaki bir kareye git.',
      ),
      LessonMoveStep(
        fen: '4r2k/8/8/8/8/8/2B5/4K3 w - - 0 1',
        prompt: 'Şahı kaçırmak yerine, filini kale ile şahın arasına koy.',
        accepted: ['c2e4'],
        highlights: ['e8', 'e1'],
        success: 'Fil e4\'e girdi ve şah çekmeyi kesti. Buna araya girme denir.',
        wrong: 'Fil c2\'den e4\'e gidebilir: e4, kale ile şahın arasında kalır.',
      ),
      LessonMoveStep(
        fen: '4r2k/8/8/1B6/8/8/8/4K3 w - - 0 1',
        prompt: 'Bu sefer şah çeken kaleyi filinle al.',
        accepted: ['b5e8'],
        highlights: ['e8', 'b5'],
        success: 'Fil e8\'i aldı. Tehdit ortadan kalktı, üstelik bir kale kazandın.',
        wrong: 'Fil b5\'ten e8\'e uzanıyor (c6, d7 boş). Kaleyi almak için o kareye git.',
      ),
      LessonQuizStep(
        question: 'İki taş aynı anda şah çekerse (çifte şah) hangi savunma işe yarar?',
        options: [
          'Yalnızca şahı kaçırmak',
          'Araya taş koymak',
          'Şah çeken taşlardan birini almak',
        ],
        correctIndex: 0,
        explanation:
            'İki taşı aynı anda durduramazsın, bu yüzden şahı kaçırmaktan başka çare yoktur.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b10',
    level: ChessLessonLevel.baslangic,
    title: 'Bir maçın akışı',
    summary: 'Açılış, oyun ortası ve son oyun',
    steps: [
      LessonInfoStep(
        text:
            'Bir satranç oyunu üç bölümden oluşur: açılış, oyun ortası ve son oyun. '
            'Bölümler arasında keskin bir çizgi yoktur, ama her birinin farklı bir hedefi vardır.',
      ),
      LessonInfoStep(
        fen: _afterE4E5,
        text:
            'Açılış: taşlarını çıkar, merkezi tut, şahını rok ile güvenceye al. '
            'Bu aşamada hedef, taşlarını hızla ve uyumlu şekilde geliştirmektir.',
      ),
      LessonInfoStep(
        text:
            'Oyun ortası: taşlar aktif olduğunda plan kurma zamanı. Taktikler yakala, rakibin zayıf '
            'noktalarına saldır, kendi şahını güvende tut. Çoğu oyun burada karar verilir.',
      ),
      LessonInfoStep(
        text:
            'Son oyun: tahtada az taş kalır. Şah artık güvenli değil, aksine güçlü bir savaşçıdır. '
            'Geçer piyonlar önem kazanır ve piyonun vezire terfi etmesi için yarış başlar.',
      ),
      LessonQuizStep(
        question: 'Açılışın temel hedefi hangisidir?',
        options: [
          'Vezirle erken saldırmak',
          'Taşları geliştirip şahı güvenceye almak',
          'Bütün piyonları ilerletmek',
        ],
        correctIndex: 1,
        explanation: 'Geliştirilmiş taşlar ve güvenli bir şah, sonraki bölümler için temeldir.',
      ),
      LessonQuizStep(
        question: 'Şah hangi bölümde aktif bir savaşçıya dönüşür?',
        options: ['Açılış', 'Oyun ortası', 'Son oyun'],
        correctIndex: 2,
        explanation:
            'Vezirler gidince tehlike azalır; şah merkeze çıkıp piyonları desteklemelidir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b11',
    level: ChessLessonLevel.baslangic,
    title: 'Piyon hamleleri ayrıntılı',
    summary: 'İlk hamlede iki kare, çapraz yeme ve terfi',
    steps: [
      LessonInfoStep(
        text:
            'Piyon en küçük taştır ama kuralları en çoktur. İleri gider, geri gidemez. Normalde bir kare '
            'ilerler; yalnızca başlangıç karesindeyse iki kare ilerleyebilir. Taş alırken ise düz '
            'değil çapraz (bir kare ileri ve yan) gider.',
      ),
      LessonMarkStep(
        fen: _start,
        prompt: 'e2 piyonunun gidebileceği tüm kareleri işaretle.',
        pieceSquare: 'e2',
        success: 'Doğru: başlangıç karesindeki piyon e3 ve e4\'e gidebilir.',
      ),
      LessonMarkStep(
        fen: '4k3/8/8/3p1p2/4P3/8/8/4K3 w - - 0 1',
        prompt: 'e4 piyonunun tüm hamlelerini işaretle (ileri gitme ve taş alma dahil).',
        pieceSquare: 'e4',
        success: 'Piyon e5\'e ilerleyebilir, d5 ve f5\'teki taşları da çapraz alabilir.',
      ),
      LessonMoveStep(
        fen: '4k3/8/8/3p1p2/4P3/8/8/4K3 w - - 0 1',
        prompt: 'Piyonunla d5\'teki siyah piyonu al.',
        accepted: ['e4d5'],
        highlights: ['d5'],
        success: 'Piyon çapraz giderek taşı aldı. Piyon yalnızca çapraz alır, düz almaz.',
        wrong: 'e4 piyonu bir kare çapraz ileri, d5\'e gidince taşı alır.',
      ),
      LessonMoveStep(
        fen: '6k1/4P3/8/8/8/8/8/4K3 w - - 0 1',
        prompt: 'Piyonunu son sıraya ulaştırıp terfi ettir.',
        accepted: ['e7e8'],
        highlights: ['e8'],
        success:
            'Piyon son sıraya ulaşınca vezir, kale, fil ya da ata dönüşür; çoğunlukla vezir seçilir. Burada '
            'yeni vezir şah da çekiyor!',
        wrong: 'e7 piyonunu bir kare ilerlet: e8 son sıradır.',
      ),
      LessonQuizStep(
        question: 'Piyon taş alırken nasıl hareket eder?',
        options: ['Çapraz, bir kare ileri', 'Düz ileri', 'Yandan'],
        correctIndex: 0,
        explanation: 'Piyon düz ilerler ama çapraz alır; bu, onu diğer taşlardan ayıran özelliktir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b12',
    level: ChessLessonLevel.baslangic,
    title: 'Merkezi kontrol',
    summary: 'd4, e4, d5, e5 neden önemli',
    steps: [
      LessonInfoStep(
        fen: _start,
        highlights: ['d4', 'e4', 'd5', 'e5'],
        text:
            'Tahtanın ortasındaki dört kare (d4, e4, d5, e5) merkezdir. Merkezdeki taş daha çok kareye '
            'ulaşır; ayrıca iki kanada da hızla yardıma koşabilir.',
      ),
      LessonMoveStep(
        fen: _start,
        prompt: 'Merkez karesine bir piyon sür (e4 ya da d4).',
        accepted: ['e2e4', 'd2d4'],
        success: 'Merkeze bir piyon koydun. Piyonlar merkezde durunca taşlarını da geliştirmek kolaylaşır.',
        wrong: 'e2 ya da d2 piyonunu iki kare ilerlet.',
      ),
      LessonMoveStep(
        fen: _afterE4E5,
        prompt: 'Şimdi bir atını geliştir ve merkeze baskı yap (Af3 ya da Ac3).',
        accepted: ['g1f3', 'b1c3'],
        success: 'Atlar merkeze bakınca en güçlüdür. Kenarda bir at ise az kareyi kontrol eder.',
        wrong: 'g1 atını f3\'e ya da b1 atını c3\'e oynayabilirsin.',
      ),
      LessonQuizStep(
        question: 'Aşağıdakilerden hangisi merkez karesi değildir?',
        options: ['e4', 'd5', 'a3'],
        correctIndex: 2,
        explanation: 'a3 bir kenar karesidir. Merkez kareleri d4, e4, d5 ve e5\'tir.',
      ),
      LessonQuizStep(
        question: 'Kenardaki at neden zayıftır?',
        options: [
          'Merkezdekine göre daha az kareyi kontrol eder',
          'Kurallara göre hareket edemez',
          'Kolayca alınır',
        ],
        correctIndex: 0,
        explanation:
            'Merkezdeki at 8 kareye, köşedeki at yalnızca 2 kareye gidebilir. Bu yüzden "kenardaki at kederdir" denir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b13',
    level: ChessLessonLevel.baslangic,
    title: 'Taşları korumak',
    summary: 'Korumasız taş ve savunmayı kurmak',
    steps: [
      LessonInfoStep(
        text:
            'Bir taşın yanında onu koruyan başka bir taş yoksa o taş asılıdır: rakip onu alırsa '
            'karşılığında bir şey alamazsın. Korunan taşı alan kişi ise kendi taşını kaybeder.',
      ),
      LessonMoveStep(
        fen: '4k3/8/8/8/3q4/2N5/8/R3K3 w - - 0 1',
        prompt: 'Siyah vezir c3 atına saldırıyor ve at korunmuyor. Atı koru (kaleyle).',
        accepted: ['a1a3', 'a1c1'],
        highlights: ['c3'],
        success:
            'Kale atı koruyor. Artık Vxc3 dese de Kxc3 ile veziri alırsın, bu yüzden siyah almaz.',
        wrong: 'Kaleyi c3\'ü koruyacak bir kareye götür: a3 (yatay) ya da c1 (dikey).',
      ),
      LessonQuizStep(
        question: 'Korunan bir taşı almak neden çoğunlukla kötüdür?',
        options: [
          'Alan taş karşılıkta yenir',
          'Kurallara aykırıdır',
          'Sıra kaybedilir',
        ],
        correctIndex: 0,
        explanation:
            'Alan taş, koruyan taş tarafından hemen alınır. Böylece yalnızca değer kaybedilir (takas hesabı önemlidir).',
      ),
      LessonQuizStep(
        question: 'Hamleden önce kendine sorman gereken soru hangisidir?',
        options: [
          'Taşlarımın hangisi korumasız?',
          'Rakip ne kadar hızlı oynuyor?',
          'Hangi renk daha iyi?',
        ],
        correctIndex: 0,
        explanation: 'Korumasız taşlarını düzenli kontrol etmek, sık yapılan en büyük hatadan seni korur.',
      ),
    ],
  ),
  ChessLesson(
    id: 'b14',
    level: ChessLessonLevel.baslangic,
    title: 'Rok adım adım',
    summary: 'Kısa rok, uzun rok ve rok yasakları',
    steps: [
      LessonInfoStep(
        fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
        text:
            'Rok, şahı güvene alıp kaleyi oyuna sokan tek hamledir. Şah iki kare kaleye doğru gider, '
            'kale de şahın diğer yanına atlar. Kısa rok (0-0) h kalesiyle, uzun rok (0-0-0) a kalesiyle yapılır.',
      ),
      LessonMoveStep(
        fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
        prompt: 'Kısa rok yap: şahı e1\'den g1\'e götür.',
        accepted: ['e1g1'],
        highlights: ['e1', 'h1'],
        success: 'Kısa rok tamam: şah g1\'de, kale f1\'e geçti.',
        wrong: 'Şahı e1\'den iki kare sağa, g1\'e götür.',
      ),
      LessonMoveStep(
        fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
        prompt: 'Bu sefer uzun rok yap: şahı e1\'den c1\'e götür.',
        accepted: ['e1c1'],
        highlights: ['e1', 'a1'],
        success: 'Uzun rok tamam: şah c1\'de, kale d1\'e geçti.',
        wrong: 'Şahı e1\'den iki kare sola, c1\'e götür.',
      ),
      LessonInfoStep(
        text:
            'Rok için şartlar: şah ve o kale daha önce hiç oynamamış olmalı; ikisinin arasında taş '
            'olmamalı; şah şu anda şah altında olmamalı; şahın geçtiği ve indiği kareler rakip tarafından '
            'saldırı altında olmamalı.',
      ),
      LessonQuizStep(
        fen: '4k3/8/8/8/8/8/5r2/R3K2R w KQ - 0 1',
        question: 'Siyah kale f2\'de. Beyaz kısa rok yapabilir mi?',
        options: [
          'Hayır, şahın geçeceği f1 karesi saldırı altında',
          'Evet, şah şu an şah altında değil',
          'Evet, kaleler yerinde',
        ],
        correctIndex: 0,
        explanation:
            'Şah f1\'den geçerken saldırı altında kalır. Bu yüzden kısa rok yasaktır. (Uzun rok hâlâ mümkündür.)',
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

  ChessLesson(
    id: 'o6',
    level: ChessLessonLevel.orta,
    title: 'Çatal ve çivileme ayrıntıları',
    summary: 'Piyon çatalı, çivilenmiş taşa saldırmak',
    steps: [
      LessonInfoStep(
        text:
            'Çatalı yalnızca at yapmaz; piyon, fil, kale ve vezir de yapabilir. Piyon çatalı özellikle '
            'tatlıdır, çünkü en ucuz taşla iki değerli taşa birden saldırırsın.',
      ),
      LessonMoveStep(
        fen: '4k3/8/8/2r1r3/8/3P4/8/6K1 w - - 0 1',
        prompt: 'Piyonunu öyle bir kareye it ki iki kaleye birden saldırsın.',
        accepted: ['d3d4'],
        highlights: ['c5', 'e5'],
        success: 'd4 piyonu hem c5 hem e5 kalesine saldırıyor. Biri kurtulsa da diğerini alırsın.',
        wrong: 'd3 piyonunu bir kare ilerlet: d4\'ten c5 ve e5 karelerini vurur.',
      ),
      LessonInfoStep(
        text:
            'Çivilenmiş bir taş hareket edemez (ya da edemeyecek kadar tehlikelidir). Bu yüzden '
            'çivilenmiş taşa saldırmak çok etkilidir: kaçamaz, ancak korunabilir.',
      ),
      LessonMoveStep(
        fen: '4k3/8/2n5/1B6/3P4/8/8/6K1 w - - 0 1',
        prompt: 'c6\'daki at, şahına karşı çivili. Piyonla ona saldır.',
        accepted: ['d4d5'],
        highlights: ['c6', 'b5'],
        success:
            'd5 piyonu atı vuruyor. At çivili olduğu için kaçamaz; siyah şahı kaçırsa bile at alınır.',
        wrong: 'd4 piyonunu d5\'e it: oradan c6 atına saldırır.',
      ),
      LessonQuizStep(
        question: 'Çivilenmiş bir taşa saldırmanın avantajı nedir?',
        options: [
          'Taş kaçamaz, korunması gerekir',
          'Taş otomatik olarak silinir',
          'Rakip bir hamle atlamak zorunda kalır',
        ],
        correctIndex: 0,
        explanation:
            'Taş yerinden oynayamadığı için yalnızca korunabilir; korunmuyorsa kaybedilir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o7',
    level: ChessLessonLevel.orta,
    title: 'Keşif atağı ve çifte şah',
    summary: 'Bir hamlede iki tehdit yaratmak',
    steps: [
      LessonInfoStep(
        text:
            'Keşif atağında bir taşı yerinden oynatınca arkasındaki uzun menzilli taşın (kale, fil, '
            'vezir) hattı açılır. Açılan hat şah çekiyorsa buna keşif şahı denir.',
      ),
      LessonMoveStep(
        fen: '4k3/1q6/8/8/4B3/8/8/4RK2 w - - 0 1',
        prompt: 'Filinle veziri al: kale de keşifle şah çeker.',
        accepted: ['e4b7'],
        highlights: ['e4', 'e1', 'e8'],
        success: 'Fil vezirin yerinde ve kale şah çekiyor. Siyah vezirini kurtaramadı.',
        wrong: 'Fil e4\'ten b7\'deki veziri alabilir; kale de şahı vurur.',
      ),
      LessonInfoStep(
        text:
            'Çifte şah: hareket eden taş şah çekerken, açılan hat da şah çeker. Aynı anda iki taş şah çektiği için '
            'rakibin tek çaresi şahı kaçırmaktır.',
      ),
      LessonMoveStep(
        fen: '4k3/8/8/8/4N3/8/8/4RK2 w - - 0 1',
        prompt: 'Atı öyle oyna ki hem at hem kale şah çeksin (çifte şah).',
        accepted: ['e4f6', 'e4d6'],
        highlights: ['e8'],
        success: 'Çifte şah! At e8\'i vuruyor, e-sütunu da kale için açıldı.',
        wrong: 'At f6 ya da d6 karesine gitsin: oradan e8\'e saldırır ve kale de açılır.',
      ),
      LessonQuizStep(
        question: 'Çifte şahta rakip nasıl kurtulabilir?',
        options: [
          'Yalnızca şahını kaçırarak',
          'Araya taş koyarak',
          'Şah çeken taşlardan birini alarak',
        ],
        correctIndex: 0,
        explanation:
            'İki taşı aynı anda etkisiz hale getiremezsin; tek çare şahı kaçırmaktır.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o8',
    level: ChessLessonLevel.orta,
    title: 'Kale ve piyon son oyunu',
    summary: 'Kaleyi geçer piyonun arkasına koymak',
    steps: [
      LessonInfoStep(
        text:
            'Kale son oyunları en sık görülen son oyunlardır. Tek bir ilkeyi öğrensen çok işine yarar: '
            '"Kaleler geçer piyonun arkasında durur." Kendi piyonunun arkasında kale onu iter, '
            'rakip piyonun arkasında ise onu durdurur.',
      ),
      LessonMoveStep(
        fen: '4k3/8/8/P7/8/8/3K4/7R w - - 0 1',
        prompt: 'Kaleni a-sütununda, piyonunun arkasına yerleştir.',
        accepted: ['h1a1'],
        highlights: ['a5'],
        success: 'Kale a1\'de. Piyon ilerledikçe kale onu arkadan destekler.',
        wrong: 'Kaleyi h1\'den a1\'e götür: piyonun (a5) tam arkası.',
      ),
      LessonQuizStep(
        question: 'Rakibin geçer piyonunu durdurmak için kaleni nereye koyarsın?',
        options: [
          'Piyonun arkasına',
          'Piyonun önüne',
          'Şahının yanına',
        ],
        correctIndex: 0,
        explanation:
            'Arkadan piyona saldırırsın; piyon ilerledikçe kaleden uzaklaşmaz, sen ise hep saldırıda kalırsın.',
      ),
      LessonInfoStep(
        text:
            'Bu konunun ünlü konumları var: Lucena (kazanan kurulum, "köprü kurmak") ve Philidor '
            '(beraberlik savunması, üçüncü sıra). İkisi de kale ve piyon son oyunlarının temelidir; '
            'Usta seviyesine çıktığında bunları ayrıca çalışırsın.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o9',
    level: ChessLessonLevel.orta,
    title: 'Açık hatlar ve 7. sıra',
    summary: 'Kaleleri aktif hatlara yerleştirmek',
    steps: [
      LessonInfoStep(
        text:
            'Kale kapalı sütunda hareketsizdir. Açık sütun (üzerinde hiç piyon olmayan sütun) '
            'kale için otoyoldur. Kalelerini açık sütunlara, hatta açık sütunları ele geçirmeye götür.',
      ),
      LessonMoveStep(
        fen: '6k1/pp3ppp/8/8/8/8/PP3PPP/R5K1 w - - 0 1',
        prompt: 'Kaleni açık bir sütuna (c, d ya da e) taşı.',
        accepted: ['a1c1', 'a1d1', 'a1e1'],
        success: 'Kale artık açık sütunda; oradan tahtanın derinliklerine inebilir.',
        wrong: 'c, d ve e sütunlarında hiç piyon yok. Kaleni oraya götür.',
      ),
      LessonInfoStep(
        text:
            '7. sıra: kalen rakibin 7. sırasına ulaşırsa (siyah için 2. sıra) orada çoğunlukla '
            'piyonlar ve şah sıkışmıştır. Kale hem piyonlara saldırır hem şahı hapseder.',
      ),
      LessonMoveStep(
        fen: '6k1/pp3ppp/8/8/8/8/PP3PPP/3R2K1 w - - 0 1',
        prompt: 'Kaleni rakibin 7. sırasına çıkar.',
        accepted: ['d1d7'],
        highlights: ['b7', 'f7'],
        success: 'Kale d7\'de b7 ve f7 piyonlarına birden saldırıyor. Rakip hepsini koruyamaz.',
        wrong: 'Açık d-sütununda ilerle ve 7. sıraya çık.',
      ),
      LessonQuizStep(
        question: 'Açık sütun nedir?',
        options: [
          'Üzerinde hiç piyon olmayan sütun',
          'Kalenin durduğu sütun',
          'Şahın önündeki sütun',
        ],
        correctIndex: 0,
        explanation:
            'Piyonsuz sütunda kale engelsiz ilerler; bu yüzden onları ele geçirmek önemlidir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o10',
    level: ChessLessonLevel.orta,
    title: 'Tehdit fark etme rutini',
    summary: 'Her hamleden önce rakibin niyetini kontrol et',
    steps: [
      LessonInfoStep(
        text:
            'Çoğu oyun, "Rakibim ne yapmak istiyor?" sorusunu sormadığı için kaybedilir. Hamle yapmadan '
            'önce şu kısa listeyi uygula: 1) Rakip son hamlesiyle neyi tehdit ediyor? '
            '2) Taşlarımdan biri saldırı altında mı ya da korumasız mı? 3) Benim hamlem yeni bir '
            'açık yaratıyor mu?',
      ),
      LessonQuizStep(
        fen: '4k3/8/8/8/2n5/8/3Q4/4K3 w - - 0 1',
        question: 'Siyah at c4\'e geldi. Ne tehdit ediyor?',
        options: [
          'Beyaz vezire saldırıyor',
          'Beyaz şaha şah çekiyor',
          'Hiçbir şeye saldırmıyor',
        ],
        correctIndex: 0,
        explanation: 'c4 atı d2\'yi vurur. Bunu görmeden başka bir hamle yaparsan veziri kaybedersin.',
      ),
      LessonQuizStep(
        fen: '3r2k1/5ppp/8/8/8/8/5PPP/6K1 w - - 0 1',
        question: 'Siyah kale d8\'de. Beyaz hamle yapmazsa siyahın tehdidi nedir?',
        options: [
          'Kd1 ile son sıra matı',
          'Piyon almak',
          'Şahı kovalamak',
        ],
        correctIndex: 0,
        explanation:
            'Şahın önü kendi piyonlarıyla kapalı olduğu için d1\'e inen kale mat eder. '
            'Şahına bir kaçış karesi (h2 ya da g2 piyonunu ilerleterek) açman gerekir.',
      ),
      LessonQuizStep(
        question: 'Hamle yapmadan önce sormanız gereken ilk soru nedir?',
        options: [
          'Rakip ne tehdit ediyor?',
          'Hangi piyonu ilerleteyim?',
          'Vezirimi nereye çıkarayım?',
        ],
        correctIndex: 0,
        explanation:
            'Tehdidi görmek, en iyi hamleyi aramaktan önce gelir; çünkü kaybettiğin materyal geri gelmez.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o11',
    level: ChessLessonLevel.orta,
    title: 'Popüler açılışlar',
    summary: 'İtalyan, İspanyol, Sicilya ve Vezir gambiti',
    steps: [
      LessonInfoStep(
        text:
            'Açılışların isimleri vardır; bunlar yüzlerce yıllık deneyimin kısa özetleridir. '
            'Ezber yapmana gerek yok, fikirlerini anlaman yeter. Dört yaygın açılışa bakalım.',
      ),
      LessonInfoStep(
        fen: _afterE4E5,
        text:
            'İtalyan oyunu: 1.e4 e5 2.Af3 Ac6 3.Fc4. Fil c4\'e çıkıp f7 karesine baskı kurar; '
            'merkez ve hızlı gelişme hedeflenir.',
      ),
      LessonMoveStep(
        fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
        prompt: 'İtalyan oyunu: filini c4\'e çıkar.',
        accepted: ['f1c4'],
        success: 'İşte İtalyan oyunu. Fil f7 karesini hedef alıyor.',
        wrong: 'Fili f1\'den c4\'e çıkar.',
      ),
      LessonMoveStep(
        fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
        prompt: 'İspanyol oyunu: filini bu sefer b5\'e çıkar.',
        accepted: ['f1b5'],
        success: 'İspanyol (Ruy Lopez): fil c6 atına baskı yapıyor. Yüzlerce yıldır oynanan bir klasik.',
        wrong: 'Fili f1\'den b5\'e çıkar: c6 atına saldırır.',
      ),
      LessonMoveStep(
        fen: 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        prompt: 'Sicilya savunması: siyah 1...c5 oynadı. Atını f3\'e çıkar.',
        accepted: ['g1f3'],
        success:
            'Sicilya, siyahın en sert karşılıklarından biri; c5 ile merkezde asimetri yaratır.',
        wrong: 'Atı g1\'den f3\'e çıkar.',
      ),
      LessonMoveStep(
        fen: 'rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w KQkq - 0 2',
        prompt: 'Vezir gambiti: c-piyonunu c4\'e oynayıp merkez piyonuna baskı yap.',
        accepted: ['c2c4'],
        success:
            'Vezir gambiti: beyaz bir piyon önerir, ama siyah alırsa genelde beyaz merkezi ele geçirir.',
        wrong: 'c2 piyonunu c4\'e götür.',
      ),
      LessonQuizStep(
        question: 'İtalyan oyununda fil hangi kareyi hedef alır?',
        options: ['f7', 'a7', 'h8'],
        correctIndex: 0,
        explanation:
            'c4 fili f7 piyonuna doğru çaprazı izler; başlangıçta o kare yalnızca şahla korunur.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o12',
    level: ChessLessonLevel.orta,
    title: 'Vezir taktikleri',
    summary: 'Vezir çatalı ve vezirle mat',
    steps: [
      LessonInfoStep(
        text:
            'Vezir en güçlü taştır (9 puan) ve düz ile çapraz aynı anda saldırır. Bu yüzden çatal için '
            'en uygun taşlardan biridir. Ama veziri erken oynatırsan rakibin gelişen taşlarıyla kovalanırsın.',
      ),
      LessonMoveStep(
        fen: '6k1/8/8/n7/8/8/8/3Q2K1 w - - 0 1',
        prompt: 'Veziri öyle bir kareye oyna ki hem şah çeksin hem a5 atına saldırsın.',
        accepted: ['d1d5'],
        highlights: ['a5', 'g8'],
        success:
            'Vd5: çaprazda şah çekiyor, yatayda a5 atına saldırıyor. Şah kaçınca atı alırsın.',
        wrong: 'd5 karesine bak: g8 ile a5 oradan görünüyor.',
      ),
      LessonMoveStep(
        fen: '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1',
        prompt: 'Şahının desteğiyle vezirle mat et.',
        anyMate: true,
        success:
            'Vg7 mat! Vezir şahın (f6) koruması altında; h8 şahının h7 ve g8 kaçış karesi yok.',
        wrong: 'Vezir g7\'ye gitmeli: şahın onu koruyor.',
      ),
      LessonQuizStep(
        question: 'Vezirle çatal yaparken hangi tehlikeye dikkat edersin?',
        options: [
          'Vezirin saldırdığı taş vezire karşılık verebilir mi?',
          'Vezir yavaş hareket eder',
          'Vezir geri gidemez',
        ],
        correctIndex: 0,
        explanation:
            'Vezir bir kaleye kendi hattında saldırırsa kale de vezire saldırır. O yüzden çatal, karşılık veremeyen taşlara yapılır.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o13',
    level: ChessLessonLevel.orta,
    title: 'Fil ve at son oyunları',
    summary: 'Hangi az taşla mat edilir, hangisiyle edilmez',
    steps: [
      LessonInfoStep(
        fen: '4k3/8/8/8/8/8/8/2B1K3 w - - 0 1',
        text:
            'Yalnızca bir fil (ya da bir at) ile şah, rakibin çıplak şahını mat edemez: bu beraberliktir. '
            'Oyun da bunu otomatik olarak beraberlik sayar. Mat için daha fazla materyal gerekir.',
      ),
      LessonInfoStep(
        text:
            'Yeterli olanlar: iki fil (zıt renkli karelerde) ile mat mümkündür. Fil ile at birlikte de '
            'mümkündür ama daha zordur. İki at ise rakip hata yapmadıkça mat edemez. Bu yüzden '
            'materyal değişimlerini bilerek yap.',
      ),
      LessonQuizStep(
        question: 'Şah + tek fil, çıplak şaha karşı ne sonuç verir?',
        options: ['Beraberlik', 'Mat', 'Pat'],
        correctIndex: 0,
        explanation: 'Tek hafif taş mat için yetmez; oyun yetersiz materyalden berabere biter.',
      ),
      LessonQuizStep(
        question: 'Hangi ikili tek başına şahla mat edebilir?',
        options: ['İki fil', 'İki at', 'Bir at'],
        correctIndex: 0,
        explanation:
            'İki fil birbirini tamamlar. İki at ise zorunlu mat yapamaz; ancak rakip hata yaparsa olur.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o14',
    level: ChessLessonLevel.orta,
    title: 'Terfi ve geçer piyon',
    summary: 'Geçer piyon, kare kuralı ve terfi',
    steps: [
      LessonInfoStep(
        text:
            'Geçer piyon: önünde ve yan sütunlarında rakip piyon olmayan piyondur. Son sıraya kimse '
            'engel olamaz, bu yüzden çok değerlidir. "Geçer piyon kaçmalı" sözü buradan gelir.',
      ),
      LessonInfoStep(
        text:
            'Kare kuralı: piyonun terfi karesine kadar olan mesafeyi bir kenar kabul eden bir kare düşün. '
            'Rakip şah sırası ona gelince bu karenin içindeyse piyona yetişir, dışındaysa yetişemez.',
      ),
      LessonMoveStep(
        fen: '6k1/4P3/8/8/8/8/8/4K3 w - - 0 1',
        prompt: 'Geçer piyonu terfi ettir.',
        accepted: ['e7e8'],
        success: 'Yeni vezir e8\'de. Bir geçer piyon çoğu zaman oyunu bitirir.',
        wrong: 'Piyonu e8\'e it.',
      ),
      LessonQuizStep(
        question: 'Geçer piyon hangisidir?',
        options: [
          'Önünde ve yan sütunlarında rakip piyonu olmayan',
          'En çok ilerlemiş piyon',
          'Şahın önündeki piyon',
        ],
        correctIndex: 0,
        explanation:
            'Rakip piyonlar onu durduramaz; yalnızca taşlar ya da şah durdurabilir.',
      ),
      LessonQuizStep(
        question: 'Kare kuralı ne için kullanılır?',
        options: [
          'Rakip şahın piyona yetişip yetişemeyeceğini görmek için',
          'Filin çaprazını hesaplamak için',
          'Kaleyi terfi ettirmek için',
        ],
        correctIndex: 0,
        explanation:
            'Şah kareye sıra ona gelirken girebiliyorsa piyonu durdurur; giremiyorsa piyon terfi eder.',
      ),
    ],
  ),
  ChessLesson(
    id: 'o15',
    level: ChessLessonLevel.orta,
    title: 'Açılış tuzakları',
    summary: 'Çoban matı ve aptal matı',
    steps: [
      LessonInfoStep(
        text:
            'Bazı açılış hataları çok çabuk mata yol açar. Bunları tanırsan hem tuzağa düşmezsin hem de '
            'rakip acemiyse ilk hamlelerden avantaj alabilirsin. Ama sağlam oyuncuya karşı işe yaramaz; '
            'karşı taraf f7 karesini korursa saldırı boşa gider.',
      ),
      LessonInfoStep(
        fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
        highlights: ['f7'],
        text:
            'Çoban matı: 1.e4 e5 2.Fc4 Ac6 3.Vh5?! Af6?? Vezir ve fil f7\'yi birlikte hedef alıyor; siyah '
            'f7\'yi korumadı.',
      ),
      LessonMoveStep(
        fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
        prompt: 'Çoban matını tamamla.',
        anyMate: true,
        success: 'Vxf7 mat! Vezir fil tarafından korunuyor ve şahın kaçış karesi kalmadı.',
        wrong: 'f7 karesine bak: vezir orada fil desteğiyle mat eder.',
      ),
      LessonInfoStep(
        fen: 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2',
        highlights: ['g4', 'f3'],
        text:
            'Aptal matı: 1.f3 e5 2.g4 ve beyazın şah tarafı açıldı (f3, g4 piyonları e1-h4 çaprazını '
            'açtı). Siyah bu çaprazdan bir hamleyle mat eder. Şah tarafındaki piyonları gereksiz ilerletme.',
      ),
      LessonMoveStep(
        fen: 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2',
        prompt: 'Siyah olarak veziri h4\'e oynayıp mat et.',
        accepted: ['d8h4'],
        highlights: ['h4'],
        success: 'Vh4 mat! e1-h4 çaprazı açıktı ve beyazın hiçbir savunması yok.',
        wrong: 'Vezir d8\'den h4\'e çaprazda gider.',
      ),
      LessonQuizStep(
        question: 'Çoban matına karşı en basit savunma nedir?',
        options: [
          'f7 karesini korumak (örneğin Af6 yerine g6 ya da Vf6/Ah6)',
          'Şahı hemen kaçırmak',
          'Vezirle saldırmak',
        ],
        correctIndex: 0,
        explanation:
            'Tuzağın tamamı f7\'ye dayanır. Orayı korur ya da vezire tempoyla saldırırsan tehlike biter.',
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
  ChessLesson(
    id: 'a6',
    level: ChessLessonLevel.ileri,
    title: 'Feda taktikleri',
    summary: 'Materyali verip karşılığında daha fazlasını almak',
    steps: [
      LessonInfoStep(
        text:
            'Feda, materyal vererek daha değerli bir şey karşılığında kazanmaktır: mat, daha çok materyal, '
            'saldırı ya da üstün bir konum. Her feda kendine şu soruyu sordurmalı: "Karşılığında ne alıyorum?"',
      ),
      LessonInfoStep(
        text:
            'Yaygın fedalar: mat için vezir ya da kale fedası, şahın önündeki savunmayı kırmak için '
            'fil/at fedası, kalite fedası (kaleyi bir hafif taşla değiştirmek). Kalite fedası daha çok '
            'konumsal bir yatırımdır.',
      ),
      LessonMoveStep(
        fen: '3r2k1/5ppp/8/8/8/8/4QPPP/4R1K1 w - - 0 1',
        prompt: 'Veziri feda et: şah çekerek rakibi kaleyle almaya zorla, sonra kale mat eder.',
        accepted: ['e2e8'],
        highlights: ['e8'],
        success:
            'Ve8+! Siyahın tek cevabı Kxe8. Ardından Kxe8 mat: şahın önündeki piyonlar kaçışı kapatıyor.',
        wrong: 'Vezir e2\'den e8\'e gitsin ve şah çeksin; arkasındaki kale devam edecek.',
      ),
      LessonQuizStep(
        question: 'Bir fedayı yapmadan önce ilk sormanız gereken soru nedir?',
        options: [
          'Karşılığında ne alıyorum?',
          'Rakip kızar mı?',
          'Hangi taş daha güzel?',
        ],
        correctIndex: 0,
        explanation:
            'Feda ancak mat, daha çok materyal ya da net bir üstünlük getiriyorsa mantıklıdır.',
      ),
      LessonQuizStep(
        question: 'Kalite fedası nedir?',
        options: [
          'Kaleyi bir at ya da fille değiştirmek',
          'Veziri feda etmek',
          'Piyon vermek',
        ],
        correctIndex: 0,
        explanation:
            'Kalite (kale ile hafif taş farkı) verilir; karşılığında konum, piyon ya da saldırı beklenir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a7',
    level: ChessLessonLevel.ileri,
    title: 'Zayıf kareler ve ileri karakol',
    summary: 'Piyonla vurulamayan kareleri atlar için kullanmak',
    steps: [
      LessonInfoStep(
        text:
            'Piyonlar geri gidemez. Bir piyon ilerleyince arkasında bıraktığı kareleri artık koruyamaz; '
            'bu karelere zayıf kare denir. Hiçbir piyonla vurulamayan zayıf kareye yerleşen taşa '
            'ileri karakol (outpost) denir.',
      ),
      LessonInfoStep(
        fen: '6k1/pp3ppp/2p5/8/3P4/5N2/PP3PPP/6K1 w - - 0 1',
        highlights: ['e5', 'd4'],
        text:
            'Örnek: Siyahın d ve e sütununda piyonu yok, yani hiçbir siyah piyon e5\'i vuramaz. '
            'Beyazın d4 piyonu ise e5\'i destekler. Atın için harika bir karakol.',
      ),
      LessonMoveStep(
        fen: '6k1/pp3ppp/2p5/8/3P4/5N2/PP3PPP/6K1 w - - 0 1',
        prompt: 'Atı e5 karakoluna yerleştir.',
        accepted: ['f3e5'],
        success: 'At e5\'te, d4 piyonu tarafından korunuyor ve hiçbir siyah piyon onu kovamaz.',
        wrong: 'At f3\'ten e5\'e gidebilir.',
      ),
      LessonQuizStep(
        question: 'İyi bir ileri karakolun iki şartı nedir?',
        options: [
          'Rakip piyonlarla vurulamaz ve kendi piyonunla korunur',
          'Tahtanın kenarındadır',
          'Şahın yanındadır',
        ],
        correctIndex: 0,
        explanation:
            'Piyonla atılamayan ve korunan bir taş, sonsuza dek rakibi rahatsız eder.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a8',
    level: ChessLessonLevel.ileri,
    title: 'Fil çifti ve at-fil dengesi',
    summary: 'Hangi hafif taş hangi pozisyonda daha iyi',
    steps: [
      LessonInfoStep(
        text:
            'Fil ve at yaklaşık aynı değerdedir (3 puan), ama farklı türde pozisyonlarda üstün gelir. '
            'Fil uzun çaprazlarda, at ise kapalı pozisyonlarda ve karakollarda güçlüdür.',
      ),
      LessonInfoStep(
        text:
            'Fil çifti: iki fili birlikte tutmak, birlikte iki rengi de kapsadığı için çoğunlukla bir '
            'avantajdır. Özellikle açık pozisyonlarda iki fil birbirini tamamlar.',
      ),
      LessonQuizStep(
        question: 'Pozisyon açık ve kalabalık değilse hangi taş genellikle daha güçlüdür?',
        options: ['Fil', 'At', 'İkisi de aynı'],
        correctIndex: 0,
        explanation:
            'Fil uzun menzilli olduğu için açık tahtada tüm çaprazlara hâkim olur; at ise yavaş kalır.',
      ),
      LessonQuizStep(
        question: 'Kapalı, piyonların kilitlendiği pozisyonda hangi taş genellikle daha uygundur?',
        options: ['At', 'Fil', 'Vezir'],
        correctIndex: 0,
        explanation:
            'At piyonların üstünden atlar; fil kendi piyonlarının arkasında hapsolabilir.',
      ),
      LessonQuizStep(
        question: 'Fil çiftinin avantajı ne zaman en çok işe yarar?',
        options: [
          'Pozisyon açıldığında',
          'Tahta kilitlendiğinde',
          'Vezirler kalmadığında',
        ],
        correctIndex: 0,
        explanation: 'Açık hatlarda iki fil, iki rengin karelerini birlikte kontrol eder.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a9',
    level: ChessLessonLevel.ileri,
    title: 'Savunma teknikleri',
    summary: 'Pat, sürekli şah ve kaybedilmiş pozisyonu kurtarmak',
    steps: [
      LessonInfoStep(
        text:
            'Kötü durumda pes etmek yerine kurtuluş yollarını ara. İki klasik resurs vardır: '
            'pat (rakip şaha hiç yasal hamle kalmaması) ve sürekli şah (rakibi aynı şahları tekrar '
            'etmeye zorlamak).',
      ),
      LessonInfoStep(
        fen: '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
        text:
            'Bu pozisyon patın klasik örneği: siyah şahın hiç yasal hamlesi yok, ama şah çekilmiyor. '
            'Oyun berabere biter. Üstün taraf, bu tuzağa düşmemeye dikkat etmeli.',
      ),
      LessonMoveStep(
        fen: 'k7/8/1K6/8/8/8/8/6Q1 w - - 0 1',
        prompt: 'Üstün taraf olarak pattan kaçın ve mat et.',
        anyMate: true,
        success: 'Vg8 mat. Kaçış karesi bırakmadan şah çektin.',
        wrong: 'Mat değil. Vezir g8\'e giderse son sırayı kapatıp şah çeker.',
      ),
      LessonQuizStep(
        question: 'Sürekli şah nedir?',
        options: [
          'Rakibi sürekli şah çekerek aynı konumları tekrarlamaya zorlamak',
          'Şahı tahtanın ortasına götürmek',
          'Hep aynı taşla oynamak',
        ],
        correctIndex: 0,
        explanation:
            'Şahtan kaçamayan taraf aynı konumları tekrarlar ve üç kere tekrar olunca oyun berabere biter.',
      ),
      LessonQuizStep(
        question: 'Kötü durumdayken pat seni nasıl kurtarabilir?',
        options: [
          'Rakibin şahını hamlesiz bırakıp beraberlik almak',
          'Şahını kaçırmak',
          'Vezirle mat etmek',
        ],
        correctIndex: 0,
        explanation:
            'Üstün taraf dikkatsiz olursa patla oyun berabere biter; savunan taraf bunu hedefleyebilir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a10',
    level: ChessLessonLevel.ileri,
    title: 'Zaman ve tempo',
    summary: 'Gelişme önceliği, tempo kazanmak ve saat yönetimi',
    steps: [
      LessonInfoStep(
        text:
            'Tempo, satrançta bir hamlelik zaman demektir. Hamleyi boşa harcamak (aynı taşı iki kez '
            'oynatmak, gereksiz piyon hamlesi) tempo kaybıdır; rakibi bir tehdide yanıt vermeye '
            'zorlayarak gelişmek ise tempo kazandırır.',
      ),
      LessonMoveStep(
        fen: '4k3/8/8/3q4/8/8/8/1N2K3 w - - 0 1',
        prompt: 'Atını geliştirirken aynı anda vezire de saldır.',
        accepted: ['b1c3'],
        highlights: ['d5'],
        success: 'At c3 hem gelişti hem vezire saldırdı: siyah vezirini oynatmak zorunda, sen tempo kazandın.',
        wrong: 'At b1\'den c3\'e gidebilir: oradan d5\'e saldırır.',
      ),
      LessonInfoStep(
        text:
            'Saat de bir kaynaktır. Oyunda 5, 10 ya da 30 dakikalık süreli seçeneklerini kullanabilirsin. '
            'Kolay hamlelere hızlı, kritik pozisyonlara uzun düşün; her hamleye eşit süre harcama.',
      ),
      LessonQuizStep(
        question: 'Açılışta aynı taşı iki kez oynatmak neden çoğunlukla kötüdür?',
        options: [
          'Tempo kaybettirir, geliştirme gecikir',
          'Kural dışıdır',
          'Rakibi kızdırır',
        ],
        correctIndex: 0,
        explanation:
            'Açılışta her hamle yeni bir taşı geliştirmeli; aynı taşı tekrar oynatmak rakibe bir hamle hediye eder.',
      ),
      LessonQuizStep(
        question: 'Süreli oyunda zaman yönetimi için en iyi ilke hangisidir?',
        options: [
          'Basit hamlelere hızlı, kritik anlara uzun düşünmek',
          'Her hamleye aynı süre harcamak',
          'Hep çok hızlı oynamak',
        ],
        correctIndex: 0,
        explanation: 'Süreni önemli kararlara sakla; rutin hamlelerde vakit kaybetme.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a11',
    level: ChessLessonLevel.ileri,
    title: 'Ünlü oyundan ders: Opera Oyunu',
    summary: 'Morphy\'nin 1858\'deki gelişme ve saldırı klasiği',
    steps: [
      LessonInfoStep(
        text:
            'Paul Morphy, 1858\'de Paris Operası\'nda oynanan bir gösteri oyununda Dük Karl ve Kont Isouard '
            'ile oynadı. Oyun, "hızlı gelişme + açık hatlar + doğrudan saldırı" ilkesinin sahne örneği '
            'olarak bilinir. Morphy siyah taşlarla değil beyazla oynadı.',
      ),
      LessonInfoStep(
        text:
            'Hamleler: 1.e4 e5 2.Af3 d6 3.d4 Fg4 4.dxe5 Fxf3 5.Vxf3 dxe5 6.Fc4 Af6 7.Vb3 Ve7 8.Ac3 c6 '
            '9.Fg5 b5 10.Axb5 cxb5 11.Fxb5+ Abd7 12.0-0-0 Kd8 13.Kxd7 Kxd7 14.Kd1 Ve6 15.Fxd7+ Axd7 '
            '16.Vb8+ Axb8 17.Kd8#. Son bölümü tahtada birlikte oynayalım.',
      ),
      LessonMoveStep(
        fen: '4kb1r/p2n1ppp/4q3/4p1B1/4P3/1Q6/PPP2PPP/2KR4 w - - 0 16',
        prompt: 'Morphy\'nin şaşırtıcı vezir fedasını oyna: veziri b8\'e sür.',
        accepted: ['b3b8'],
        highlights: ['b8'],
        success: 'Vb8+! Siyah vezirini alan atı b8\'e çekmek zorunda; bu, mat için son kareyi boşaltıyor.',
        wrong: 'Vezir b3\'ten b8\'e gitsin ve şah çeksin.',
      ),
      LessonMoveStep(
        fen: '1n2kb1r/p4ppp/4q3/4p1B1/4P3/8/PPP2PPP/2KR4 w - - 0 17',
        prompt: 'Şimdi kaleyle oyunu bitir.',
        anyMate: true,
        success: 'Kd8 mat! d8\'deki kale g5 filiyle korunuyor, siyah şahın kaçacağı yer yok.',
        wrong: 'd-sütunu artık açık. Kaleyi d8\'e götür.',
      ),
      LessonQuizStep(
        question: 'Morphy\'nin bu oyundan en çok öğrettiği ilke hangisidir?',
        options: [
          'Hızlı gelişme ve açık hatlar üstünlük getirir',
          'Vezir erken çıkarılmalıdır',
          'Piyonlar asla ilerlememelidir',
        ],
        correctIndex: 0,
        explanation:
            'Morphy taşlarını hızla geliştirdi, rakibin gelişmemiş taşlarına karşı açık hatlardan saldırdı.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a12',
    level: ChessLessonLevel.ileri,
    title: 'Geri kalmış piyon ve piyon zinciri',
    summary: 'Piyon yapısının ikinci bölümü',
    steps: [
      LessonInfoStep(
        text:
            'Geri kalmış piyon: yanındaki piyonlar ilerlemiş, kendisi ise rakip piyon tarafından '
            'vurulduğu için ilerleyemeyen ve arkadan korunamayan piyondur. Önündeki kare de genellikle '
            'rakibin ileri karakolu olur.',
      ),
      LessonInfoStep(
        fen: '4k3/8/4p3/3pP3/3P4/8/8/4K3 w - - 0 1',
        highlights: ['d4', 'e5', 'd5', 'e6'],
        text:
            'Piyon zinciri: çapraz dizilmiş piyonlar birbirini korur. Burada beyazın zinciri d4-e5, '
            'siyahınki d5-e6. Zincire saldırmak için tabanı (en arkadaki piyonu) hedef alırsın; taban '
            'düşerse diğerleri de düşer.',
      ),
      LessonQuizStep(
        question: 'Piyon zincirine hangi noktadan saldırmak en etkilidir?',
        options: ['Tabanından', 'Uç piyondan', 'Ortasından'],
        correctIndex: 0,
        explanation:
            'Tabandaki piyon başkalarını korur ama kendisi korunmaz. Onu almak tüm zinciri zayıflatır.',
      ),
      LessonQuizStep(
        question: 'Geri kalmış piyon neden bir zayıflıktır?',
        options: [
          'Korunması zor ve önü rakip taşlara açık kalır',
          'Geri gidebilir',
          'Vezire terfi edemez',
        ],
        correctIndex: 0,
        explanation:
            'Yanındaki piyonlar önde olduğu için ona destek kalmaz. Rakip onu hedef alır ve önüne taş yerleştirir.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a13',
    level: ChessLessonLevel.ileri,
    title: 'Karşı oyun ve inisiyatif',
    summary: 'Savunmadan saldırıya geçmek',
    steps: [
      LessonInfoStep(
        text:
            'İnisiyatif, tehdit yaratan ve rakibi cevap vermeye zorlayan tarafın elindedir. İnisiyatifi '
            'kaybedince yalnızca savunma yaparsın; ama bazen en iyi savunma, rakibin planını durdurmak '
            'yerine kendi karşı oyununu başlatmaktır.',
      ),
      LessonInfoStep(
        text:
            'Karşı oyun için rakibin zayıf noktasına hızlı bir tehdit bulman gerekir: açılmış bir sütun, '
            'korumasız bir taş ya da rakibin şahına açılan bir hat. Farklı kanatlara rok yapıldıysa '
            'iki taraf da piyon hücumuyla birbirinin şahına yönelir; burada hız her şeydir.',
      ),
      LessonQuizStep(
        question: 'Rakip şah tarafına saldırıyorsa ve sen savunmada zorlanıyorsan en iyi plan hangisi olabilir?',
        options: [
          'Karşı oyunla rakibin zayıf noktasında tehdit yaratmak',
          'Sadece piyon hamleleri yapmak',
          'Vezirini kaçırmak',
        ],
        correctIndex: 0,
        explanation:
            'Rakibi kendi savunmasıyla uğraştırırsan hücumu yavaşlar. Yine de kendi şahını ihmal etme.',
      ),
      LessonQuizStep(
        question: 'İnisiyatif nedir?',
        options: [
          'Tehdit yaratıp rakibi cevap vermeye zorlamak',
          'İlk hamleyi yapmak',
          'En çok taşa sahip olmak',
        ],
        correctIndex: 0,
        explanation: 'İnisiyatifi elinde tutan oyunun akışını belirler.',
      ),
      LessonQuizStep(
        question: 'Zıt kanatlara rok yapıldığında genel olarak ne olur?',
        options: [
          'İki taraf da piyonlarla birbirinin şahına saldırır ve hız önem kazanır',
          'Oyun otomatik berabere biter',
          'Vezirler alınır',
        ],
        correctIndex: 0,
        explanation:
            'Şahlar farklı yönlerde olduğu için piyonlar ilerleyebilir; kazanan çoğunlukla daha hızlı saldıran olur.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a14',
    level: ChessLessonLevel.ileri,
    title: 'Vezir son oyunları',
    summary: 'Vezir ve piyon, sürekli şah',
    steps: [
      LessonInfoStep(
        text:
            'Vezirli son oyunlar tehlikelidir çünkü vezir hem saldırı hem de sürekli şah için çok güçlüdür. '
            'Vezirin üstünlüğü olsa bile rakip şahın etrafında dolaşan bir vezir, sürekli şahla beraberlik '
            'alabilir. Bu yüzden önde olan taraf, kendi şahını rakip vezirin şahlarından korumalıdır.',
      ),
      LessonInfoStep(
        text:
            'Vezir, 7. sıradaki tek piyona karşı genellikle kazanır; ancak kenar piyonlarında (a ve h) '
            'rakip şahın konumuna göre pat tuzakları beraberlik getirebilir. Bu ayrıntı, ileri seviyede '
            'ayrıca çalışılır.',
      ),
      LessonQuizStep(
        question: 'Vezirli son oyunlarda üstün taraf en çok neyden korkmalıdır?',
        options: [
          'Sürekli şahtan beraberlik almaktan',
          'Piyonların terfi etmesinden',
          'Kale takasından',
        ],
        correctIndex: 0,
        explanation:
            'Şahı korumasız kalan taraf, rakip vezirin sonsuz şahlarıyla kazanmış oyunu beraberliğe çevirebilir.',
      ),
      LessonQuizStep(
        question: 'Şahını rakip vezirin şahlarından korumak için ne yapabilirsin?',
        options: [
          'Şahı piyonların ya da kendi taşlarının arkasına saklamak',
          'Şahı tahtanın ortasına çıkarmak',
          'Hiçbir şey yapmamak',
        ],
        correctIndex: 0,
        explanation: 'Şah çeken vezire karşı araya girebilecek taşların ve piyonların arkasında güvende olur.',
      ),
    ],
  ),
  ChessLesson(
    id: 'a15',
    level: ChessLessonLevel.ileri,
    title: 'Kendi oyununu analiz etme',
    summary: 'Hataları bulmak ve ders çıkarmak',
    steps: [
      LessonInfoStep(
        text:
            'Gelişmenin en hızlı yolu oynadığın oyunları incelemektir. Oyun bittikten sonra hamle geçmişine '
            'bak ve şu soruyu sor: "Nerede oyunun yönü değişti?" Çoğu zaman tek bir hamle ya da kaçırılmış '
            'bir tehdit karar verir.',
      ),
      LessonInfoStep(
        text:
            'Hata türleri: 1) Taktik gözden kaçırma (asılı taş, çatal), 2) Plansızlık, 3) Açılış '
            'ilkelerini unutmak, 4) Son oyun bilgisi eksikliği, 5) Süre yönetimi. Hangi türü sık '
            'yaptığını bul ve o konuya çalış.',
      ),
      LessonQuizStep(
        question: 'Oyun sonrası analizde ilk sorulması gereken soru hangisidir?',
        options: [
          'Oyunun yönü nerede değişti?',
          'Rakip kaç yaşında?',
          'Hangi açılışı en çok seviyorum?',
        ],
        correctIndex: 0,
        explanation:
            'Kritik anı bulmak, aynı hatayı tekrar etmemeni sağlar; her hamleyi incelemek zorunda değilsin.',
      ),
      LessonQuizStep(
        question: 'Hataları sınıflandırmanın faydası nedir?',
        options: [
          'Sık yaptığın hata türüne odaklanıp o konuya çalışabilirsin',
          'Rakibi suçlayabilirsin',
          'Oyun daha çabuk biter',
        ],
        correctIndex: 0,
        explanation:
            'Aynı türden hatalar tekrar ediyorsa, çalışmanı ona göre planlaman en verimli yoldur.',
      ),
    ],
  ),
];
