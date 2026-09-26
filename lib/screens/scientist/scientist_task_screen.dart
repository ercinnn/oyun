import 'package:flutter/material.dart';

import '../../controllers/scientist_game_controller.dart';
import '../../models/science/science_task.dart';
import '../../widgets/science_lab/lab_labels.dart';
import '../../widgets/science_lab/lab_split_layout.dart';
import '../../widgets/science_lab/lab_style.dart';
import '../../widgets/science_lab/scientist_name_badge.dart';
import '../../widgets/science_lab/scientist_progress.dart';
import '../../widgets/science_lab/scientist_sound_toggle.dart';

/// Görev turu: deney sahnesi + soru ya da sonuç paneli. Sahne widget'ı
/// turlar boyunca aynı yerde kalır ki 3B görünüm her turda baştan kurulmasın.
///
/// Panel üç adımı görünür kılar (tahmin et → deneyi izle → öğren): önce soru
/// ve büyük seçenek kartları; cevaptan sonra seçenekler yerinde kalır (doğru
/// olan yeşil, yanlış seçilen turuncu), altında sonuç kartı açılır.
class ScientistTaskScreen extends StatelessWidget {
  const ScientistTaskScreen({
    super.key,
    required this.controller,
    required this.scene,
  });

  final ScientistGameController controller;
  final Widget scene;

  @override
  Widget build(BuildContext context) {
    final player = controller.currentPlayer;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.players.length == 1
              ? '${player.name} oynuyor'
              : 'Sıra: ${player.name}',
        ),
        actions: [ScientistSoundToggle(controller: controller)],
      ),
      body: LabSplitLayout(
        scene: KeyedSubtree(key: const Key('scientistScene'), child: scene),
        panel: _TaskPanel(controller: controller),
      ),
    );
  }
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({required this.controller});

  final ScientistGameController controller;

  @override
  Widget build(BuildContext context) {
    final task = controller.currentTask;
    final player = controller.currentPlayer;
    final round =
        controller.showingResult ? player.roundsPlayed : player.roundsPlayed + 1;
    final accent =
        ScientistIdentity.maybeOf(context)?.color ?? Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Görev $round / ${controller.roundsPerPlayer}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            ScoreChip(correct: player.correctCount),
          ],
        ),
        const SizedBox(height: 6),
        RoundDots(
          key: const Key('scientistRoundDots'),
          total: controller.roundsPerPlayer,
          results: player.results,
          current: controller.showingResult ? null : player.roundsPlayed,
        ),
        const SizedBox(height: 10),
        _FlowStrip(answered: controller.showingResult, accent: accent),
        const SizedBox(height: 10),
        _QuestionCard(task: task, accent: accent),
        const SizedBox(height: 10),
        _Options(controller: controller),
        if (controller.showingResult) ...[
          const SizedBox(height: 6),
          _ResultCard(
            key: ValueKey('result-${player.name}-$round'),
            controller: controller,
          ),
        ],
      ],
    );
  }
}

/// ① Tahmin et → ② Deneyi izle → ③ Öğren: çocuğun şu an hangi adımda
/// olduğunu gösterir.
class _FlowStrip extends StatelessWidget {
  const _FlowStrip({required this.answered, required this.accent});

