import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/scientist_game_controller.dart';
import '../../models/science/scientist_phase.dart';
import '../../widgets/science_lab/scientist_name_badge.dart';
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
      ScientistPhase.turnTransition => _TurnTransition(controller: controller),
      ScientistPhase.finished => _Results(controller: controller, config: config),
      ScientistPhase.explore => exploreBuilder(controller),
    };
    // Sahneli ekranlar (görev, keşif) bilim insanının adını buradan okuyup
    // sol üste yazar (`LabSplitLayout`).
    return ScientistIdentity(scientist: config.scientist, child: screen);
  }
}

class _TurnTransition extends StatelessWidget {
  const _TurnTransition({required this.controller});

  final ScientistGameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, size: 64),
              const SizedBox(height: 16),
              Text(
                'Sıra ${controller.currentPlayer.name}\'de!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cihazı sıradaki oyuncuya ver.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: controller.acknowledgeTurnTransition,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Hazırım'),
                ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Sonuçlar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScientistNameBadge(scientist: config.scientist),
                const SizedBox(height: 16),
                Icon(Icons.emoji_events, size: 64, color: Colors.amber.shade700),
                const SizedBox(height: 12),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(config.moral, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                for (final player in ranked)
                  Card(
                    child: ListTile(
                      title: Text(player.name),
                      trailing: Text(
                        '${player.correctCount} / '
                        '${controller.roundsPerPlayer} doğru',
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: controller.restart,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text('Tekrar Oyna'),
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
