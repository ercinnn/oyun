# CLAUDE.md

Bu dosya Claude Code'a bu depoda çalışırken yol gösterir. Kısa tutulmuştur: ayrıntı koddaki yorumlarda ve testlerde; burada yalnızca **koddan kolayca çıkarılamayan** kararlar ve tuzaklar var.

## Komutlar

```bash
flutter pub get
flutter analyze                 # temiz olmadan iş bitmiş sayılmaz (varsayılan flutter_lints)
flutter test                    # test/widget_test.dart + bilim insanı başına test/<ad>_test.dart
flutter test test/widget_test.dart --plain-name "Hitting a bomb"
flutter run -d chrome
flutter run -d web-server --web-port=<port> --web-hostname=localhost   # -d chrome açılmazsa
flutter run -d windows
dart run tool/generate_sounds.dart        # assets/sounds/{bomb,win}.wav'ı yeniden üretir
dart run tool/preview_town_sounds.dart    # kasaba kliplerini build/town_sounds/ altına WAV yazar (kulakla dinlemek için)
flutter run -d chrome -t lib/dev/town_3d_probe.dart        # girişi atlayıp 3B kasaba; ?look=fancy|dress|suit|hoodie
flutter run -d chrome -t lib/dev/scientist_3d_probe.dart   # ?who=arsimet|newton|galileo|tesla|curie|einstein|fleming&go=explore|tasks[&station=...]
flutter run -d emulator-5554 -t lib/dev/town_3d_probe.dart --dart-define=USE_3D=true   # Android'de 3B (flutter emulators --launch Pixel_5)
flutter build apk --release                           # 2B APK
flutter build apk --release --dart-define=USE_3D=true   # 3B APK
```

- **Native/web eklentili yeni bağımlılık** (ör. `flutter_tts`, `three_js`) sonrası `flutter run` tamamen durdurulup yeniden başlatılmalı; hot reload/restart eklenti kaydını yenilemez → çalışırken `MissingPluginException`. Çözüm kod değil, yeniden başlatma.
- **`errno = 10048` / "Failed to bind web development server"**: önceki oturumun `dartvm.exe`'si portu tutuyor. Port değiştirme, süreci öldür:
  ```powershell
  Get-NetTCPConnection -LocalPort <port> | Select-Object OwningProcess
  Stop-Process -Id <OwningProcess> -Force
  ```

## Mimari

Flutter **oyun platformu**, arka uç Supabase. `Navigator` tabanlı kabuk birbirinden bağımsız oyunları barındırır: Bombalı Sayılar, Kart Eşleştirme, Renk mi Kelime mi?, Dizi Hafızası, Diziler, Tepki Süresi, Simon Diyor ki, Kayan Yapboz, Satranç, Çarpım Bahçesi, Sudoku, Bitki Laboratuvarı, Elektrik Atölyesi, Renkli Kasaba, Bilim İnsanları. Durum yönetimi `provider` (`ChangeNotifier`), **oyun başına kapsamlı**; bilinçli istisnalar yalnızca platform kökündeki `ProfileController` ve `AuthController`.

### Yeni oyun eklemek

1. `games/<oyun>_game.dart`: `static const routeName` taşıyan kök widget + oyunun kendi `MultiProvider`'ı (route'a her girişte yeni controller, çıkışta dispose — oyunlar arası state sızmaz).
2. `main.dart`'ın `onGenerateRoute`'una case.
3. `screens/game_catalog_screen.dart`'taki `gameCatalog`'a `GameCatalogEntry`; `skills: GameSkillRatings(zeka, ingilizce, iq, hafiza, dikkat)` zorunlu (0-5). Dürüst puanla; 0'ı da göster. **Zeka ≠ Dikkat**: Zeka strateji/planlama, Dikkat odak/dürtü kontrolü (Stroop/Simon/Tepki Süresi Dikkat 5). Kartın "… ODAKLI" etiketi `dominantSkillLabel`'dan gelir ve aynı beş addan birini kullanır (eşanlamlı yok).
4. Kurulum ekranına `PlayerCountSelector` (1/2 kişi, varsayılan 2). 1 kişide ikinci isim alanı gizlenir, `startGame` tek elemanlı listeyle çağrılır; controller'lar zaten liste üzerinde genel olduğu için mantık değişmez. Yalnızca metin değişir: sonuç ekranında `ranked.length == 1` ise `'Tebrikler, <ad>!'`.
5. 1. oyuncu adı `initState`'te `context.read<ProfileController>().name`'den (boşsa `'1. Oyuncu'`), 2. oyuncu her zaman `'2. Oyuncu'`.

### Tekrarlayan kurallar (bütün oyunlar)

