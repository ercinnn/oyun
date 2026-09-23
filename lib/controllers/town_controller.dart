import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/town_map_data.dart';
import '../models/town/avatar_spec.dart';
import '../models/town/mini_game_session.dart';
import '../models/town/room_layout.dart';
import '../models/town/shop_catalog.dart';
import '../models/town/town_map.dart';
import '../models/town/town_phase.dart';
import '../models/town/town_profile.dart';
import '../models/town/town_world.dart';
import '../services/town_progress_repository.dart';
import '../services/town_sounds.dart';

/// Yarışma modunda her oyuncunun oynadığı tur sayısı (üç mini oyun, birer kez).
/// Diğer oyunların round sabitleriyle aynı adı kullanmıyoruz ("ambiguous
/// import" kuralı).
const int townRoundsPerPlayer = 3;

/// Karede bir kez "ping" atan hafif bildirici: [CustomPainter]'ın `repaint`
/// dinleyicisi. Her karede yalnızca çizim yenilenir; ekran ağacı ancak
/// [TownController.notifyListeners] ile (altın, kapı, süre saniyesi gibi
/// ayrık değişimlerde) yeniden kurulur.
class FrameNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Renkli Kasaba'nın durum makinesi.
///
/// Diğer oyunların aksine **sürekli kare döngüsü** vardır: ekran her karede
/// [tick] çağırır (bir `Ticker` ile). Simülasyonun kendisi saf ve sabit
/// adımlıdır ([TownWorld.step]); bu sınıf yalnızca girdiyi, fazları, cüzdanı ve
/// kalıcılığı yönetir. `Future.delayed` kullanılmaz; kayıtlar fire-and-forget
/// yazılır ve hatalar yutulur.
class TownController extends ChangeNotifier {
  TownController({
    TownProgressRepository? repository,
    Random? random,
    TownSounds? sounds,
  }) : _repository = repository ?? InMemoryTownProgressRepository(),
       _random = random ?? Random(),
       _sounds = sounds {
    world = _newTownWorld();
  }

  final TownProgressRepository _repository;
  final Random _random;

  /// Ses servisi; verilmezse oyun tamamen sessiz çalışır (testlerin varsayılanı,
  /// bkz. satrançtaki `ChessController.moveSounds`).
  final TownSounds? _sounds;

  /// Karede bir kez atılan çizim bildirimi.
  final FrameNotifier frame = FrameNotifier();

  TownPhase phase = TownPhase.setup;
  TownProfile profile = TownProfile();
  late TownWorld world;

  /// Şu anki hareket girdisi (joystick / klavye).
  WorldInput input = WorldInput.none;

  // Mini oyun / yarışma.
  MiniGameSession? session;
  bool contest = false;
  List<TownPlayerState> players = [];
  int currentPlayerIndex = 0;

  /// Mini oyun bitince (yarışma ya da serbest) sonuç kartı açıkken true.
  bool get sessionFinished => session?.finished ?? false;

  /// Serbest modda bitmiş oyunun ödülü cüzdana eklendi mi.
  bool _rewardGiven = false;

  // Kalıcılık.
  bool _dirty = false;
  double _sinceSave = 0;

  // Ayrık değişimi yakalayıp ekran ağacını yenilemek için son görülenler.
  DoorKind? _lastDoor;
  int _lastSecond = -1;
  bool _lastSessionFinished = false;

  // Ses için izlenen son değerler (dünya sayaçları kümülatif, delta bakılır).
  double _lastX = 0;
  double _lastY = 0;
  double _stepDistance = 0;
  int _lastCoinTotal = 0;
  int _lastStarTotal = 0;
  int _lastHits = 0;
  int _lastFound = 0;

  /// Bir ayak sesi ile diğeri arasında yürünen mesafe (kare). Karakter
  /// `TownWorld.speed` (3,4 kare/sn) ile koştuğu için bu değer doğrudan adım
  /// tempusunu belirler: 1,15 ≈ saniyede 3 adım. Daha küçük bir değer
  /// (ilk denemedeki 0,62 → saniyede 5,4 adım) tarayıcıda makineli tüfek gibi
  /// duyuluyordu; küçültürken dinlemeden değiştirme.
  static const double _stepStride = 1.15;

