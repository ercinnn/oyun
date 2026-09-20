import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/profile_controller.dart';
import '../controllers/town_controller.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/player_count_selector.dart';

class TownSetupScreen extends StatefulWidget {
  const TownSetupScreen({super.key});

  @override
  State<TownSetupScreen> createState() => _TownSetupScreenState();
}

class _TownSetupScreenState extends State<TownSetupScreen> {
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

  void _startContest() {
    if (!_formKey.currentState!.validate()) return;
    context.read<TownController>().startContest([
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
    final controller = context.watch<TownController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Renkli Kasaba')),
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
                  Center(
                    child: AvatarPreview(
                      spec: controller.profile.avatar,
                      size: 110,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kendi kasabanda gez, altın ve yıldız topla, avatarını '
                    'giydir, odanı döşe ve mini oyunlar oyna!',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bu oyun tek cihazda oynanır; internet, sohbet ya da gerçek '
                    'para yoktur.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('townEnter'),
                    onPressed: controller.enterTown,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Kasabaya Gir'),
                    ),
                  ),
                  const Divider(height: 40),
                  Text(
                    'Mini Oyun Yarışı: her oyuncu üç mini oyunu oynar, '
                    'toplam puanı en yüksek olan kazanır.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  OutlinedButton(
                    key: const Key('townContest'),
                    onPressed: _startContest,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Mini Oyun Yarışını Başlat'),
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
