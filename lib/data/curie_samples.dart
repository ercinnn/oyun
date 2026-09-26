import '../models/curie/geiger.dart';

/// Curie'nin masasındaki numuneler. Sayım değerleri oyun için sadeleştirilmiş
/// ama sıralamaları gerçekçidir: radyum > polonyum > zift blendi > uranyum;
/// granit çok az, sofra tuzu hiç ışımaz. Her kimliğin 3B modeli
/// `assets/models/curie.glb` içinde `curie_sample_<id>` grubudur.
///
/// Zift blendi ile uranyum çifti bilerek var: cevher, içindeki saf uranyumdan
/// **daha çok** ışır — Curie'yi polonyum ve radyumu aramaya götüren ipucu.
const List<RadioSample> curieSamples = [
  RadioSample(
    id: 'radium',
    name: 'Radyum',
    emoji: '🟢',
    cpsAt10cm: 400,
    glows: true,
    note: 'Radyum çok güçlü ışır; tuzları karanlıkta hafif yeşilimsi parlar. '
        'Marie ve Pierre Curie onu tonlarca cevherden birkaç tanecik olarak '
        'ayırdılar.',
  ),
  RadioSample(
    id: 'polonium',
    name: 'Polonyum',
    emoji: '🧪',
    cpsAt10cm: 250,
    note: 'Polonyumu Marie Curie buldu ve adını doğduğu ülke Polonya\'dan '
        'verdi.',
  ),
  RadioSample(
    id: 'pitchblende',
    name: 'Zift blendi (uranyum cevheri)',
    emoji: '🪨',
    cpsAt10cm: 60,
    note: 'Bu kara taş, içindeki uranyumdan daha çok ışıyordu. Curie içinde '
        'bilinmeyen başka elementler olduğunu anladı: polonyum ve radyum!',
  ),
  RadioSample(
    id: 'uranium',
    name: 'Uranyum tuzu',
    emoji: '🟡',
    cpsAt10cm: 15,
    note: 'Uranyumun ışıdığını Becquerel keşfetti; Curie bu ışımayı ölçmeyi '
        'öğrendi ve ona "radyoaktivite" adını verdi.',
  ),
  RadioSample(
    id: 'granite',
    name: 'Granit taşı',
    emoji: '⬜',
    cpsAt10cm: 1,
    note: 'Bazı taşlar çok çok az ışır; sayaç arka plandan zor ayırır. '
        'Bu kadarı zararsızdır.',
  ),
  RadioSample(
    id: 'salt',
    name: 'Sofra tuzu',
    emoji: '🧂',
    cpsAt10cm: 0,
    note: 'Sofra tuzu ışımaz; duyduğun birkaç tık doğadan gelen arka plandır.',
  ),
];

RadioSample curieSampleById(String id) =>
    curieSamples.firstWhere((s) => s.id == id);