  /// Müziğin çaldığı fazlar: kurulum, sıra devri ve sonuç ekranı sessizdir
  /// (oradaki metni okumak için sessizlik daha uygun).
  static const Set<TownPhase> _musicPhases = {
    TownPhase.town,
    TownPhase.wardrobe,
    TownPhase.market,
    TownPhase.home,
    TownPhase.arcade,
    TownPhase.miniGame,
  };

  TownPlayerState get currentPlayer => players[currentPlayerIndex];

  List<TownPlayerState> get rankedByScore {
    final sorted = List<TownPlayerState>.from(players);
    sorted.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return sorted;
  }

  /// Karakterin yanındaki kapının türü (varsa "Gir" düğmesi çıkar).
  DoorKind? get doorPrompt =>
      phase == TownPhase.town ? world.nearbyDoor?.kind : null;

  TownWorld _newTownWorld() => TownWorld(
    map: buildTownMap(),
    random: _random,
    startX: townStartX,
    startY: townStartY,
    coinSpots: townCoinSpots,
    npcCount: 4,
  );

  // ─────────────────────────── Yükleme / kayıt ───────────────────────────

  /// Kayıtlı ilerlemeyi yükler (yoksa varsayılan profil kalır).
  Future<void> load() async {
    final loaded = await _repository.load();
    if (loaded != null) {
      profile = loaded;
      notifyListeners();
    }
  }

  void _markDirty() => _dirty = true;

  // ─────────────────────────── Ses ───────────────────────────

  /// Bir efekt çalar (ses kapalıysa ya da servis yoksa hiçbir şey yapmaz).
  void _fx(void Function(TownSounds sounds) play) {
    final sounds = _sounds;
    if (sounds == null || !profile.soundOn) return;
    play(sounds);
  }

  /// Fazı değiştirir ve müziği faza göre açar/kapatır. Faz her zaman buradan
  /// değişir; aksi hâlde müzik bir ekranda takılı kalır.
  void _setPhase(TownPhase next) {
    phase = next;
    _syncMusic();
  }

  void _syncMusic() {
    final sounds = _sounds;
    if (sounds == null) return;
    if (profile.musicOn && _musicPhases.contains(phase)) {
      sounds.startMusic();
    } else {
      sounds.stopMusic();
    }
  }

  /// Ses efektlerini açıp kapatır (tercih kaydedilir).
  void toggleSound() {
    profile.soundOn = !profile.soundOn;
    saveNow();
    // Açıldığında kısa bir tık: düğmenin işe yaradığı duyulsun.
    _fx((sounds) => sounds.placeItem());
    notifyListeners();
  }

  /// Müziği açıp kapatır (tercih kaydedilir).
  void toggleMusic() {
    profile.musicOn = !profile.musicOn;
    saveNow();
    _syncMusic();
    notifyListeners();
  }

  /// Dünyadaki kümülatif sayaçları ses için başlangıç değerine çeker; yeni bir
  /// dünyaya (mini oyun ya da kasabaya dönüş) geçerken çağrılır, yoksa taze
  /// dünyanın sıfır sayaçları "eksi delta" sayılıp ses tetiklenmezdi.
  void _resyncWorldSounds(TownWorld target) {
    _lastX = target.x;
    _lastY = target.y;
    _stepDistance = 0;
    _lastCoinTotal = target.coinsCollectedTotal;
    _lastStarTotal = target.starsCollectedTotal;
    _lastHits = 0;
    _lastFound = 0;
  }

  /// Dünyanın bu karedeki değişimlerinden ses üretir (ayak sesi, altın, yıldız).
  void _observeWorldSounds(TownWorld target) {
    if (target.moving) {
      final dx = target.x - _lastX;
      final dy = target.y - _lastY;
      _stepDistance += sqrt(dx * dx + dy * dy);
      if (_stepDistance >= _stepStride) {
        _stepDistance = 0;
        _fx((sounds) => sounds.step());
      }
    } else {
      // Dururken bir sonraki adımın sesi hemen gelsin (yürümeye başlar başlamaz).
      _stepDistance = _stepStride * 0.7;
    }
    _lastX = target.x;
    _lastY = target.y;

    if (target.starsCollectedTotal > _lastStarTotal) {
      _fx((sounds) => sounds.star());
    } else if (target.coinsCollectedTotal > _lastCoinTotal) {
      _fx((sounds) => sounds.coin());
    }
    _lastStarTotal = target.starsCollectedTotal;
    _lastCoinTotal = target.coinsCollectedTotal;
  }

