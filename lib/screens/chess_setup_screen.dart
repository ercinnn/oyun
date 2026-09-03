import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chess_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/chess_mode.dart';
import '../models/chess_piece.dart';
import '../widgets/player_count_selector.dart';

class ChessSetupScreen extends StatefulWidget {
  const ChessSetupScreen({super.key});

  @override
  State<ChessSetupScreen> createState() => _ChessSetupScreenState();
}

class _ChessSetupScreenState extends State<ChessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _soloNameController;
  late final TextEditingController _whiteNameController;
  final _blackNameController = TextEditingController(text: '2. Oyuncu');
  int _playerCount = 2;
  PieceColor _humanColor = PieceColor.white;

  @override
  void initState() {
    super.initState();
    final profileName = context.read<ProfileController>().name;
    final defaultName = profileName.isNotEmpty ? profileName : '1. Oyuncu';
    _soloNameController = TextEditingController(text: defaultName);
    _whiteNameController = TextEditingController(text: defaultName);
  }

  @override
  void dispose() {
    _soloNameController.dispose();
    _whiteNameController.dispose();
    _blackNameController.dispose();
    super.dispose();
  }

  void _startGame() {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<ChessController>();
    if (_playerCount == 1) {
      controller.startGame(
        mode: ChessMode.vsAi,
        whiteName: _humanColor == PieceColor.white
            ? _soloNameController.text.trim()
            : 'Bilgisayar',
        blackName: _humanColor == PieceColor.black
            ? _soloNameController.text.trim()
            : 'Bilgisayar',
        humanColor: _humanColor,
      );
    } else {
      controller.startGame(
        mode: ChessMode.twoPlayer,
        whiteName: _whiteNameController.text.trim(),
        blackName: _blackNameController.text.trim(),
      );
    }
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
      appBar: AppBar(title: const Text('Satranç')),
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
                    'Bilgisayara karşı ya da aynı cihazda karşılıklı klasik '
                    'satranç oyna. Sıra kime geçerse tahta ona göre döner.',
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
                  if (_playerCount == 1) ...[
                    TextFormField(
                      controller: _soloNameController,
                      decoration: const InputDecoration(
                        labelText: 'Oyuncu adı',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SegmentedButton<PieceColor>(
                        segments: const [
                          ButtonSegment(
                            value: PieceColor.white,
                            label: Text('Beyaz'),
                            icon: Icon(Icons.circle_outlined),
                          ),
                          ButtonSegment(
                            value: PieceColor.black,
                            label: Text('Siyah'),
                            icon: Icon(Icons.circle),
                          ),
                        ],
                        selected: {_humanColor},
                        onSelectionChanged: (selection) =>
                            setState(() => _humanColor = selection.first),
                      ),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _whiteNameController,
                      decoration: const InputDecoration(
                        labelText: 'Beyaz Oyuncu adı',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _blackNameController,
                      decoration: const InputDecoration(
                        labelText: 'Siyah Oyuncu adı',
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
