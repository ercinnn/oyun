import 'package:flutter/material.dart';

import '../models/game_catalog_entry.dart';
import '../theme/home_palette.dart';
import 'skill_ratings_table.dart';

/// Ana menüdeki tek bir oyun kartı. Yüksekliği ana menünün ızgarası tarafından
/// sabitlenir (bkz. `screens/game_catalog_screen.dart`), bu yüzden açıklama
/// [_descriptionMaxLines] satırla sınırlanır ve alt blok [Spacer] ile kartın
/// dibine yapışır — böylece yan yana duran kartların yıldız tabloları aynı
/// hizada olur.
class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.entry,
    required this.index,
    required this.onTap,
  });

  static const _descriptionMaxLines = 3;

  final GameCatalogEntry entry;

  /// Katalogdaki sırası; kartın sağ üstündeki "01" numarası için.
  final int index;

  final VoidCallback onTap;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final accent = homeAccentOf(entry.color);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HomePalette.surface, HomePalette.surfaceRaised],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? accent.withValues(alpha: 0.55)
                : HomePalette.outline,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? accent.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.35),
              blurRadius: _hovered ? 26 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: accent.withValues(alpha: 0.12),
            highlightColor: accent.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    entry: entry,
                    accent: accent,
                    index: widget.index,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    entry.description,
                    maxLines: GameCard._descriptionMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: HomePalette.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Divider(
                    height: 17,
                    thickness: 1,
                    color: HomePalette.outline,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: SkillRatingsTable(ratings: entry.skills)),
                      const SizedBox(width: 8),
                      _PlayAffordance(accent: accent, active: _hovered),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.entry,
    required this.accent,
    required this.index,
  });

  final GameCatalogEntry entry;
  final Color accent;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, entry.color],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(entry.icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: HomePalette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (index + 1).toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: HomePalette.textMuted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _FocusChip(
                label: entry.skills.dominantSkillLabel,
                accent: accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Oyunun en yüksek puanlı becerisini "HAFIZA ODAKLI" gibi tek satırda
/// özetler; dört satırlık tabloyu okumadan önce bir bakışta oyunun neye
/// çalıştığını söylemesi için.
class _FocusChip extends StatelessWidget {
  const _FocusChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: accent,
        ),
      ),
    );
  }
}

class _PlayAffordance extends StatelessWidget {
  const _PlayAffordance({required this.accent, required this.active});

  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(color: active ? accent : HomePalette.outlineStrong),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        size: 20,
        color: active ? accent : HomePalette.textSecondary,
      ),
    );
  }
}