- **Faz makinesi**: her oyun kök widget'ında `phase` enum'una göre ekran seçer (`setup → playing → turnTransition → finished`). Oyun içinde isimli alt route yok; yeni ekran = yeni faz değeri. İstisnalar: Kart Eşleştirme ve Satranç'ta `turnTransition` yok (gizlenecek kişisel durum yok / her hamlede araya girmek oyunu böler).
- **Gecikmeli geri çağrılar** (`Future.delayed`) her zaman `_generation` sayacıyla korunur (`startGame`/`restart` artırır), gerekiyorsa `_resolving` ile. Tamamen senkron controller'larda (Kayan Yapboz, Sudoku, Çarpım Bahçesi, Bitki Laboratuvarı, Elektrik Atölyesi, bilim insanları, satranç dersleri) gerek yok — **bunları zamanlayıcıya çevirme**; açıklama panelini okumak çocuğun zamanıdır.
- **Tur sayısı sabitleri benzersiz adlı olmalı** (`roundsPerPlayer`, `patternRoundsPerPlayer`, `reflexRoundsPerPlayer`, `simonRoundsPerPlayer`, `multiplicationRoundsPerPlayer`, `plantLabRoundsPerPlayer`, `electricRoundsPerPlayer`, `townRoundsPerPlayer`, `<ad>RoundsPerPlayer`…): `test/widget_test.dart` tüm controller'ları tek dosyada içe aktarır, aynı ad "ambiguous import" derleme hatası verir.
- **Seçenek sırası deneme başına bir kez karıştırılır** ve modelde saklanır (`StroopTrial.options`, `SimonTrial.boardOrder`); `build()` içinde karıştırma (yeniden çizimde düğmeler kayar, oyuncu konumu ezberler).
- **Türkçe üretilen metin**: değişken kelimeye ek getirilmez. Ya sabit kelime gramerini taşır (`"{ad} rengine dokun!"`) ya da cümle sahne başına elle yazılır, kod yalnızca sayı koyar. Dart'ın `toLowerCase()`'i I→ı bilmez; küçük harfli hâl elle yazılır (`PlantFactor.lowerLabel`).
- **Enjekte edilebilir `Random`**: rastgelelik içeren controller/model'ler `Random` alır; testler tohum sabitler.
- **Testler controller alanlarını doğrudan atayabilir** (public alanlar bilerek): ör. Yapboz'da bir hamle kalmış tahta, Satranç'ta `ChessBoard.custom(...)`, Çarpım Bahçesi'nde `buildRows/buildColumns`.
- **Zaman ölçümü**: süre `Stopwatch` ile ölçülür (monoton), `DateTime.now()` yalnızca zaman damgası içindir. `Stopwatch`/`DateTime` `tester.pump()` ile ilerlemez; testler milisaniye değil durum geçişlerini doğrular. Test edilmesi gereken saatler tik sayacıyla yapılır (Satranç saati).
- **`pumpAndSettle` bitmeyen ekranlar**: süreli satranç, kasaba (sürekli `Ticker`), 3B görünümler → `tester.pump(Duration)`.
- **Taşma debug/testte sert hatadır**: `Row` içindeki metinler `Flexible`; dar ekran testleri oyuna geniş görünümde girip sonra `physicalSize`'ı daraltır (katalog 320 px'te zaten taşar).
- **Varsayılan entegrasyon yok**: `AppThemeController`/`SoundService`/`SpeechService`/`GameResultRepository` yalnızca Bombalı Sayılar'a (ve Kart Eşleştirme'de `SpeechService`) aittir; diğer oyunlara **yalnızca istenirse** eklenir. Satranç/kasaba/bilim insanlarının sesleri ayrı, kodla sentezlenen sistemlerdir (aşağıda).
- **Yan servisler oyunu asla bozmaz**: ses, konuşma, kayıt çağrıları try/catch veya `.catchError((_) {})` içinde.
- **Asset yok tercihi**: çizimler `CustomPainter`, sesler kodla sentezlenir; `pubspec.yaml`'a gereksiz asset ekleme. 3B modeller Blender betikleriyle üretilir (aşağıda).

### Platform kabuğu ve ana sayfa

- `MaterialApp.theme` sabit nötr (`Colors.indigo`). Kendi temasını isteyen oyun alt ağacını yerel `Theme(...)` ile sarar. `debugShowCheckedModeBanner: false` kozmetik (kullanıcı isteği).
- **Katalog (`GameCatalogScreen`) ve `LoginScreen` platformun tek koyu ekranlarıdır** (`theme/home_palette.dart`'ın `homeThemeData()`'sı yerel `Theme` ile; `MaterialApp.theme`'e taşıma, her oyunu boyar). İkisi aynı `HomeBackdrop`, `PlatformLogoMark` ve `platformStatChips()`'i kullanır; birini değiştirirsen diğerini aynı commit'te değiştir.
- Katalogda `AppBar` yok; kaydırılmayan `_TopBar` var. Profil düğmesi **yalnızca ikon** (+ `Tooltip`): adı `Text` olarak göstermek, üstte oyun açıkken `find.text('<ad>')`'ı iki kez eşleştirip testleri bozar.
- Kart ızgarası 1/2/3 sütun (720/1080 eşik), kart yüksekliği sabit `_cardHeight` (**258**). Karta satır/ikon eklersen yüksekliği artır, yoksa taşar. Izgara `shrinkWrap` + `NeverScrollableScrollPhysics` (tüm kartların kurulması testleri görünüm yüksekliğinden bağımsız kılar).
- Oyun rengini koyu zeminde kullanırken daima `homeAccentOf(color)`'dan geçir. `StarRating` kart başına 5 tane olmalı (testler `gameCatalog.length * 5` sayar).

### Profil ve kimlik doğrulama

- `ProfileController`: yalnızca `name`, `shared_preferences`'ta, kökte tek örnek. `main()` `load()`'ı `runApp`'ten önce bekler (kurulum ekranları ilk build'de adı görsün). Testlerde verilmezse boş isimli örnek kullanılır.
- `AuthController`: Supabase **Google OAuth**. `AuthGate` ('/' route) `isSignedIn`'e göre `LoginScreen` ya da katalog gösterir. Kimlik (Auth) ile oyundaki görünen ad (Profile) bilerek ayrı; `signOut` profile dokunmaz.
- `isSignedIn` bir `bool`'dur (testler gerçek `Session` kurmadan simüle eder). Test varsayılanı **giriş yapılmış**.
- **`signOut()` bilerek senkron**: `isSignedIn`'i hemen false yapar, Supabase çağrısını `unawaited` gönderir. Ağı beklemeye çevirme — testte `pumpAndSettle` sahte sunucuyu beklemediği için çıkış hiç olmamış gibi görünüyordu.
- Google sağlayıcısı Supabase panelinde elle kurulur; Client Secret'ı Claude **girmez**. OAuth istemcisi Google Cloud `oyun-platformu-506422`'de; Supabase projesi değişirse bu istemcinin redirect URI'lerine `https://<ref>.supabase.co/auth/v1/callback` eklenir (yeni istemci gerekmez).

### Supabase

