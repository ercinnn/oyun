import '../models/newton/falling.dart';

/// Düşme kulesinden bırakılabilen cisimler. Limit hızları ilkokul düzeyinde
/// yuvarlatılmış gerçekçi değerlerdir; model yalnızca bu tabloya bakar. Her
/// kimliğin 3B modeli `assets/models/newton.glb` içinde `fall_<id>` grubudur.
///
/// Kâğıt çifti bilerek var (Arşimet'teki hamur top/kase gibi): **aynı kâğıt**
/// düzken süzülür, buruşturulunca hızla düşer — fark ağırlıkta değil, havanın
/// onu ne kadar tuttuğunda.
const List<FallingObject> newtonFallingObjects = [
  FallingObject(
    id: 'apple',
    name: 'Elma',
    emoji: '🍎',
    massG: 150,
    terminalSpeed: 25,
    note: 'Elma ağır ve yuvarlaktır; hava onu pek yavaşlatamaz. Newton\'un '
        'başına düşen elma, Dünya\'nın her şeyi kendine çektiğini düşündürdü.',
  ),
  FallingObject(
    id: 'feather',
    name: 'Tüy',
    emoji: '🪶',
    massG: 1,
    terminalSpeed: 1.2,
    note: 'Tüy çok hafif ve geniştir: hava onu yukarı doğru iter, süzülerek '
        'iner. Havayı kaldırırsak tüy de taş gibi düşer.',
  ),
  FallingObject(
    id: 'hammer',
    name: 'Çekiç',
    emoji: '🔨',
    massG: 800,
    terminalSpeed: 60,
    note: 'Çekiç ağırdır, hava onu neredeyse hiç yavaşlatmaz.',
  ),
  FallingObject(
    id: 'bowling',
    name: 'Bovling topu',
    emoji: '🎳',
    massG: 6000,
    terminalSpeed: 90,
    note: 'Bovling topu tenis topundan 100 kat ağırdır ama kısa bir düşüşte '
        'neredeyse aynı anda yere değerler. Kütleçekim ağır cismi daha çok '
        'çeker, ama ağır cismi hızlandırmak da o kadar zordur.',
  ),
  FallingObject(
    id: 'tennis',
    name: 'Tenis topu',
    emoji: '🎾',
    massG: 58,
    terminalSpeed: 22,
    note: 'Tenis topu hafiftir ama küçük ve yuvarlaktır; hava onu kısa '
        'mesafede pek tutamaz.',
  ),
  FallingObject(
    id: 'paper_flat',
    name: 'Düz kâğıt',
    emoji: '📄',
    massG: 5,
    terminalSpeed: 1.5,
    note: 'Düz kâğıt havaya geniş yüzüyle çarpar; hava onu paraşüt gibi '
        'tutar.',
  ),
  FallingObject(
    id: 'paper_ball',
    name: 'Buruşuk kâğıt',
    emoji: '🗞️',
    massG: 5,
    terminalSpeed: 8,
    note: 'Aynı kâğıdı buruşturduk! Ağırlığı değişmedi ama havaya çarpan yüzü '
        'küçüldü, bu yüzden çok daha hızlı düştü.',
  ),
  FallingObject(
    id: 'balloon',
    name: 'Balon',
    emoji: '🎈',
    massG: 3,
    terminalSpeed: 2.2,
    note: 'Balon büyük ama çok hafiftir; hava onu kolayca yavaşlatır.',
  ),
];

FallingObject fallingObjectById(String id) =>
    newtonFallingObjects.firstWhere((o) => o.id == id);
