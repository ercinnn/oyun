import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/profile_controller.dart';
import '../../controllers/scientist_game_controller.dart';
import '../../widgets/player_count_selector.dart';
import '../../widgets/science_lab/scientist_name_badge.dart';
import '../../widgets/science_lab/scientist_sound_toggle.dart';
import 'scientist_game_config.dart';

/// Bilim insanı oyunlarının ortak kurulum ekranı: renkli başlıkta hikâye,
/// "nasıl oynanır" şeridi ve iki büyük mod kartı — puanlı Görevler (oyuncu
/// sayısı + isimler, 1. oyuncu profilden) ve puansız keşif atölyesi.
class ScientistSetupScreen extends StatefulWidget {
  const ScientistSetupScreen({
    super.key,
    required this.controller,
    required this.config,
  });

  final ScientistGameController controller;
  final ScientistGameConfig config;

  @override
  State<ScientistSetupScreen> createState() => _ScientistSetupScreenState();
}

class _ScientistSetupScreenState extends State<ScientistSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _player1Controller;
  final _player2Controller = TextEditingController(text: '2. Oyuncu');
  int _playerCount = 2;

  @override
  void initState() {
    super.initState();
    final profileName = context.read<ProfileController>().name;
    _player1Controller = TextEditingController(
      text: profileName.isNotEmpty ? profileName : '1. Oyuncu',
    );
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  void _startGame() {
    if (!_formKey.currentState!.validate()) return;
    widget.controller.startGame([
      _player1Controller.text.trim(),
      if (_playerCount == 2) _player2Controller.text.trim(),
    ]);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'İsim boş olamaz';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final color = config.scientist.color;
    return Scaffold(
      appBar: AppBar(
        title: Text(config.title),
        actions: [ScientistSoundToggle(controller: widget.controller)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final hero = [
            _Hero(config: config),
            const SizedBox(height: 14),
            _HowToPlay(color: color),
          ];
          final modes = [
            _ModeCard(
              color: color,
              icon: Icons.emoji_events,
              title: 'Görevler',
              subtitle:
                  '${widget.controller.roundsPerPlayer} soru. Önce tahmin et, '
                  'sonra deneyi izle. En çok doğruyu bilen kazanır.',
              children: [
                Center(
                  child: PlayerCountSelector(
                    playerCount: _playerCount,
                    onChanged: (value) => setState(() => _playerCount = value),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _player1Controller,
                  decoration: InputDecoration(
                    labelText: _playerCount == 1
                        ? 'Oyuncu adı'
                        : '1. Oyuncu adı',
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                if (_playerCount == 2) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _player2Controller,
                    decoration: const InputDecoration(
                      labelText: '2. Oyuncu adı',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const Key('scientistStart'),
                  onPressed: _startGame,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 26),
                  label: const Text('Görevleri Başlat'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ModeCard(
              color: Colors.teal,
              icon: Icons.science,
              // Birçok bilim insanında keşif adı ekran başlığıyla aynı
              // ("Tesla'nın Laboratuvarı"); tekrar etmesin.
              title: 'Serbest Keşif',
              subtitle: '${config.exploreHint} Puan yok, istediğin kadar dene.',
              children: [
                OutlinedButton.icon(
                  key: const Key('scientistExplore'),
                  onPressed: widget.controller.startExplore,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.teal.shade400, width: 2),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.explore),
                  label: const Text('Keşfe Başla'),
                ),
              ],
            ),
          ];
          // Geniş ekranda hikâye solda, modlar sağda: iki düğme de kaydırmadan
          // görünür.
          final wide = constraints.maxWidth >= 860;
          return Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1000 : 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: hero,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: modes,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...hero,
                            const SizedBox(height: 14),
                            ...modes,
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bilim insanının renginde başlık: ad etiketi, emoji şeridi ve hikâye.
class _Hero extends StatelessWidget {
  const _Hero({required this.config});

  final ScientistGameConfig config;

  @override
  Widget build(BuildContext context) {
    final color = config.scientist.color;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ScientistNameBadge(scientist: config.scientist),
          ),
          const SizedBox(height: 10),
          Text(
            config.banner,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 44),
          ),
          const SizedBox(height: 8),
          Text(
            config.intro,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Üç ikonlu "nasıl oynanır" şeridi.
class _HowToPlay extends StatelessWidget {
  const _HowToPlay({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.psychology_alt, 'Tahmin et', 'Sence ne olacak?'),
      (Icons.visibility, 'Deneyi izle', 'Sahnede gerçekleşir.'),
      (Icons.school, 'Öğren', 'Nedenini oku.'),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(steps[i].$1, color: color, size: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  '${i + 1}. ${steps[i].$2}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  steps[i].$3,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Oyun modu kartı (Görevler / Keşif).
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 15, height: 1.35)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
