import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';
import '../models/town/avatar_spec.dart';
import '../models/town/shop_catalog.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/town_hud.dart';

/// Giyim Dükkânı: avatar önizlemesi, ücretsiz renkler ve altınla alınan
/// biçimler (saç, kıyafet, şapka, aksesuar).
class TownWardrobeScreen extends StatefulWidget {
  const TownWardrobeScreen({super.key});

  @override
  State<TownWardrobeScreen> createState() => _TownWardrobeScreenState();
}

class _TownWardrobeScreenState extends State<TownWardrobeScreen> {
  static const _categories = [
    ShopCategory.hair,
    ShopCategory.outfit,
    ShopCategory.hat,
    ShopCategory.accessory,
  ];

  ShopCategory _category = ShopCategory.hair;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TownController>();
    final profile = controller.profile;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giyim Dükkânı'),
        leading: BackButton(onPressed: controller.backToTown),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CoinChip(coins: profile.coins),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: AvatarPreview(spec: profile.avatar, size: 150)),
                const SizedBox(height: 8),
                _Swatches(
                  title: 'Ten',
                  keyPrefix: 'skin',
                  colors: skinPalette,
                  selected: profile.avatar.skin,
                  onPick: controller.setSkin,
                ),
                _Swatches(
                  title: 'Saç rengi',
                  keyPrefix: 'hairColor',
                  colors: hairPalette,
                  selected: profile.avatar.hairColor,
                  onPick: controller.setHairColor,
                ),
                _Swatches(
                  title: 'Kıyafet rengi',
                  keyPrefix: 'outfitColor',
                  colors: outfitPalette,
                  selected: profile.avatar.outfitColor,
                  onPick: controller.setOutfitColor,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final category in _categories)
                      ChoiceChip(
                        key: Key('wardrobeCategory_${category.name}'),
                        label: Text(category.label),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final item in shopItemsIn(_category))
                  Card(
                    child: ListTile(
                      leading: Text(item.emoji, style: const TextStyle(fontSize: 28)),
                      title: Text(item.name),
                      subtitle: Text(
                        profile.owns(item.id)
                            ? 'Sende var'
                            : '${item.price} altın',
                        style: textTheme.bodySmall,
                      ),
                      trailing: _ItemButton(item: item),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemButton extends StatelessWidget {
  const _ItemButton({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TownController>();
    final profile = controller.profile;
    final equipped = controller.isEquipped(item);
    final owned = profile.owns(item.id);
    final affordable = profile.coins >= item.price;

    final String label;
    final VoidCallback? onPressed;
    if (equipped) {
      label = 'Giyili';
      onPressed = null;
    } else if (owned) {
      label = 'Giy';
      onPressed = () => controller.buyOrEquip(item);
    } else {
      label = 'Satın al';
      onPressed = affordable ? () => controller.buyOrEquip(item) : null;
    }

    return FilledButton(
      key: Key('wardrobeItem_${item.id}'),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({
    required this.title,
    required this.keyPrefix,
    required this.colors,
    required this.selected,
    required this.onPick,
  });

  final String title;
  final String keyPrefix;
  final List<Color> colors;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (var i = 0; i < colors.length; i++)
                GestureDetector(
                  key: Key('${keyPrefix}_$i'),
                  onTap: () => onPick(i),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black26,
                        width: i == selected ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
