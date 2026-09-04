/// Satrançta oyuncu başına düşen toplam süre.
///
/// [unlimited] bilerek hem varsayılan hem de listenin ilk seçeneği: platformun
/// hedef kitlesi için süreli oyun bir tercih, zorunluluk değil. Ayrıca
/// `ChessController` yalnızca süreli bir oyunda periyodik saat sayacını
/// kuruyor — süresiz oyunda hiç `Timer` çalışmaz.
enum ChessTimeControl {
  unlimited(label: 'Süresiz'),
  fiveMinutes(label: '5 dk', minutes: 5),
  tenMinutes(label: '10 dk', minutes: 10),
  thirtyMinutes(label: '30 dk', minutes: 30);

  const ChessTimeControl({required this.label, this.minutes});

  final String label;

  /// `null` = süre sınırı yok.
  final int? minutes;

  Duration? get initialTime =>
      minutes == null ? null : Duration(minutes: minutes!);
}
