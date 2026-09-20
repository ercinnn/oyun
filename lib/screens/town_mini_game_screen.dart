import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';
import '../widgets/iso_world_view.dart';
import '../widgets/town_hud.dart';

/// Bir mini oyun turu: dünya + süre/durum rozetleri; bitince sonuç kartı.
class TownMiniGameScreen extends StatelessWidget {
  const TownMiniGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TownController>();
    final session = controller.session;
    if (session == null) return const Scaffold();

    final String title;
    if (controller.contest) {
      title = '${controller.currentPlayer.name} · ${session.kind.title}';
    } else {
      title = session.kind.title;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        leading: controller.contest
            ? null
            : BackButton(onPressed: controller.backToTown),
        automaticallyImplyLeading: false,
      ),
      body: IsoWorldView(
        world: session.world,
        avatar: controller.profile.avatar,
        frame: controller.frame,
        onTick: controller.tick,
        onInput: controller.setInput,
        onTapTile: controller.tapTile,
        overlay: [
          Positioned(
            top: 12,
            left: 12,
            child: HudBadge(
              textKey: const Key('miniTime'),
              text: 'Süre: ${session.timeLeft.ceil()}',
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: HudBadge(
              textKey: const Key('miniStatus'),
              text: session.statusText,
            ),
          ),
          if (session.finished)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x88000000),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            session.timeLeft <= 0 ? 'Süre doldu!' : 'Bitirdin!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Puanın: ${session.score}',
                            key: const Key('miniScore'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (!controller.contest) ...[
                            const SizedBox(height: 4),
                            Text('Ödül: ${session.rewardCoins} altın'),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('townMiniContinue'),
                            onPressed: controller.continueAfterMiniGame,
                            child: const Text('Devam'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