- `data/game_result_repository.dart` arayüz; `SupabaseGameResultRepository` (`public.game_results`, şema + RLS `supabase/schema.sql`) Bombalı Sayılar'a bağlı. `InMemoryGameResultRepository` testler/denemeler için.
- `config/supabase_config.dart`'taki URL ve anon anahtarı **bilerek koda gömülü** (anon anahtar herkese açık tasarlanmıştır; güvenlik RLS'tedir). `Supabase.initialize(publishableKey: ...)` (`anonKey` değil) `main()`'de bir kez çağrılır.
- Testlerin `setUpAll`'ı `SharedPreferences.setMockInitialValues({})` + sahte proje (`https://test.supabase.co`) ile başlatır; hiçbir test gerçek veriye bakmaz. Kayıt hataları yutulur.
- Başka oyuna kalıcılık eklerken aynı deseni tekrarla (ikinci bir başlatma yolu açma).
- **Supabase paneli**: panel hesabı (`eylulsehacakaloglu@gmail.com`) Claude hesabından farklı. `claude-in-chrome` ile panele ancak kullanıcı paneli bağlı tarayıcıda açtığını açıkça söylerse girilir; aksi hâlde adımları kullanıcıya bırak. Sır hiçbir zaman panele yazılmaz.

## Oyunlar

### Bombalı Sayılar (kurallar tutarlı kalmalı)

- 5 sütun × 10 satır, 1-50. Her oyuncuya oyun başında **sabit** bomba düzeni (satır başına 2 bomba sütunu) — hafıza oyunudur, düzen hiç değişmez.
- `GameController.selectCell`: bomba `currentRow`'u 0'a çeker ve `attempts`'i artırır ama **sırayı devretmez**; sıra ancak 10 satır kesintisiz geçilince döner. Kazanan en az `attempts`.
- `streakClearedCols` yalnızca mevcut denemeyi tutar ve bombada silinir; arayüz önceki denemenin güvenli hücrelerini **asla** sızdırmamalı.
- Tema (`AppThemeController`, 5 hazır + 8 renklik özel palet) iki oyuncu için tektir, yalnızca bu oyuna aittir. Tema yalnızca **aktif** hücreye ve ızgaranın arkasındaki `Container`'a uygulanır; temizlenmiş (yeşil) / kilitli (gri) renkler durum bildirimi olduğu için sabittir.
- `widgets/number_grid.dart`: hücre boyu esas olarak yükseklik/10'dan, `[min, max]` ile sınırlı, genişlikle de kısıtlı; `GridView` değil elle `Column`/`Row`. Satır/sütun sayısı değişirse hesap burada.
- Ses: `SoundService` wav'ları `rootBundle` + **`BytesSource`** ile çalar (`AssetSource` web'de `/assets/assets/...` yolu yüzünden sessizce 404 verir). Tetikleyici `GameController`'dadır.

### Kart Eşleştirme

- 4×4 = 8 çift; eşleşme `symbol` ile, çiftin bir kartı Türkçe bir kartı İngilizce `label` taşır (yalnızca görsel). Kategori ekleme: enum + en az 8 girişli `_xxxNames` + `_namesFor` case'i + seçici segmenti.
- Eşleşmede sıra aynı oyuncuda (400 ms), eşleşmemede kartlar kapanır ve sıra geçer (850 ms). Kazanan en çok çift.
- Eşleşmiş karta dokunmak `pronounce` çağırır (`SpeechService`, `flutter_tts`). Çocuk sesi yerine **yüksek perde (1.4) + yavaş hız (0.42)** bilinçli: isimle ses seçmek platformlar arası kırılgan. Tüm TTS çağrıları try/catch içinde.
- Sabit kart arkası rengi bilinçli (tema entegrasyonu yok).

### Renk mi Kelime mi? (Stroop)

Kelime ile mürekkep rengi bağımsız; doğru cevap **mürekkep**. Düğmeler renk **adını** nötr siyah metinle gösterir, renkli daire değil (renk eşlemek adlandırmayı atlatır). 10 tur, 350 ms geri bildirim. Kazanan en çok doğru.

### Dizi Hafızası (Simon tipi)

Her oyuncuya **tek koşu**: dizi büyür, yanlış dokunuş turu bitirir, skor tamamlanan son uzunluk; `maxSequenceLength` 20. Oynatma ve bekleme `_generation`/`_resolving` korumalı, `inputLocked` bu sırada dokunmayı kapatır. Yalnızca yanlış dokunuş yanıp söner (doğru için ayrı flaş bilerek yok).

### Diziler (sayı örüntüsü)

