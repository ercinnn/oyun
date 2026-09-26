import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/profile_controller.dart';
import '../../controllers/scientist_game_controller.dart';
import '../../widgets/player_count_selector.dart';
import 'scientist_game_config.dart';

/// Bilim insanı oyunlarının ortak kurulum ekranı: hikâye, oyuncu sayısı,
/// isimler (1. oyuncu profilden), "Görevleri Başlat" ve keşif atölyesi.
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
    final theme = Theme.of(context);
    final config = widget.config;
    return Scaffold(
      appBar: AppBar(title: Text(config.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    config.banner,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(config.intro, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Görevlerde önce tahmin edersin, sonra deneyi izlersin. '
                    '${widget.controller.roundsPerPlayer} görevde en çok '
                    'doğruyu bilen kazanır.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: PlayerCountSelector(
                      playerCount: _playerCount,
                      onChanged: (value) => setState(() => _playerCount = value),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _player1Controller,
                    decoration: InputDecoration(
                      labelText:
                          _playerCount == 1 ? 'Oyuncu adı' : '1. Oyuncu adı',
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                  if (_playerCount == 2) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _player2Controller,
                      decoration: const InputDecoration(
                        labelText: '2. Oyuncu adı',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateName,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('scientistStart'),
                    onPressed: _startGame,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Görevleri Başlat'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('scientistExplore'),
                    onPressed: widget.controller.startExplore,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('${config.exploreTitle} (puansız)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.exploreHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
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
