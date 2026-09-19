import '../models/electric_material.dart';

/// İletken/yalıtkan deneyindeki malzemeler. Bilgi ilkokul düzeyinde
/// sadeleştirilmiştir; bir öğretmen/ebeveyn gözden geçirip düzeltebilir.
const List<ElectricMaterial> electricMaterials = [
  ElectricMaterial(
    id: 'bakir',
    name: 'Bakır tel',
    emoji: '➰',
    conductive: true,
    note:
        'Bakır çok iyi bir iletkendir; elektrik kabloları bu yüzden bakırdan yapılır.',
  ),
  ElectricMaterial(
    id: 'aluminyum',
    name: 'Alüminyum kutu',
    emoji: '🥫',
    conductive: true,
    note: 'Alüminyum bir metaldir ve elektriği iletir.',
  ),
  ElectricMaterial(
    id: 'demir',
    name: 'Demir cıvata',
    emoji: '🔩',
    conductive: true,
    note: 'Demir bir metaldir; metaller elektriği iletir.',
  ),
  ElectricMaterial(
    id: 'kalem',
    name: 'Kurşun kalem ucu',
    emoji: '✏️',
    conductive: true,
    note:
        'Kurşun kalemin ucu kurşun değil grafittir; grafit elektriği iletir.',
  ),
  ElectricMaterial(
    id: 'tuzlusu',
    name: 'Tuzlu su',
    emoji: '🧂',
    conductive: true,
    note:
        'Tuzlu su elektriği iletir; suda çözünen tuz elektriğin geçmesine yardım eder.',
  ),
  ElectricMaterial(
    id: 'kasik',
    name: 'Metal kaşık',
    emoji: '🥄',
    conductive: true,
    note: 'Metal kaşık elektriği iletir.',
  ),
  ElectricMaterial(
    id: 'plastik',
    name: 'Plastik şişe',
    emoji: '🧴',
    conductive: false,
    note:
        'Plastik yalıtkandır; elektrik geçmez. Kabloların dışı bu yüzden plastikle kaplıdır.',
  ),
  ElectricMaterial(
    id: 'tahta',
    name: 'Tahta çubuk',
    emoji: '🥢',
    conductive: false,
    note: 'Kuru tahta yalıtkandır; elektriği geçirmez.',
  ),
  ElectricMaterial(
    id: 'silgi',
    name: 'Silgi',
    emoji: '⬜',
    conductive: false,
    note: 'Silgi kauçuktan yapılır ve yalıtkandır.',
  ),
  ElectricMaterial(
    id: 'cam',
    name: 'Cam bardak',
    emoji: '🥛',
    conductive: false,
    note: 'Cam yalıtkandır; elektriği geçirmez.',
  ),
  ElectricMaterial(
    id: 'kumas',
    name: 'Kumaş',
    emoji: '🧣',
    conductive: false,
    note: 'Kuru kumaş yalıtkandır; elektriği geçirmez.',
  ),
  ElectricMaterial(
    id: 'kagit',
    name: 'Kâğıt',
    emoji: '📄',
    conductive: false,
    note: 'Kuru kâğıt yalıtkandır; elektriği geçirmez.',
  ),
  ElectricMaterial(
    id: 'lastik',
    name: 'Lastik',
    emoji: '🛞',
    conductive: false,
    note:
        'Lastik yalıtkandır; bu yüzden elektrikçilerin eldivenleri lastikten yapılır.',
  ),
];