- 5 terimin ilk 4'ü + "?", 4 seçenek. Sınıf adları İngilizce `Pattern*` (Türkçe vitrin, İngilizce kimlik).
- `PatternDifficulty` üç ayrı üretici: **Kolay** = bir çarpım tablosunun ardışık katları (Çarpım Bahçesi'ne gönderme, kurulumda görünür metinle açıklanır); **Orta** = zorluk öncesi davranışın birebir aynısı; **Zor** = daha geniş aritmetik + ters geometrik (bölen) dizi (artan geometriği `.reversed`). Tüm terimler pozitif.
- Çeldiriciler `spacing = |shown[1]-shown[0]|` ölçeğinde; pozitif olmayan, cevaba eşit ya da **ekranda zaten görünen** değer reddedilir. 8 tur.

### Tepki Süresi

5 tur; rastgele 1200-3500 ms sonra "ŞİMDİ!". Erken dokunuş 1000 ms ceza. Sinyal zamanlayıcısı `_generation` **ve** `roundState == waiting` ile korunur (erken dokunuş aynı nesilde olur). Testte: `startGame` sonrası hemen dokunmak her zaman erken başlangıçtır; 3500 ms pump her zaman `ready`'ye ulaşır. Kazanan en düşük ortalama.

### Simon Diyor ki

Stroop controller'ının kopyası. 4 sabit renk+şekil (`SimonTileId` enum). ~%70 "Simon dedi ki:" ile başlar; `respond(null)` = "Pas Geç". Her turda açık seçim zorunlu (zaman penceresi yok, çocuklara daha anlaşılır). Beceri puanı Stroop'la aynı.

### Kayan Yapboz

4×4, her oyuncuya ayrı tahta; aynı oyuncu çözene kadar oynar (Bombalı Sayılar şekli), tamamen senkron. Karıştırma çözülmüş hâlden 150 **yasal** kaydırma ile yapılır → her zaman çözülebilir (parite hesabı gerekmez; kablo bulmacası da bu tekniği kullanır). Kazanan en az hamle. Testler karıştırılmış tahtayı çözmez; bir hamle kalmış tahta atar.

### Satranç

Sıfırdan kural motoru + yapay zekâ (paket yok). Fazlar `setup → playing → finished`.

- **Tahta**: düz 64'lük liste. **`applyMove` her zaman yeni `ChessBoard` döndürür, `undoMove` yok** — geri alma hatalarının tüm sınıfını ortadan kaldırmak için; yasal hamle filtresi ve arama aynı yoldan geçer. Testler `ChessBoard.custom(...)`/`fromFen` ile pozisyon kurar.
- **Görünüm yönü**: iki kişilikte sırası gelen alta (her hamlede döner), bilgisayara karşı insan rengi sabit. Döndürme hücre sırasını değiştirerek yapılır, `Transform.rotate` değil (taşlar ters döner). Son hamle / şah vurgusu ve koordinatlar `displayOrder`'dan hesaplanır.
- **Yapay zekâ** (`services/chess_ai.dart`, saf Dart): negamax + alfa-beta + PST + MVV-LVA, **süre bütçeli yinelemeli derinleştirme**, tamamen senkron (web'de isolate güvenilmez; arama süresi = arayüz donması). Zorluk 1-5 derinlik, süre bütçesi ve hata olasılığını birlikte ayarlar (1-2'deki rastgele hamle bilinçli). Yavaşsa önce `ChessDifficulty` bütçelerini düşür.
- **`_makeAiMove`**: 150 ms gecikme ("düşünüyor" karesi çizilsin) + `chessAiThinkTime` (0,3-5 sn, pozisyon karmaşıklığına göre, arama süresi düşülür); `_generation` her beklemeden sonra kontrol edilir. Testler `ChessController.aiThinkTimeScale = 0` yapar.
- **Saat**: `Timer.periodic` ile tik çıkarma (test edilebilirlik için). `timeControl` varsayılanı **süresiz** — süreli oyunda `pumpAndSettle` bitmez. Süre biterse rakip kazanır.
- **Notasyon** hamle anında `_applyAndRecord`'da üretilir (önceki ve sonraki tahta gerekir), Türkçe harfler (Ş/V/K/F/A). Geçmiş paneli geniş ekranda yanda, dar ekranda altta; `jumpTo` ile kayar.
- **Değerlendirme çubuğu** statik değerlendirmenin lojistik dönüşümü, yalnızca hamlede yenilenir, tahtayla birlikte döner. **Alınan taşlar** `moveHistory`'den türetilir; "+N" standart değerlerle (`chessStandardPieceValues`, motorun centipawn tablosundan bilinçli olarak ayrı).
- **Kullanıcı isteğiyle ayarlı düzen (sorulmadan değiştirme)**: çerçeve 1 px, çubuk 22,5 px, çubuk-tahta boşluğu 1,2 px, taş ölçeği `_pieceScale = 0.84` (karenin oranı, sabit font boyu değil), çok ince taş kenarı.
- **Taşlar çizilir**: `ChessPieceGlyph` dolu glifi iki kez (kenar + dolgu) çizer. **Piyon vektör `CustomPainter`'dır**: `♟` Android'de renkli emoji fontuyla çizilip rengi yok sayıyordu; metne geri çevirme. Testler `find.text('♙')` değil `_findPiece` kullanır; terfi seçenekleri `ValueKey('promote_<type>')`.
- **Etkileşim** iki dokunuşlu `selectSquare`. Birden fazla hamle eşleşirse terfi diyaloğu (otomatik vezir yok). Rok hakkı kale kendi karesinde **alınınca** da düşer; rok geçiş karesi tehdit kontrolü ayrı. Beraberlik: 50 hamle, üç tekrar, temel yetersiz materyal (aynı renk fil vs fil bilerek yok). Sonuç `outcome` + `outcomeReason` (`rankedBy` yok).
- **Hamle sesi** (dosyasız): şah > yeme > normal. Ses bir **tariftir** (`chess_move_sound_recipe.dart`) ve **iki yerde** yorumlanır — web'de Web Audio grafiği, diğerlerinde saf Dart sentezleyici → WAV. Tarif değişirse ikisini de güncelle; web yolu VM'de test edilemez, kulakla dene. Çalınış başına ±%5 perde/kazanç. Zaman aşımı `Timer`'ı bilerek yok. Testler ses vermez.
- **Dersler** (44: 14/15/15): ayrı route, `data/chess_lesson_catalog.dart` saf veri (FEN, `'e2e4'`, `anyMate`), senkron `ChessLessonController`, ilerleme `shared_preferences`. Tahta `widgets/chess_board_view.dart`'ın ortak parçasıdır. Veri testi her FEN'i, her kabul edilen hamlenin yasallığını ve `anyMate` adımlarının çözülebilirliğini doğrular. Lucena/Philidor gibi kuramsal konular test edilemediği için bilerek yalnızca anlatım + quiz.

### Çarpım Bahçesi

- **Dizi (array) modeli**: deneme `rows`/`columns` ile tanımlı, cevap türetilir; `3 × 4` = "4'lük 3 satır". Tek turlar `array` (okuma, 4 seçenek), çift turlar `build` (ızgarayı kur); sıkı dönüşüm.
- **Açıklama paneli asıl üründür**: her cevaptan sonra tur ilerlemez, "Devam" beklenir → controller'da `Future.delayed` yok.
- `build`'de ters kurulum (4 × 3) **doğru** sayılır ve değişme özelliği öğretilir.
- Çeldiriciler pedagojik (±satır, ±sütun, `rows + columns`, ±1).
- ~30 **gerçek hayat sahnesi** (`MultiplicationContext`): cümleler sahne başına elle yazılır, yalnızca `{r}/{c}/{n}` yerine konur. `fixedColumns` dünyadan gelen sayı (bisiklet 2 teker), `buildPrompt == null` = yalnızca okuma turu. Sahne havuzu ve iki faktör tavanı (`arrayMaxFactor`/`buildMaxFactor`) zorluğa göre; seviyede yeni gelen sahneler çift ağırlıklı.
- `MultiplicationArrayView` üç yerde kullanılır; yan şeritler sayılmayan etiket hücreleridir ve boyut hesabında sanal satır/sütun kaplar. 12 × 12'nin 320 × 560'ta taşmadığını bir test sabitler. Veri testleri her zorlukta kullanılabilir sahne ve boş şablon olmamasını doğrular.

### Sudoku

Kayan Yapboz'un uyarlaması, senkron. Üretim: 3 köşegen kutu + MRV backtracking; aynı `_SudokuSolver` doldurma (`limit: 1`) ve benzersizlik sayımı (`limit: 2`) yapar, düğüm bütçeli. **Tuzak**: limite ulaşınca son hücreyi sıfırlamadan dön — sıfırlamak çözülmüş tahtayı geri sararken bozuyordu. İpucu çıkarma yalnızca benzersizlik korunursa kalıcı (hedef 40/32/26). `isSolved` = `values == solution`. İki adımlı giriş (hücre seç + rakam). 3 hata hakkı turu bitirir. Kazanan en az hata.

### Bitki Laboratuvarı (8-10 yaş, 28 bitki, 4 etken)

- Bilimsel yöntem + adil deney. Modlar: puanlı **Görevler** (8 tur: deney tahmini / bitki doktoru dönüşümlü) ve puansız **Serbest laboratuvar** (`freeLab` fazı).
- Model saf ve deterministik (`simulatePlant`): ışık/su/sıcaklık/yükseklik için 3 kademeli skor tablosu, `overall` = çarpım, belirti en zayıf etkenden. Birim **hafta** (0-10). Deney çiftlerinde boy farkı ≥ %12; doktor turunda tek bozuk etken.
- Sonuç paneli asıl üründür, kontrolcü senkron; zaman atlamalı animasyon sunum katmanında (sonlu).
- `data/plant_catalog.dart`: çilek, limon, karpuz, şeftali, muz, çay, kahve, buğday, pirinç **mutlaka** bulunmalı (test). Yeni bitki: her etkende tek 1.0 ve ≤ 0.5 bir kademe.

### Elektrik Atölyesi (8-10 yaş)

- Modlar: **Görevler** (10 tur, `roundsPlayed % 5` ile 5 tür, her türden 2 — tur sayısı 5'in katı), **Serbest Devre**, **Kablo Yolu Seviyeleri** (12). Senkron, sonuç paneli.
- Devre simülasyonu saf: 1,5 V pil, 3 V ampul, gerilim > 3,9 V ise patlar; seri/paralel farkları. Karşılaştırma sorularında parlaklık farkı ≥ 0,15.
- Kablo bulmacası: çözülmüş hâlden karıştırma, dokunuş saat yönünde, doğru = ideal + 4 hamle içinde. Seviye tohumu `Random(level * 7919)`.
- **Tuzak**: `WirePuzzleBoard` satırında `crossAxisAlignment: stretch` **ve** `CustomPaint(size: Size.infinite)` birlikte şart; yoksa karolar 0 yüksekliğe çöker. Test dokunuşun hamle saydığını doğrular.
- Güvenlik sahneleri yalnızca "yap / yapma" öğretir, taklit edilebilir deney tarifi yok.

### Renkli Kasaba (PK XD tarzı dünya)

- Fazlar: `setup → town → wardrobe/market/home/arcade → miniGame → turnTransition → finished`. Çevrimiçi/sosyal/gerçek para **yok**. İki giriş: serbest kasaba (kalıcı avatar) ve 1-2 kişilik **Mini Oyun Yarışı** (Engelli Parkur, Hazine Avı, Yıldız Yağmuru).
- Mantık (`models/town/`: `TownMap` ASCII, `IsoProjection`, `TownWorld` sabit adım + eksen ayrımlı çarpışma + BFS `walkTo`) görünümden bağımsız ve deterministik. Harita `data/town_map_data.dart`; test her kapı/altın/bayrağın erişilebilirliğini doğrular.
- **Sürekli kare döngüsü**: `IsoWorldView` `Ticker` → `tick(dt)`; dt 0,1 s'ye, dünya 0,05 s adımlara kısılır. Çizim `FrameNotifier` ile, ağaç yalnızca ayrık değişimlerde `notifyListeners`.
- Dokunma: `tapTarget` önce nesneye (altın, kapı, bina gövdesi) sonra zemin karesine çözer; kapının önündeyken tekrar dokunmak içeri sokar. Derinlik sıralaması `x + y`, bina için `x + y + h`.
- **Emoji tuzağı**: CanvasKit emoji fontunu geç yükler; önbelleğe alınan `TextPainter` □ gösterir. Tabelalar `Icons.*`, emoji önbelleksiz çizilir.
- Avatar/mağaza/oda: stil kimlikleri `shop_catalog.dart`'ta; mobilya çoklu alınır; halı gibi zemin eşyaları (`height < 0.1`) çakışma saymaz. Kalıcılık `shared_preferences` (`town_profile_v1`), controller varsayılanı bellek içi; bozuk kayıt varsayılana düşer.
- **Faz her zaman `_setPhase`'den değişir** (müzik faza bağlı).
- **Ses ve müzik** (`services/audio/`, `data/town_sound_clips.dart`): dosyasız, **tek yorumlayıcı** `renderClip` (saf Dart); platform katmanı yalnızca örnekleri çalar. Yeni ses = yalnızca tarif. Zarflar `durMs` içinde biter (dikişsiz döngü). Tetikleyiciler `TownController`'da, dünya saf kalır. Adım aralığı 1,15 kare (küçültürken dinle). Ses/müzik ayrı açma-kapama. Sesin kulağa nasıl geldiği test edilmez. Android'de henüz denenmedi.
- **Yol haritası** (2026-09-22): 1) günlük görevler, 3) Blender iskelet animasyonu (önce tek yürüme klibi + telefonda performans ölçümü), 4) diğer oyunlara açılan binalar, 5) Rive/Lottie arayüz animasyonları. 2) ses/müzik yapıldı. Her madde APK'da denenmeden bitmiş sayılmaz. Seçilmeyenler: Unity/Godot, Flame, yapay zekâyla model üretimi/dış varlık.

