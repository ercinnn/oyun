import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/town_3d.dart';
import '../controllers/town_controller.dart';
import '../models/town/room_layout.dart';
import '../models/town/shop_catalog.dart';
import '../widgets/furniture_thumb.dart';
import '../widgets/iso_room_view.dart';
import '../widgets/room_3d_view.dart';

/// Evim: izometrik oda. Envanterden bir eşya seç, bir kareye dokunup
/// yerleştir; yerleştirilmiş bir eşyaya dokunup seç, döndür, taşı ya da kaldır.
class TownRoomScreen extends StatefulWidget {
  const TownRoomScreen({super.key});

  @override
  State<TownRoomScreen> createState() => _TownRoomScreenState();
}

class _TownRoomScreenState extends State<TownRoomScreen> {
  /// Yerleştirilmek üzere seçilen envanter eşyası.
  String? _armedItemId;
  int _placeRotation = 0;

  /// Odadaki seçili eşyanın indeksi (-1: yok).
  int _selectedIndex = -1;

  String? _message;

  void _onTapTile(int x, int y) {
    final controller = context.read<TownController>();
    final layout = controller.profile.room;

    if (_armedItemId != null) {
      final item = shopItemById(_armedItemId!)!;
      final placed = controller.placeItem(item, x, y, rotation: _placeRotation);
      setState(() {
        _message = placed ? null : 'Buraya sığmıyor.';
        if (placed && controller.profile.availableCount(item.id) <= 0) {
          _armedItemId = null;
        }
      });
      return;
    }

    final index = layout.itemIndexAt(x, y);
    if (index >= 0) {
      setState(() {
        _selectedIndex = index;
        _message = null;
      });
      return;
    }

    // Boş kare: seçili eşya varsa oraya taşı.
    if (_selectedIndex >= 0) {
      final moved = controller.movePlaced(_selectedIndex, x, y);
      setState(() => _message = moved ? null : 'Buraya sığmıyor.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TownController>();
    final profile = controller.profile;
    final layout = profile.room;
    if (_selectedIndex >= layout.items.length) _selectedIndex = -1;

    final inventory = [
      for (final item in shopItemsIn(ShopCategory.furniture))
        if (profile.availableCount(item.id) > 0) item,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evim'),
        leading: BackButton(onPressed: controller.backToTown),
      ),
      body: Column(
        children: [
          Expanded(
            // 3B açıkken oda da kasabayla aynı görsel dilde (Blender mobilya
            // modelleri); testler/WebGL'siz platformlar izometrik görünümde.
            child: townUse3d
                ? Room3DView(
                    layout: layout,
                    selectedIndex: _selectedIndex,
                    onTapTile: _onTapTile,
                  )
                : IsoRoomView(
                    layout: layout,
                    selectedIndex: _selectedIndex,
                    onTapTile: _onTapTile,
                  ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_message != null)
                    Text(
                      _message!,
                      key: const Key('roomMessage'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  Text(
                    _armedItemId != null
                        ? 'Bir kareye dokunup yerleştir.'
                        : (_selectedIndex >= 0
                              ? 'Seçili eşya: başka bir boş kareye dokunup taşı.'
                              : 'Yerleştirmek için envanterden eşya seç ya da odadaki bir eşyaya dokun.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  if (inventory.isEmpty)
                    const Text(
                      'Envanterin boş. Marketten mobilya alabilirsin.',
                      textAlign: TextAlign.center,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final item in inventory)
                          ChoiceChip(
                            key: Key('roomInv_${item.id}'),
                            avatar: FurnitureThumb(item: item, size: 30),
                            label: Text(
                              '${item.name} ×${profile.availableCount(item.id)}',
                            ),
                            selected: _armedItemId == item.id,
                            onSelected: (selected) => setState(() {
                              _armedItemId = selected ? item.id : null;
                              _selectedIndex = -1;
                              _message = null;
                            }),
                          ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      if (_armedItemId != null)
                        OutlinedButton(
                          key: const Key('roomPlaceRotate'),
                          onPressed: () => setState(
                            () => _placeRotation = (_placeRotation + 1) % 4,
                          ),
                          child: Text('Yön: ${_placeRotation * 90}°'),
                        ),
                      if (_selectedIndex >= 0) ...[
                        OutlinedButton(
                          key: const Key('roomRotate'),
                          onPressed: () {
                            final ok = controller.rotatePlaced(_selectedIndex);
                            setState(() => _message = ok ? null : 'Döndürünce sığmıyor.');
                          },
                          child: const Text('Döndür'),
                        ),
                        OutlinedButton(
                          key: const Key('roomRemove'),
                          onPressed: () {
                            controller.removePlaced(_selectedIndex);
                            setState(() {
                              _selectedIndex = -1;
                              _message = null;
                            });
                          },
                          child: const Text('Kaldır'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Zemin', style: Theme.of(context).textTheme.labelLarge),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < roomFloorColors.length; i++)
                        _ColorDot(
                          key: Key('roomFloor_$i'),
                          color: Color(roomFloorColors[i]),
                          selected: layout.floorColor == i,
                          onTap: () => controller.setRoomFloor(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Duvar', style: Theme.of(context).textTheme.labelLarge),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < roomWallColors.length; i++)
                        _ColorDot(
                          key: Key('roomWall_$i'),
                          color: Color(roomWallColors[i]),
                          selected: layout.wallColor == i,
                          onTap: () => controller.setRoomWall(i),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.black26,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