  final bool answered;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.psychology_alt, 'Tahmin et'),
      (Icons.visibility, 'Deneyi izle'),
      (Icons.school, 'Öğren'),
    ];
    return Container(
      key: const Key('scientistFlow'),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
            Expanded(
              child: _FlowStep(
                icon: steps[i].$1,
                label: steps[i].$2,
                state: answered
                    ? (i == 0 ? _StepState.done : _StepState.active)
                    : (i == 0 ? _StepState.active : _StepState.upcoming),
                accent: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _StepState { done, active, upcoming }

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.icon,
    required this.label,
    required this.state,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final _StepState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final active = state == _StepState.active;
    final color = switch (state) {
      _StepState.done => Colors.green.shade700,
      _StepState.active => accent,
      _StepState.upcoming => Colors.grey.shade500,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? accent : color.withValues(alpha: 0.12),
          ),
          child: Icon(
            state == _StepState.done ? Icons.check : icon,
            size: 18,
            color: active ? Colors.white : color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.task, required this.accent});

  final ScienceTask task;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final question = task.ask;
    final hint = task.hint;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: accent,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  task.prompt,
                  style: TextStyle(
                    fontSize: question == null ? LabText.question - 1 : LabText.prompt,
                    fontWeight: question == null ? FontWeight.w600 : FontWeight.normal,
                    height: LabText.bodyHeight,
                  ),
                ),
                if (question != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.help, color: accent, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            question,
                            style: const TextStyle(
                              fontSize: LabText.question,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hint != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blueGrey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hint,
                          style: TextStyle(
                            fontSize: LabText.caption,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({required this.controller});

  final ScientistGameController controller;

  @override
  Widget build(BuildContext context) {
    final task = controller.currentTask;
    final options = task.options;
    final emojis = task.optionEmojis;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Kısa seçenekler (Yüzer/Batar, 30°…) geniş panelde iki sütun olur.
        final short = options.every((o) => o.length <= 14);
        final columns = short && constraints.maxWidth >= 300 ? 2 : 1;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < options.length; i++)
              SizedBox(
                width: width,
                child: _OptionTile(
                  key: Key('scientistOption_$i'),
                  index: i,
                  text: options[i],
                  emoji: emojis != null && i < emojis.length ? emojis[i] : null,
                  state: !controller.showingResult
                      ? _OptionState.open
                      : i == task.correctIndex
                      ? _OptionState.correct
                      : i == controller.lastAnswerIndex
                      ? _OptionState.wrong
                      : _OptionState.dimmed,
                  onTap: controller.showingResult ? null : () => controller.answer(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _OptionState { open, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.emoji,
    required this.state,
    required this.onTap,
  });

  final int index;
  final String text;
  final String? emoji;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    final letterColor = labTagColor(letter);
    final (background, border, trailing) = switch (state) {
      _OptionState.open => (Colors.white, letterColor.withValues(alpha: 0.45), null),
      _OptionState.correct => (
        Colors.green.shade50,
        Colors.green.shade600,
        Icon(Icons.check_circle, color: Colors.green.shade600, size: 26),
      ),
      _OptionState.wrong => (
        Colors.deepOrange.shade50,
        Colors.deepOrange.shade400,
        Icon(Icons.cancel, color: Colors.deepOrange.shade400, size: 26),
      ),
      _OptionState.dimmed => (Colors.grey.shade100, Colors.grey.shade300, null),
    };
    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.55 : 1,
      child: Material(
        color: background,
        elevation: state == _OptionState.open ? 1.5 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: emoji == null ? letterColor : Colors.white,
                      border: emoji == null
                          ? null
                          : Border.all(color: letterColor, width: 2),
                    ),
                    // Emoji'ye renk verilmez: tek renkli çizilen emoji
                    // (⚓ gibi) beyaz yazıyla zeminde kayboluyordu.
                    child: emoji == null
                        ? Text(
                            letter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : Text(
                            emoji!,
                            style: const TextStyle(
                              fontSize: 19,
                              color: Color(0xFF263238),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: LabText.option,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cevaptan sonra açılan kart: kısa bir kutlama, "Öğrendik" satırı ve
/// açıklama. Açılınca kendini görünür alana kaydırır (telefonda panel
/// kaydırılabilir; kart ekranın altında kalıp gözden kaçmasın).
class _ResultCard extends StatefulWidget {
  const _ResultCard({super.key, required this.controller});

  final ScientistGameController controller;

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final task = controller.currentTask;
    final correct = controller.lastAnswerCorrect;
    final color = correct ? Colors.green : Colors.deepOrange;
    final takeaway = task.takeaway;
    final lastRound = controller.currentPlayer.roundsPlayed >= controller.roundsPerPlayer;
    return Card(
      color: color.shade50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (context, t, child) =>
                      Transform.scale(scale: 0.4 + 0.6 * t, child: child),
                  child: Icon(
                    correct ? Icons.stars : Icons.lightbulb,
                    color: correct ? Colors.amber.shade700 : color.shade700,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    correct ? 'Doğru! Harika tahmin.' : 'Az kaldı!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (!correct) ...[
              const SizedBox(height: 6),
              Text(
                'Doğru cevap: ${task.options[task.correctIndex]}',
                style: TextStyle(
                  fontSize: LabText.body,
                  fontWeight: FontWeight.w600,
                  color: color.shade900,
                ),
              ),
            ],
            if (takeaway != null) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('scientistTakeaway'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Öğrendik: ',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            TextSpan(text: takeaway),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: LabText.body + 1,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              task.explanation(controller.lastAnswerIndex!),
              key: const Key('scientistExplanation'),
              style: const TextStyle(fontSize: LabText.body, height: LabText.bodyHeight),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('scientistContinue'),
              onPressed: controller.continueAfterResult,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              icon: Icon(lastRound ? Icons.flag : Icons.arrow_forward),
              label: const Text('Devam'),
            ),
          ],
        ),
      ),
    );
  }
}