  /// Mini oyuna özgü olayların sesi (çarpma, sandık).
  void _observeSessionSounds(MiniGameSession current) {
    if (current is ParkourSession && current.hits > _lastHits) {
      _lastHits = current.hits;
      _fx((sounds) => sounds.bump());
    } else if (current is TreasureSession && current.found > _lastFound) {
      _lastFound = current.found;
      _fx((sounds) => sounds.chest());
    }
  }

  /// Bekleyen değişiklikleri hemen yazar.
  void saveNow() {
    _dirty = false;
    _sinceSave = 0;
    _repository.save(profile).catchError((_) {});
  }

  // ─────────────────────────── Fazlar ───────────────────────────

  /// Serbest kasaba moduna gir.
  void enterTown() {
    contest = false;
    session = null;
    input = WorldInput.none;
    _resyncWorldSounds(world);
    _setPhase(TownPhase.town);
    notifyListeners();
  }

  /// Yalnızca geliştirme girişi için (`lib/dev/town_3d_probe.dart`): kasabada
  /// yürümeye gerek kalmadan bir ekranı açar. Oyunun akışında kullanılmaz.
  void debugJumpToPhase(TownPhase target) {
    input = WorldInput.none;
    _setPhase(target);
    notifyListeners();
  }

  /// Dünyadan kurulum ekranına dön.
  void leaveToSetup() {
    saveNow();
    input = WorldInput.none;
    _setPhase(TownPhase.setup);
    notifyListeners();
  }

  /// Kapıya gir: kapının türüne göre ekran açılır.
  void enterNearbyDoor() {
    final door = doorPrompt;
    if (door == null) return;
    input = WorldInput.none;
    saveNow();
    _fx((sounds) => sounds.doorOpen());
    _setPhase(switch (door) {
      DoorKind.wardrobe => TownPhase.wardrobe,
      DoorKind.market => TownPhase.market,
      DoorKind.home => TownPhase.home,
      DoorKind.arcade => TownPhase.arcade,
    });
    notifyListeners();
  }

  /// Alt ekrandan (dükkân, ev, salon) kasabaya dön.
  void backToTown() {
    saveNow();
    session = null;
    _resyncWorldSounds(world);
    _setPhase(TownPhase.town);
    notifyListeners();
  }

  void restart() {
    saveNow();
    players = [];
    currentPlayerIndex = 0;
    session = null;
    contest = false;
    input = WorldInput.none;
    _setPhase(TownPhase.setup);
    notifyListeners();
  }

  // ─────────────────────────── Dünya döngüsü ───────────────────────────

  void setInput(WorldInput value) => input = value;

  /// Bir kareye dokunuldu/tıklandı: oraya yürü. Kasabada ve süren mini
  /// oyunlarda çalışır (bitmiş oyunda dokunuş yok sayılır).
  void tapTile(int x, int y) {
    if (phase == TownPhase.town) {
      // Kapının önündeyken o kapıya (ya da binaya) bir kez daha dokunmak içeri
      // sokar: tamamen fareyle/parmakla oynanabilsin, "Gir" düğmesi şart olmasın.
      final door = world.nearbyDoor;
      if (door != null && door.doorX == x && door.doorY == y) {
        enterNearbyDoor();
        return;
      }
      world.walkTo(x, y);
    } else if (phase == TownPhase.miniGame) {
      final current = session;
      if (current != null && !current.finished) current.world.walkTo(x, y);
    }
  }

  /// Bir kare ilerlet ([dt] saniye).
  void tick(double dt) {
    if (phase == TownPhase.town) {
      world.step(dt, input);
      _observeWorldSounds(world);
      final value = world.takeCollectedValue();
      if (value > 0) {
        profile.coins += value;
        _markDirty();
        notifyListeners();
      }
      final door = world.nearbyDoor?.kind;
      if (door != _lastDoor) {
        _lastDoor = door;
        if (door != null) _fx((sounds) => sounds.doorNear());
        notifyListeners();
      }
    } else if (phase == TownPhase.miniGame) {
      final current = session;
      if (current == null) return;
      current.step(dt, input);
      _observeWorldSounds(current.world);
      _observeSessionSounds(current);
      final second = current.timeLeft.ceil();
      final finishedNow = current.finished;
      if (second != _lastSecond || finishedNow != _lastSessionFinished) {
        _lastSecond = second;
        _lastSessionFinished = finishedNow;
        if (finishedNow) {
          input = WorldInput.none;
          _fx((sounds) => current.score > 0 ? sounds.win() : sounds.lose());
        }
        notifyListeners();
      }
    }

    if (_dirty) {
      _sinceSave += dt;
      if (_sinceSave >= 3) saveNow();
    }
    frame.ping();
  }

