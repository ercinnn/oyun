import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/memory_match_controller.dart';
import '../models/memory_category.dart';
import '../widgets/memory_category_selector.dart';
import '../widgets/player_count_selector.dart';

class MemorySetupScreen extends StatefulWidget {
  const MemorySetupScreen({super.key});

  @override
  State<MemorySetupScreen> createState() => _MemorySetupScreenState();
}

class _MemorySetupScreenState extends State<MemorySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _player1Controller = TextEditingController(text: '1. Oyuncu');
  final _player2Controller = TextEditingController(text: '2. Oyuncu');
  int _playerCount = 2;
  MemoryCategory _category = MemoryCategory.fruits;

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  void _startGame() {
    if (!_formKey.currentState!.validate()) return;
    context.read<MemoryMatchController>().startGame(
      [
        _player1Controller.text.trim(),
        if (_playerCount == 2) _player2Controller.text.trim(),
      ],
      category: _category,
    );
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
      appBar: AppBar(title: const Text('Kart Eşleştirme')),
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
                    _playerCount == 1
                        ? '$gridColumns x $gridRows\'lik kapalı kartlar '
                              'arasından eşleri bul. Eşleştirirsen devam '
                              'edersin, en az hamlede tüm çiftleri bulmaya '
                              'çalış!'
                        : '$gridColumns x $gridRows\'lik kapalı kartlar '
                              'arasından eşleri bul. Eşleştirirsen sıra '
                              'sende kalır, tutturamazsan sıra rakibine '
                              'geçer. En çok çifti bulan kazanır!',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kategori',
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: MemoryCategorySelector(
                      category: _category,
                      onChanged: (value) =>
                          setState(() => _category = value),
                    ),
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
