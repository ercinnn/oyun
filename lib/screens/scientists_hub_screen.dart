import 'package:flutter/material.dart';

import '../data/scientists_catalog.dart';

/// Bilim insanı seçimi: posterdeki sırayla kartlar. Oyunu hazır olan kart
/// o bilim insanının route'unu açar, diğerleri "Yakında" görünür.
class ScientistsHubScreen extends StatelessWidget {
  const ScientistsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bilim İnsanları')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tarihi değiştiren bilim insanlarından birini seç ve onun '
                'buluşunu kendin deneyerek keşfet!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < scientists.length; i++)
                _ScientistCard(number: i + 1, scientist: scientists[i]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScientistCard extends StatelessWidget {
  const _ScientistCard({required this.number, required this.scientist});

  final int number;
  final Scientist scientist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = scientist;
    final color = s.available ? s.color : Colors.grey;
    return Opacity(
      opacity: s.available ? 1 : 0.6,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          key: Key('scientist_${s.id}'),
          onTap: s.available
              ? () => Navigator.pushNamed(context, s.routeName!)
              : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 6)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(s.emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$number. ${s.name}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(s.discovery, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(s.summary, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                s.available
                    ? Icon(Icons.play_circle_fill, color: color, size: 36)
                    : const Chip(
                        label: Text('Yakında'),
                        visualDensity: VisualDensity.compact,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
