import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';
import '../models/color_theme.dart';

class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppThemeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Görünüm', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < standardThemes.length; i++)
              _PresetSwatch(
                theme: standardThemes[i],
                selected: controller.selectedPresetIndex == i,
                onTap: () => controller.selectPreset(i),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Özel renkler',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _ColorRow(
          label: 'Kutu',
          selectedColor: controller.customBoxColor,
          isActive: controller.selectedPresetIndex == null,
          onSelect: controller.selectCustomBoxColor,
        ),
        const SizedBox(height: 8),
        _ColorRow(
          label: 'Arka Plan',
          selectedColor: controller.customBackgroundColor,
          isActive: controller.selectedPresetIndex == null,
          onSelect: controller.selectCustomBackgroundColor,
        ),
        const SizedBox(height: 8),
        _ColorRow(
          label: 'Sayı',
          selectedColor: controller.customNumberColor,
          isActive: controller.selectedPresetIndex == null,
          onSelect: controller.selectCustomNumberColor,
        ),
      ],
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final GameColorTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 76,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          color: theme.backgroundColor,
        ),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.boxColor,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '5',
                style: TextStyle(color: theme.numberColor, fontSize: 14),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              theme.name,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.selectedColor,
    required this.isActive,
    required this.onSelect,
  });

  final String label;
  final Color selectedColor;
  final bool isActive;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in customColorPalette)
                _ColorSwatch(
                  color: color,
                  selected: isActive && color == selectedColor,
                  onTap: () => onSelect(color),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black87 : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
