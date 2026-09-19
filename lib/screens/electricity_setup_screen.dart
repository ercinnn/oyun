import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/electricity_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/player_count_selector.dart';

class ElectricitySetupScreen extends StatefulWidget {
  const ElectricitySetupScreen({super.key});

  @override
  State<ElectricitySetupScreen> createState() => _ElectricitySetupScreenState();
}

class _ElectricitySetupScreenState extends State<ElectricitySetupScreen> {
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
    context.read<ElectricityController>().startGame([
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
    final controller = context.read<ElectricityController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Elektrik Atölyesi')),
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
                    'Pil, ampul, kablo ve anahtarla elektriğin nasıl çalıştığını '
                    'keşfet! Devreleri tahmin et, malzemeleri dene, kablo yolunu '
                    'bul, şehre enerji sağla ve güvenli davranışları öğren.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Görevlerde $electricRoundsPerPlayer turda en çok doğruyu '
                    'bilen kazanır. Bütün deneyler pille yapılır; gerçek prizle '
                    'asla deney yapma!',
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
                    key: const Key('electricityStart'),
                    onPressed: _startGame,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Görevleri Başlat'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('electricityFreeCircuit'),
                    onPressed: controller.startFreeCircuit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Serbest Devre Atölyesi (puansız)'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('electricityWireLevels'),
                    onPressed: controller.startWireLevels,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Kablo Yolu Seviyeleri (puansız)'),
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