  // ─────────────────────────── Giyim dükkânı ───────────────────────────

  bool isEquipped(ShopItem item) => switch (item.category) {
    ShopCategory.hair => profile.avatar.hairStyle == item.id,
    ShopCategory.outfit => profile.avatar.outfit == item.id,
    ShopCategory.hat => profile.avatar.hat == item.id,
    ShopCategory.accessory => profile.avatar.accessory == item.id,
    ShopCategory.furniture => false,
  };

  /// Eşyayı kuşan; sahip değilse (yeterli altın varsa) önce satın al. Başarılıysa
  /// true; altın yetmezse false.
  bool buyOrEquip(ShopItem item) {
    if (item.category == ShopCategory.furniture) return false;
    if (!profile.owns(item.id)) {
      if (!profile.buy(item)) {
        _fx((sounds) => sounds.denied());
        return false;
      }
      _fx((sounds) => sounds.purchase());
    } else {
      _fx((sounds) => sounds.placeItem());
    }
    final avatar = profile.avatar;
    profile.avatar = switch (item.category) {
      ShopCategory.hair => avatar.copyWith(hairStyle: item.id),
      ShopCategory.outfit => avatar.copyWith(outfit: item.id),
      ShopCategory.hat => avatar.copyWith(hat: item.id),
      ShopCategory.accessory => avatar.copyWith(accessory: item.id),
      ShopCategory.furniture => avatar,
    };
    _markDirty();
    notifyListeners();
    return true;
  }

  void setSkin(int index) {
    if (index < 0 || index >= skinPalette.length) return;
    profile.avatar = profile.avatar.copyWith(skin: index);
    _markDirty();
    notifyListeners();
  }

  void setHairColor(int index) {
    if (index < 0 || index >= hairPalette.length) return;
    profile.avatar = profile.avatar.copyWith(hairColor: index);
    _markDirty();
    notifyListeners();
  }

  void setOutfitColor(int index) {
    if (index < 0 || index >= outfitPalette.length) return;
    profile.avatar = profile.avatar.copyWith(outfitColor: index);
    _markDirty();
    notifyListeners();
  }

  // ─────────────────────────── Market ───────────────────────────

  /// Mobilya satın al (birden çok alınabilir). Altın yetmezse false.
  bool buyFurniture(ShopItem item) {
    if (item.category != ShopCategory.furniture) return false;
    final bought = profile.buy(item);
    _fx((sounds) => bought ? sounds.purchase() : sounds.denied());
    if (bought) {
      _markDirty();
      notifyListeners();
    }
    return bought;
  }

  // ─────────────────────────── Oda ───────────────────────────

  /// Envanterden [item]'ı odaya yerleştir. Geçersizse (sınır/çakışma/adet)
  /// false.
  bool placeItem(ShopItem item, int x, int y, {int rotation = 0}) {
    if (profile.availableCount(item.id) <= 0) return false;
    if (!profile.room.canPlace(item, x, y, rotation)) {
      _fx((sounds) => sounds.denied());
      return false;
    }
    _fx((sounds) => sounds.placeItem());
    profile.room = profile.room.copyWith(
      items: [
        ...profile.room.items,
        PlacedItem(itemId: item.id, x: x, y: y, rotation: rotation),
      ],
    );
    _markDirty();
    notifyListeners();
    return true;
  }

  /// [index]'teki eşyayı bir çeyrek tur döndür (sığmazsa false).
  bool rotatePlaced(int index) {
    if (index < 0 || index >= profile.room.items.length) return false;
    final placed = profile.room.items[index];
    final item = shopItemById(placed.itemId);
    if (item == null) return false;
    final rotation = (placed.rotation + 1) % 4;
    if (!profile.room.canPlace(item, placed.x, placed.y, rotation, ignoreIndex: index)) {
      return false;
    }
    _fx((sounds) => sounds.placeItem());
    final items = [...profile.room.items];
    items[index] = placed.copyWith(rotation: rotation);
    profile.room = profile.room.copyWith(items: items);
    _markDirty();
    notifyListeners();
    return true;
  }

