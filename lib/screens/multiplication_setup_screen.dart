import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/multiplication_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/multiplication_context.dart';
import '../models/multiplication_difficulty.dart';
import '../widgets/multiplication_difficulty_selector.dart';
import '../widgets/player_count_selector.dart';

class MultiplicationSetupScreen extends StatefulWidget {
  const MultiplicationSetupScreen({super.key});

  @override
  State<MultiplicationSetupScreen> createState() =>
      _MultiplicationSetupScreenState();
}

class _MultiplicationSetupScreenState extends State<MultiplicationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _player1Controller;
  final _player2Controller = TextEditingController(text: '2. Oyuncu');
  int _playerCount = 2;
  MultiplicationDifficulty _difficulty = MultiplicationDifficulty.kolay;

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
    context.read<MultiplicationController>().startGame([
      _player1Controller.text.trim(),
      if (_playerCount == 2) _player2Controller.text.trim(),
    ], difficulty: _difficulty);
  }

  /// Seçili seviyenin sahnelerinden birkaçının adı ("Yumurta kolisi ·
  /// Bisiklet tekerlekleri · …"). Tamamı yazılsa kurulum ekranı bir metin
  /// duvarına dönerdi; kaçının sığdığını sahne sayısı değil okunabilirlik
  /// belirliyor.
  static String _sceneExamples(MultiplicationDifficulty difficulty) {
    final scenes = multiplicationContextsFor(difficulty);
    final shown = scenes.take(4).map((scene) => scene.title).join(' · ');
    return scenes.length > 4 ? '$shown ve ${scenes.length - 4} sahne daha' : shown;
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
      appBar: AppBar(title: const Text('Çarpım Bahçesi')),
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
                  const Text(
                    '3 × 4 demek, 4 tanesini üç kere almak demek! Her tur '
                    'gerçek hayattan bir sahnede geçer: bazılarında '
                    'sahnedeki nesneleri sayacaksın, bazılarında sahneyi sen '
                    'kuracaksın.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$multiplicationRoundsPerPlayer turda en çok doğruyu '
                    'bilen kazanır.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: PlayerCountSelector(
                      playerCount: _playerCount,
                      onChanged: (value) =>
                          setState(() => _playerCount = value),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Zorluk: ${_difficulty.hint}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: MultiplicationDifficultySelector(
                      difficulty: _difficulty,
                      onChanged: (value) =>
                          setState(() => _difficulty = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Seviye seçimi sadece sayıları değil, hangi gerçek hayat
                  // sahnelerinin çıkacağını da belirliyor; oyuncu neyi seçtiğini
                  // görebilsin diye o seviyenin sahneleri burada listeleniyor.
                  Text(
                    'Sahneler: ${_sceneExamples(_difficulty)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
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
