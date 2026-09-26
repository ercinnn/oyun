import 'package:flutter/foundation.dart';

import '../models/science/science_task.dart';
import '../models/science/scientist_phase.dart';
import '../services/scientist_sounds.dart';

/// Bilim İnsanları oyunlarının ortak durum makinesi: oyuncular, turlar,
/// cevap → sonuç paneli → "Devam", sıra devri ve keşif atölyesine geçiş.
/// Her bilim insanı bunu genişletip yalnızca kendi görevlerini
/// ([generateTask]) ve keşif durumunu ekler.
///
/// Bitki Laboratuvarı/Elektrik Atölyesi gibi **tamamen senkron**: hiç
/// `Future.delayed` yok, bu yüzden `_generation`/`_resolving` gerekmez.
/// Cevaptan sonra [showingResult] true olur ve oyuncu "Devam"a basana kadar
/// deney + açıklama ekranda kalır; animasyonlar yalnızca görünümdedir.
abstract class ScientistGameController<T extends ScienceTask>
    extends ChangeNotifier {
  ScientistPhase phase = ScientistPhase.setup;
  List<ScientistPlayerState> players = [];
  int currentPlayerIndex = 0;
  late T currentTask;
  bool showingResult = false;
  bool lastAnswerCorrect = false;
  int? lastAnswerIndex;

  /// Ses efektleri; verilmezse (testler) oyun tamamen sessizdir ve ses
  /// düğmesi görünmez. [attachSounds] ile bağlanır.
  ScientistSounds? sounds;
  bool _disposed = false;

  /// Ses servisini bağlar ve kayıtlı açık/kapalı tercihini okur (okuma
  /// bitince düğme doğru simgeyi göstersin diye dinleyicilere bildirir).
  void attachSounds(ScientistSounds value) {
    sounds = value;
    value.load().then((_) {
      if (!_disposed) notifyListeners();
    }).catchError((_) {});
  }

  bool get hasSounds => sounds != null;
  bool get soundOn => sounds?.enabled ?? false;

  void toggleSound() {
    final s = sounds;
    if (s == null) return;
    s.enabled = !s.enabled;
    notifyListeners();
  }

  /// Bir ses efekti çalar (ses yoksa ya da kapalıysa hiçbir şey olmaz).
  /// Alt sınıflar deney eylemlerinde çağırır.
  @protected
  void playSound(ScienceSound sound) {
    final s = sounds;
    if (s != null && s.enabled) s.play(sound);
  }

  /// Oyuncu başına görev sayısı.
  int get roundsPerPlayer;

  /// Oyuncunun [round]. görevi (0'dan başlar). Görev türlerinin dönüşümü ve
  /// tekrarsızlık alt sınıfın işidir.
  T generateTask(int round);

  /// Yeni oyuncunun sırası başlarken (görev havuzlarını karıştırmak için).
  void planForPlayer() {}

  /// Keşif atölyesinin başlangıç durumu ([startExplore] çağırır).
  void resetExplore() {}

  ScientistPlayerState get currentPlayer => players[currentPlayerIndex];

  List<ScientistPlayerState> get rankedByCorrect {
    final sorted = List<ScientistPlayerState>.from(players);
    sorted.sort((a, b) => b.correctCount.compareTo(a.correctCount));
    return sorted;
  }

  void startGame(List<String> names) {
    players = names.map((n) => ScientistPlayerState(name: n)).toList();
    currentPlayerIndex = 0;
    _clearResult();
    planForPlayer();
    currentTask = generateTask(0);
    phase = ScientistPhase.playing;
    notifyListeners();
  }

  void answer(int index) {
    if (phase != ScientistPhase.playing || showingResult) return;
    if (index < 0 || index >= currentTask.options.length) return;
    lastAnswerIndex = index;
    lastAnswerCorrect = index == currentTask.correctIndex;
    if (lastAnswerCorrect) currentPlayer.correctCount++;
    currentPlayer.roundsPlayed++;
    showingResult = true;
    playSound(lastAnswerCorrect ? ScienceSound.correct : ScienceSound.wrong);
    notifyListeners();
  }

  void continueAfterResult() {
    if (!showingResult) return;
    _clearResult();
    if (currentPlayer.roundsPlayed >= roundsPerPlayer) {
      final next = _findNextUnfinishedPlayerIndex();
      if (next == null) {
        phase = ScientistPhase.finished;
        playSound(ScienceSound.fanfare);
        notifyListeners();
        return;
      }
      currentPlayerIndex = next;
      planForPlayer();
      phase = ScientistPhase.turnTransition;
      playSound(ScienceSound.turn);
    }
    currentTask = generateTask(currentPlayer.roundsPlayed);
    notifyListeners();
  }

  void acknowledgeTurnTransition() {
    phase = ScientistPhase.playing;
    notifyListeners();
  }

  void restart() {
    players = [];
    currentPlayerIndex = 0;
    _clearResult();
    phase = ScientistPhase.setup;
    notifyListeners();
  }

  void startExplore() {
    resetExplore();
    phase = ScientistPhase.explore;
    notifyListeners();
  }

  void backToSetup() {
    phase = ScientistPhase.setup;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    sounds?.dispose();
    super.dispose();
  }

  void _clearResult() {
    showingResult = false;
    lastAnswerCorrect = false;
    lastAnswerIndex = null;
  }

  int? _findNextUnfinishedPlayerIndex() {
    for (var i = 0; i < players.length; i++) {
      if (players[i].roundsPlayed < roundsPerPlayer) return i;
    }
    return null;
  }
}