  /// [index]'teki eşyayı yeni konuma taşı (sığmazsa false).
  bool movePlaced(int index, int x, int y) {
    if (index < 0 || index >= profile.room.items.length) return false;
    final placed = profile.room.items[index];
    final item = shopItemById(placed.itemId);
    if (item == null) return false;
    if (!profile.room.canPlace(item, x, y, placed.rotation, ignoreIndex: index)) {
      return false;
    }
    _fx((sounds) => sounds.placeItem());
    final items = [...profile.room.items];
    items[index] = placed.copyWith(x: x, y: y);
    profile.room = profile.room.copyWith(items: items);
    _markDirty();
    notifyListeners();
    return true;
  }

  /// [index]'teki eşyayı odadan kaldır (envantere döner).
  void removePlaced(int index) {
    if (index < 0 || index >= profile.room.items.length) return;
    _fx((sounds) => sounds.placeItem());
    final items = [...profile.room.items]..removeAt(index);
    profile.room = profile.room.copyWith(items: items);
    _markDirty();
    notifyListeners();
  }

  void setRoomFloor(int index) {
    if (index < 0 || index >= roomFloorColors.length) return;
    profile.room = profile.room.copyWith(floorColor: index);
    _markDirty();
    notifyListeners();
  }

  void setRoomWall(int index) {
    if (index < 0 || index >= roomWallColors.length) return;
    profile.room = profile.room.copyWith(wallColor: index);
    _markDirty();
    notifyListeners();
  }

  // ─────────────────────────── Mini oyunlar ───────────────────────────

  /// Serbest modda oyun salonundan bir mini oyun başlat (puansız, altın ödüllü).
  void startFreeMiniGame(MiniGameKind kind) {
    contest = false;
    _beginSession(kind);
  }

  /// Yarışma modunu başlat: her oyuncu üç mini oyunu sırayla oynar.
  void startContest(List<String> names) {
    contest = true;
    players = names.map((name) => TownPlayerState(name: name)).toList();
    currentPlayerIndex = 0;
    _beginSession(MiniGameKind.values[0]);
  }

  void _beginSession(MiniGameKind kind) {
    session = MiniGameSession.create(kind, _random);
    _rewardGiven = false;
    input = WorldInput.none;
    _lastSecond = -1;
    _lastSessionFinished = false;
    _resyncWorldSounds(session!.world);
    _setPhase(TownPhase.miniGame);
    _fx((sounds) => sounds.gameStart());
    notifyListeners();
  }

  /// Sonuç kartındaki "Devam"a basıldı.
  ///
  /// Serbest modda ödül cüzdana eklenir ve oyun salonuna dönülür. Yarışmada
  /// puan oyuncuya yazılır; sıradaki oyuna, sıra devrine ya da sonuç ekranına
  /// geçilir.
  void continueAfterMiniGame() {
    final current = session;
    if (current == null || !current.finished) return;

    if (!contest) {
      if (!_rewardGiven) {
        profile.coins += current.rewardCoins;
        _rewardGiven = true;
        _markDirty();
      }
      session = null;
      saveNow();
      _setPhase(TownPhase.arcade);
      notifyListeners();
      return;
    }

    final player = currentPlayer;
    player.totalScore += current.score;
    player.roundsPlayed++;

    if (player.roundsPlayed >= townRoundsPerPlayer) {
      final next = _findNextUnfinishedPlayerIndex();
      if (next == null) {
        session = null;
        _setPhase(TownPhase.finished);
        notifyListeners();
        return;
      }
      currentPlayerIndex = next;
      session = null;
      _setPhase(TownPhase.turnTransition);
      notifyListeners();
      return;
    }
    _beginSession(MiniGameKind.values[player.roundsPlayed]);
  }

  /// Yarışmada sıra devrinden sonra sıradaki oyuncunun ilk oyununu başlat.
  void acknowledgeTurnTransition() {
    _beginSession(MiniGameKind.values[currentPlayer.roundsPlayed]);
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (currentPlayerIndex + offset) % players.length;
      if (players[index].roundsPlayed < townRoundsPerPlayer) return index;
    }
    return null;
  }

  @override
  void dispose() {
    frame.dispose();
    _sounds?.dispose();
    super.dispose();
  }
}
