import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/profile_controller.dart';
import '../controllers/stroop_controller.dart';
import '../widgets/player_count_selector.dart';

class StroopSetupScreen extends StatefulWidget {
  const StroopSetupScreen({super.key});

  @override
  State<StroopSetupScreen> createState() => _StroopSetupScreenState();
}

class _StroopSetupScreenState extends State<StroopSetupScreen> {
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
    context.read<StroopController>().startGame([
      _player1Controller.text.trim(),
      if (_playerCount == 2) _player2Controller.text.trim(),
    ]);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'İsim boş olamaz';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Renk mi Kelime mi?')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ekranda bir renk adı yazacak ama YAZININ RENGİ farklı '
                    'olabilir. Kelimeyi değil, yazının gerçek rengini seç! '
                    '$roundsPerPlayer turda en çok doğruyu bilen kazanır.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: PlayerCountSelector(
                      playerCount: _playerCount,
                      onChanged: (value) =>
                          setState(() => _playerCount = value),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    onPressed: _startGame,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Oyunu Başlat'),
                    ),
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