#### 3B görünüm (kasaba, oda, bilim insanları — `three_js`)

- `townUse3d` / `scientistsUse3d` = `kIsWeb || USE_3D`. Web'de varsayılan açık; Android'de `--dart-define=USE_3D=true` ile çalıştığı görüldü ama varsayılan değil; masaüstü denenmedi. VM testleri her zaman 2B yedeği kullanır. Kasabanın mini oyunları 2B'dir.
- **Web kurulumu**: `web/gles_bindings.js` `index.html`'de `flutter_bootstrap.js`'ten **önce** yüklenmeli (yoksa sonsuz yükleme); `flt-platform-view { pointer-events: none }` kuralı şart (yoksa dokunma gelmez). Girdi ham `Listener` ile alınır.
- **Android**: ekran boyutu 0'ken ThreeJS kurulmaz (`PlatformException(no texture width)`). **Renk sızması**: aynı programı paylaşan malzemeler birbirinin rengini alıyordu; çözüm her görünüme `customProgramCacheKey` (`isolateMaterialPrograms` / `material()` yeni malzemeyi hemen yalıtır). **Kaldırma**; sonradan eklenen malzemeleri de yalıt. Derleme CMake 3.31.4 ister, APK ~9 MB büyür.
- Ortak 3B matematiği `widgets/three_pick.dart`'ta (kamera tabanı, ışın, kutu kesişimi, yalıtma); üçüncü bir kopya açma. Kasabada girdi kamera açısı kadar döndürülür.
- Gölge: kasabada acne ayarları (2048, bias −0,0006, normalBias 0,03) var, ama web'de gölgenin fiilen hiç işlenmediği ölçüldü (kasaba ve oda) — gerileme değil. Açmak isteyen önce `Town3DView`'de tarayıcıda doğrulamalı.
- **Oda** (`Room3DView`, `IsoRoomView` ile aynı sözleşme): döndürme bilerek yok. Yeniden kurulumda yalnızca `Mesh` sarmalları atılır, geometri/malzeme **dispose edilmez** (GLB kopyaları paylaşır).
- **Görüntü oranı**: `Lab3DState` kutu oranını `LayoutBuilder`'dan okuyup `camera.aspect`'e yazar; `Town3DView`/`Room3DView`'de bu düzeltme henüz yok.
- Anahtarlı (`ValueKey`) bir animasyon widget'ı 3B görünümü sarmamalı; her denemede ThreeJS baştan kurulur.

