import 'package:flutter/material.dart';

import 'lab_style.dart';
import 'scientist_name_badge.dart';

/// Keşif ekranlarında "ne yapmalıyım?" sorusunun cevabı: numaralı adımlar.
/// İlk bitmemiş adım "Şimdi" diye vurgulanır, bitenler ✓ alır. Adımların
/// [LabStep.done] bayrakları controller durumundan türetilir.
class LabStep {
  const LabStep(this.text, {this.done = false});

  final String text;
  final bool done;
}

/// Yer kazanmak için varsayılan olarak yalnızca **şimdiki** adımı ve
/// ilerleme noktalarını gösterir (telefonda ana eylem düğmesi ekranın altına
/// düşmesin); başlığa dokununca tüm adımlar açılır.
class LabStepList extends StatefulWidget {
  const LabStepList({
    super.key,
    required this.steps,
    this.doneMessage = 'Hepsini denedin! Şimdi kendi deneyini uydur.',
  });

  final List<LabStep> steps;
  final String doneMessage;

  @override
  State<LabStepList> createState() => _LabStepListState();
}

class _LabStepListState extends State<LabStepList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final accent = _accent(context);
    final current = steps.indexWhere((s) => !s.done);
    final doneCount = steps.where((s) => s.done).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('labStepsToggle'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.explore, size: 20, color: accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Adım adım',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (var i = 0; i < steps.length; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: steps[i].done
                            ? Colors.green.shade600
                            : i == current
                            ? accent
                            : Colors.grey.shade300,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '$doneCount/${steps.length}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < steps.length; i++)
            if (_expanded || i == current)
              _StepRow(
                number: i + 1,
                step: steps[i],
                current: i == current,
                accent: accent,
              ),
          if (current == -1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.amber.shade700, size: 22),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.doneMessage,
                      style: const TextStyle(
                        fontSize: LabText.caption + 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.step,
    required this.current,
    required this.accent,
  });

  final int number;
  final LabStep step;
  final bool current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final done = step.done;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: current ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: current ? Border.all(color: accent, width: 2) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: done
                ? Colors.green.shade600
                : current
                ? accent
                : Colors.grey.shade300,
            child: done
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: current ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                step.text,
                style: TextStyle(
                  fontSize: LabText.caption + 1,
                  height: 1.3,
                  fontWeight: current ? FontWeight.bold : FontWeight.normal,
                  color: done ? Colors.grey.shade600 : Colors.black87,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.grey.shade500,
                ),
              ),
            ),
          ),
          if (current)
            Container(
              margin: const EdgeInsets.only(left: 6, top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Şimdi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Keşif atölyesindeki bir istasyon: seçicide emoji + ad, altında ne
/// yapıldığını anlatan tek satır.
class LabStation<T> {
  const LabStation(this.value, this.label, this.emoji, this.description);

  final T value;
  final String label;
  final String emoji;
  final String description;
}

/// İstasyon seçici: büyük emojili kartlar + seçili istasyonun açıklaması.
/// Kartlardaki ad metni istasyonun `label`'ıdır (testler adla dokunur);
/// açıklama adı tekrar etmez.
class LabStationPicker<T> extends StatelessWidget {
  const LabStationPicker({
    super.key,
    required this.stations,
    required this.selected,
    required this.onSelected,
  });

  final List<LabStation<T>> stations;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final current = stations.firstWhere(
      (s) => s.value == selected,
      orElse: () => stations.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < stations.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _StationCard(
                  station: stations[i],
                  selected: stations[i].value == selected,
                  accent: accent,
                  onTap: () => onSelected(stations[i].value),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          current.description,
          key: const Key('labStationDescription'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: LabText.caption,
            color: Colors.blueGrey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _StationCard<T> extends StatelessWidget {
  const _StationCard({
    required this.station,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final LabStation<T> station;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? accent : Colors.grey.shade300,
          width: selected ? 2.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(station.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 2),
              Text(
                station.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? labStrongColor(accent) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İstasyonun ana eylemi (Suya bırak, Bırak!, İt!…): tam genişlikte büyük
/// düğme; ikincil ayarlar bunun altında kalır.
class LabActionButton extends StatelessWidget {
  const LabActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _accent(context),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      icon: Icon(icon, size: 24),
      label: Text(label),
    );
  }
}

/// Başlık satırı: panel bölümlerini ayırır ("1. Cismi seç").
class LabSectionTitle extends StatelessWidget {
  const LabSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}

Color _accent(BuildContext context) =>
    ScientistIdentity.maybeOf(context)?.color ??
    Theme.of(context).colorScheme.primary;
