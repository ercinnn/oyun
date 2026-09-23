import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';
import '../models/town/shop_catalog.dart';
import '../widgets/furniture_thumb.dart';
import '../widgets/town_hud.dart';

/// Market: mobilya satın al (birden çok alınabilir); odana Evim'den yerleştir.
class TownMarketScreen extends StatelessWidget {
  const TownMarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TownController>();
    final profile = controller.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Aldığın mobilyaları Evim\'e gidip odana yerleştirebilirsin.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              for (final item in shopItemsIn(ShopCategory.furniture))
                Card(
                  child: ListTile(
                    leading: FurnitureThumb(item: item, size: 48),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.price} altın · Sende: ${profile.owned[item.id] ?? 0}',
                    ),
                    trailing: FilledButton(
                      key: Key('marketBuy_${item.id}'),
                      onPressed: profile.coins >= item.price
                          ? () => controller.buyFurniture(item)
                          : null,
                      child: const Text('Satın al'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