#### Modeller (Blender)

- Binalar, karakter, mobilya ve laboratuvarlar `tool/blender/*.py` ile üretilen GLB'lerdir (`assets/models/`). Yükleyici ortak `widgets/glb_model_library.dart`; model yoksa ilkel şekle düşülür.
- **Karakter**: tek GLB'de tüm mağaza varyantları isimli gruplar (`hair_*`, `outfit_*`, `hat_*`, `acc_*`); seçilmeyenler kaldırılır, `Skin/Hair/Outfit…` malzemeleri yeni malzemeyle boyanır (adları değiştirme). Pivot animasyonu, iskelet yok. Yeni varyant: `shop_catalog.dart` + Blender betiği + `avatar_model.dart` kimlik kümesi + yedek `Avatar3D`. Blender `.001` numaralarını ekler; kod adı `.`'tan önceye bakarak arar.
- **Avatar gövdesi eklemlidir** (sevimli, büyük kafalı oran bilerek korundu; baş ve baş varyantları değişmedi): şekilli gövde (kalça/bel/göğüs, pantolonlu kıyafette kalça pantolon malzemesinde), konik uzuvlar (`capsule`/`ell`/`lathe_y`), dirsek ve diz çıkıntısı, diz kapağı, baldır, parmaklı el (iki boğumlu 4 parmak + başparmak), şekilli ayakkabı. Pivotlar: omuz `ArmL/R`, dirsek `ForearmL/R` (her kıyafet grubunda), kalça `LegL/R`, **diz `ShinL/R`** (bacağın tek çocuğu; kıyafetin dizden aşağısı `outfit_x@shinL` grubunda). `AvatarModel.update` yürürken dizi bacak öne salınırken büker (negatif x = baldır geriye). Parçalar her grubun içinde malzeme başına birleştirilir (`merge_by_material`, ad `grup_Malzeme`, `.` yerine `_` ki `ForearmL.001` aramasıyla karışmasın). Yedek `Avatar3D`'de dirsek/diz yoktur (yalnızca model yüklenemezse kullanılır).
- **Mobilya**: `furniture.glb` + `assets/thumbs/<id>.png`. Yeni eşya: katalog + `build_*` + `FOOTPRINTS` → `build_all()` → `show_all()` → dışa aktar → `render_thumbs`. Testler grubun varlığını ve katalog boyutuna sığdığını doğrular (GLB JSON'u saf Dart'la okunur).
- Koordinatlar: three `(x, y, z)` → Blender `(x, -z, y)`; bina/mobilya ön yüzü three'de +z.

### Bilim İnsanları (7 bilim insanı, 3B)

Kaynak kökteki `bilim-insanlari.jpg` (3/A posteri). `ScientistsGame` yalnızca seçim ekranıdır; her bilim insanı **ayrı route + kendi controller**. `Scientist.routeName == null` → "Yakında".

