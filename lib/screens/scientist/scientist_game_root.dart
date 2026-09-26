import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/scientist_game_controller.dart';
import '../../models/science/scientist_phase.dart';
import '../../widgets/science_lab/scientist_name_badge.dart';
import '../../widgets/science_lab/scientist_progress.dart';
import 'scientist_game_config.dart';
import 'scientist_setup_screen.dart';
import 'scientist_task_screen.dart';

/// Bir bilim insanı oyununun faza göre ekran seçen kökü. Kurulum, görev,
/// sıra devri ve sonuç ekranları ortaktır; her bilim insanı yalnızca kendi
/// deney sahnesini ([sceneBuilder]) ve keşif atölyesini ([exploreBuilder])
/// verir. Controller'ı üstteki `ChangeNotifierProvider<C>`'den okur.
class ScientistGameRoot<C extends ScientistGameController>
    extends StatelessWidget {
  const ScientistGameRoot({
    super.key,
    required this.config,
    required this.sceneBuilder,
    required this.exploreBuilder,
  });

  final ScientistGameConfig config;
  final Widget Function(C controller) sceneBuilder;
  final Widget Function(C controller) exploreBuilder;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<C>();
    final Widget screen = switch (controller.phase) {
      ScientistPhase.setup =>
        ScientistSetupScreen(controller: controller, config: config),
      ScientistPhase.playing => ScientistTaskScreen(
        controller: controller,
        scene: sceneBuilder(controller),
      ),
      ScientistPhase.turnTransition =>
        _TurnTransition(controller: controller, config: config),
      ScientistPhase.finished => _Results(controller: controller, config: config),
      ScientistPhase.explore => exploreBuilder(controller),
    };
    // Sahneli ekranlar (görev, keşif) bilim insanının adını buradan okuyup
    // sol üste yazar (`LabSplitLayout`).
    return ScientistIdentity(scientist: config.scientist, child: screen);
  }
}

class _TurnTransition extends StatelessWidget {
  const _TurnTransition({required this.controller, required this.config});

  final ScientistGameController controller;
  final ScientistGameConfig config;

  @override
  Widget build(BuildContext context) {
    final color = config.scientist.color;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScientistNameBadge(scientist: config.scientist),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 44,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(Icons.swap_horiz, size: 52, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                'Sıra ${controller.currentPlayer.name}\'de!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cihazı sıradaki oyuncuya ver.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: controller.acknowledgeTurnTransition,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Hazırım'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.controller, required this.config});

  final ScientistGameController controller;
  final ScientistGameConfig config;

  @override
  Widget build(BuildContext context) {
    final ranked = controller.rankedByCorrect;
    final winner = ranked.first;
    final isTie =
        ranked.length > 1 && ranked[1].correctCount == winner.correctCount;
    final String headline = ranked.length == 1
        ? 'Tebrikler, ${winner.name}!'
        : (isTie ? 'Berabere!' : '${winner.name} kazandı!');
    final color = config.scientist.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Sonuçlar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: ScientistNameBadge(scientist: config.scientist)),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, t, child) =>
                      Transform.scale(scale: 0.3 + 0.7 * t, child: child),
                  child: Icon(Icons.emoji_events, size: 80, color: Colors.amber.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                for (final player in ranked)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  player.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${player.correctCount} / '
                                '${controller.roundsPerPlayer} doğru',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RoundDots(
                            total: controller.roundsPerPlayer,
                            results: player.results,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          config.moral,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: controller.restart,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.replay),
                  label: const Text('Tekrar Oyna'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('scientistResultsExplore'),
                  onPressed: controller.startExplore,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.explore),
                  label: const Text('Keşfe geç'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
