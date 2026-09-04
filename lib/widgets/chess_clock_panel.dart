import 'package:flutter/material.dart';

/// Tek bir oyuncunun dijital saati. Sırası gelen tarafınki vurgulanır, son 30
/// saniyede kırmızıya döner.
class ChessClockPanel extends StatelessWidget {
  const ChessClockPanel({
    super.key,
    required this.name,
    required this.remaining,
    required this.isActive,
    required this.isWhite,
  });

  final String name;
  final Duration remaining;
  final bool isActive;
  final bool isWhite;

  static const _panel = Color(0xFF12161F);
  static const _accent = Color(0xFF6C8CFF);
  static const _danger = Color(0xFFE5484D);

  static String formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final low = remaining.inSeconds <= 30;
    final digitColor = low
        ? _danger
        : (isActive ? Colors.white : Colors.white.withValues(alpha: 0.55));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? (low ? _danger : _accent)
              : Colors.white.withValues(alpha: 0.10),
          width: isActive ? 1.6 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isWhite ? Colors.white : const Color(0xFF2A2E36),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: isActive ? 0.85 : 0.5),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatDuration(remaining),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: digitColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