**Ortak iskelet (genişlet, kopyalama):**
- `ScientistGameController<T extends ScienceTask>` oyuncu/tur/`answer → showingResult → continueAfterResult`/keşif akışını yönetir, senkron. Alt sınıf `roundsPerPlayer`, `generateTask`, `planForPlayer`, `resetExplore` verir. Doğru cevap her zaman modelden hesaplanır.
- Ekranlar ortak (`ScientistGameRoot<C>` + `ScientistGameConfig`); ortak anahtarlar `scientistStart`, `scientistExplore`, `scientistOption_<i>`, `scientistContinue`, `scientistExplanation`, `scientistScene`. Ad rozeti sahnenin sol üstünde (`ScientistIdentity` → `ScientistNameBadge`).
- 3B: `Lab3DState`'i genişlet (`buildWorld`/`syncWorld`/`animateWorld`); `material()` dışında kurulan malzemeleri `isolate(...)` et. Görünüm saf `…Scene` verisine yumuşakça ilerler; 2B yedek sonlu `TweenAnimationBuilder`'larla (testler yalnızca 2B'yi çalıştırır).
- Ses: dosyasız `renderClip`, `playSound(...)`; tek tercih anahtarı `scientists_sound_on`. Android'de denenmedi.
- **Görev metni**: `ScienceTask`'ın isteğe bağlı alanları: `ask` (kısa soru, büyük gösterilir; `prompt` yalnızca bağlamı anlatır ve `?` ile bitmez), `takeaway` ("Öğrendik" satırı), `optionEmojis`. (Ad `question` değil: Newton görevlerinde o ad soru türü alanı.) Bir test, her bilim insanının her görevinde `ask`/`takeaway` bulunduğunu doğrular.
- **Görev paneli** (`scientist_task_screen.dart`): tur noktaları (`ScientistPlayerState.results`, `widgets/science_lab/scientist_progress.dart`), "Tahmin et → Deneyi izle → Öğren" şeridi, A/B/C harfli büyük seçenek kartları. Cevaptan sonra seçenekler yerinde kalır (doğru ✓, yanlış ✗) ve sonuç kartı kendini görünür alana kaydırır.
- **Sahne etiketleri** (`widgets/science_lab/lab_labels.dart`): `LabLabel` (`tag` = A/B dairesi, `name`, `value`). 3B'de alt sınıf `Lab3DState.labels`'ı doldurur (`anchor`/`anchorAt`); etiketler her karede izdüşürülüp yalnızca `LabLabelLayer` yeniden çizilir. 2B'de painter aynı görünümü `paintLabLabel` ile çizer; etiketler `Text` widget'ı olmadığı için testlerdeki `find.text` aramalarını bozmaz. A/B renkleri `labTagColor` ile seçenek dairelerindekiyle aynıdır. `labLabelsOn` (sahnenin sağ altındaki düğme) hepsini kapatır.
- **Yazı ve keşif rehberi**: göstergeler `LabInset` ile (en az 14 px, `LabText`), keşif panelleri `LabStationPicker` + `LabStepList` (kompakt: yalnızca şimdiki adım, başlığa dokununca hepsi) + `LabActionButton` ile (`widgets/science_lab/lab_guide.dart`). Adımların `done` bayrakları controller'daki küçük keşif kümelerinden gelir (`droppedIds`, `litWith`…) ve `resetExplore`'da temizlenir. Adım metinleri testlerin `find.text`/`textContaining` ile aradığı metinleri ve istasyon adlarını tekrar etmemeli.
- Keşif panelleri test ekranından uzun: bilim insanı testleri `test/support/tap_visible.dart`'ın `tapVisible`'ını kullanır. Arşimet kolu (`CrankDial`) dokunuşu ilk temasta sahiplenir; yoksa kaydırılabilir panel çember hareketini kaydırmaya çeviriyordu.
- **Figürler ortak eklemli gövdeyle kurulur** (`tool/blender/human_body.py`, `lab_helpers.py`'den sonra `exec`): `human(prefix, height, build, female, skin/top/pants/shin/shoe, coat/skirt, arm_l/arm_r/leg_l/leg_r pozları, head)`. Stilize insan oranı (~7,5 baş, baş `head_scale` 1.1 ile hafif büyük), omuz/dirsek/bilek/kalça/diz/ayak bileği eklem noktaları ileri kinematikle hesaplanır, eller avuç + iki boğumlu 4 parmak + başparmak. Dönen `info`: `attach_head` (baş-yerel nesneyi yerine taşır), `grip_l/r` (tutulan eşya), `front_y(z, x)` (gövdenin/önlüğün ön yüzeyi; `front_band` ile şerit/kravat), `neck_front`. Saç `hair_cap`, gözlük `face_ring`. Figür en sonda `join_by_material(kök)` ile malzeme başına tek örgüye birleştirilir (≈10 örgü, ≈6k yüz). Figür GLB'leri yeniden üretildiğinde figür dışındaki gruplar birebir aynı kaldı (düğüm/köşe karşılaştırmasıyla doğrulandı). Poz yönü: `arm_l` figürün x<0 yanıdır; uzatılan kol sahnede figürün baktığı yöne gider, yönü oyun kodundaki `rotation.y` belirler.
- Blender betikleri `tool/blender/lab_helpers.py`'yi `exec` eder; MCP'den çalıştırırken önce `TOOL_DIR = r"C:\Projects\Eylul\bombali_sayilar\tool\blender"` tanımla (`__file__` yok). Düzenlenebilir `.blend`'ler yerelde (`003`-`009.blend`), betiklerden yeniden üretilebilir.
- **Yeni bilim insanı**: `games/<ad>_game.dart`, `<Ad>Controller`, `models/<ad>/`, katalogda `routeName`, `main.dart` route, `tool/blender/build_<ad>.py` → `assets/models/<ad>.glb`, 3B + 2B görünüm, keşif ekranı, `test/<ad>_test.dart`, probe'a `?who=`.
- Tarayıcı otomasyonunda kare hızı düşük olduğu için deneyler ağır çekim görünür — hata değil.

**Bilim insanlarına özgü notlar** (her biri 3 istasyon; görevler `3 tür × 2`, Arşimet `4 × 2`):
- **Arşimet**: su kabı (yüzen cisim kendi ağırlığı, batan kendi hacmi kadar su iter; taban 100 cm²), gemi (sandık kapasitesi), Arşimet vidası (en iyi = tarlaya yetişen en yatık açı; açı üçlüleri sabit listede, tek en iyi). "Su ne kadar yükselir"in 2. turu hep Kralın Tacı. Gövde yükseklikleri `BOAT_HULL_HEIGHT` ile `_boatHullHeight` aynı olmalı. Blender: `scale`/`rotation` grubun orijinine göre; parçayı orijinde kur, sonra taşı. `get_viewport_screenshot` eski kare döndürebilir → `render_preview(...)`.
- **Newton**: düşme kulesi (havada karesel sürtünme; "aynı anda" eşiği 0,1 sn; Ay'da tüy/çekiç), prizma (tek renk birleşince beyaza **dönmez**; yelpaze ×2,5 abartılı), itme pisti (aynı yay, ilk hız = itme/kütle). Görünüm konumları modelden okur (ekran = açıklama).
- **Galileo**: Galile teleskobu (büyütme = objektif ÷ göz merceği, tüp = **fark**; "toplam" Kepler'dir ve bilerek yanlış seçenek), Jüpiter'in uyduları (defter çizimi `* O *`), Venüs evreleri (cevap penceresi soru sırasında gizli).
- **Tesla**: jeneratör (AC'de iki LED sırayla, DC'de biri sabit; osiloskop penceresi bilerek durağan), iletim (kayıp = (P/V)²R; gerilim soruları yalnızca 30/50 km'de), kablosuz bobin (rezonans × alan; keşif ayarsız başlar). Yeniden renklenen parçalar kendi malzemesine sahip.
- **Curie** (hassas konu, güvenlik notu her yerde): Geiger sayacı (arka plan 0,5 tık/sn + ters kare; `formatCps`), kalkanlar (parçacık konumu doğarken atanmalı), ışın tedavisi (sağlıklı doku ölçüsü güvenlik payı dışında; ortalama doz bilerek kullanılmaz).
- **Einstein**: uzay-zaman örtüsü (leapfrog bilye, düşme/yörünge/kaçma), ışık saati (√(1−v²); ikiz sorusu 0,6/0,8), E=mc² (1 g ≈ 8 182 evin yıllık elektriği; düşünce deneyi olduğu yazılır, bomba vurgusu yok).
- **Fleming** (sağlık mesajları: antibiyotiği doktor verir, virüse işe yaramaz, el yıkama; doz önerisi yok): Petri kabı + kontrol kabı, temizlik (koloni sayısı kapak/el durumuna göre), doğru ilaç (erken bırakmak dayanıklıları artırır). Agar kodla koyulaştırılır, cam opaklığı 0,12.

## Blender MCP (Blender 5.2, `mcp-for-blender`)

- Kayıt **tam yolla**: `claude mcp add blender -- "C:\Users\Erdinc\.local\bin\uvx.exe" mcp-for-blender` (yalnızca `uvx` → `CONNECTION_CLOSED`). Sonra `/mcp` → Reconnect.
- Eklenti `uvx mcp-for-blender install-addon` (`BLENDERMCP_ADDONS_DIR=%APPDATA%\Blender Foundation\Blender\5.2\scripts\addons`); Blender'da etkinleştir, `N` → MCP → **Start MCP Server** (9876). Telemetri kullanıcının bilgisiyle açık.
- Çalışma: `execute_blender_code` içinde `exec(open(r"...\build_x.py").read())` → `build()` → önizleme; dışa aktarmadan önce **`show_all()`**. Yalnızca kendi betiklerini çalıştır, dış varlık indirme.
- **`001.blend` (yerel, gitignored) giyim dükkânının tek düzenlenebilir kaynağıdır** — betiği depoda yok; yedekle. `002.blend` mobilya (betikten üretilebilir).
- Tuzaklar: `hide_viewport` render'ı etkilemez (`hide_render` de); `view_transform` dinamik enum (doğrudan ata, AgX renkleri soldurur); yüksek emission parçayı görünmez yapar; açık yüzeylerde kapak yüzleri normaller düzeltildikten **sonra** silinir.

## Android / APK

- **Depo yolu ASCII kalmalı** (`C:\Projects\Eylul\…`); ASCII olmayan yol AGP'yi ve AOT'yi bozar, `android.overridePathCheck` ekleme. APK `build/app/outputs/flutter-apk/app-release.apk` → köke `oyun-platformu.apk` (3B: `oyun-platformu-3d.apk`; kökteki `*.apk` gitignored).
- Ana manifestteki **`INTERNET` izni bilerek** (release'te yoksa Supabase sessizce çalışmaz).
- Mobil Google girişi deep link ister: `oyunplatformu://login-callback/` üç yerde aynı olmalı — `SupabaseConfig.mobileAuthRedirectUrl`, manifest `intent-filter`, Supabase Redirect URLs (eklendi, çalışıyor).
- Release APK debug anahtarıyla imzalı (yan yükleme için yeterli; Play Store için keystore gerekir).

## Dağıtım (GitHub Pages)

- `.github/workflows/deploy.yml`: `main`'e her push'ta `flutter build web --release --base-href /oyun/` → Pages. **`--base-href /oyun/` şart** (site `https://ercinnn.github.io/oyun/`); repo adı değişirse bu ve Supabase redirect URL'si de değişir.
- Pages kaynağı elle **"GitHub Actions"** yapılmalı (bir kez). `build` yeşil `deploy` kırmızıysa sebep budur.
- Supabase Redirect URLs'de `https://ercinnn.github.io/oyun/**` ve yerel `http://localhost:<port>/**` bulunmalı.
