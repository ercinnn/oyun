import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chess_controller.dart';
import '../controllers/profile_controller.dart';
import '../data/chess_room_service.dart';
import '../data/supabase_chess_room_service.dart';
import '../models/chess_mode.dart';
import '../models/chess_piece.dart';
import '../models/chess_time_control.dart';

/// Oda kodu ile internetten (farklı cihazlardan) eşleşme ekranı. [controller]
/// zaten var olan `ChessController`'dır (Provider ile değil, doğrudan
/// aktarılır — bu ekran `Navigator`'a ayrı bir route olarak push edildiği
/// için `ChessGame`'in kendi `ChangeNotifierProvider`'ının kapsamı dışında
/// kalır, bkz. plan notu).
class ChessOnlineSetupScreen extends StatefulWidget {
  ChessOnlineSetupScreen({super.key, required this.controller, ChessRoomService? roomService})
    : roomService = roomService ?? SupabaseChessRoomService();

  final ChessController controller;
  final ChessRoomService roomService;

  @override
  State<ChessOnlineSetupScreen> createState() => _ChessOnlineSetupScreenState();
}

enum _OnlineForm { create, join }

class _ChessOnlineSetupScreenState extends State<ChessOnlineSetupScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  _OnlineForm _form = _OnlineForm.create;
  ChessTimeControl _timeControl = ChessTimeControl.unlimited;
  bool _busy = false;
  String? _error;
  String? _waitingCode;
  StreamSubscription<ChessRoomInfo>? _waitSubscription;

  @override
  void initState() {
    super.initState();
    final profileName = context.read<ProfileController>().name;
    _nameController.text = profileName.isNotEmpty ? profileName : '1. Oyuncu';
  }

  @override
  void dispose() {
    _waitSubscription?.cancel();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _cancelWaiting() {
    _waitSubscription?.cancel();
    _waitSubscription = null;
    setState(() {
      _waitingCode = null;
      _busy = false;
    });
  }

  Future<void> _createRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'İsim boş olamaz');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await widget.roomService.createRoom(
        hostName: name,
        timeControl: _timeControl,
      );
      if (!mounted) return;
      setState(() => _waitingCode = info.code);
      _waitSubscription = widget.roomService.watchRoom(info.code).listen(
        (update) {
          if (update.hasGuest) {
            _waitSubscription?.cancel();
            _waitSubscription = null;
            _beginGame(
              code: info.code,
              humanColor: PieceColor.white,
              whiteName: name,
              blackName: update.guestName!,
              timeControl: info.timeControl,
            );
          }
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _error = 'Bağlantı sorunu oluştu, tekrar deneyin.');
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Oda kurulamadı, internet bağlantınızı kontrol edin.';
      });
    }
  }

  Future<void> _joinRoom() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (name.isEmpty) {
      setState(() => _error = 'İsim boş olamaz');
      return;
    }
    if (code.isEmpty) {
      setState(() => _error = 'Oda kodu boş olamaz');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await widget.roomService.joinRoom(code: code, guestName: name);
      if (!mounted) return;
      _beginGame(
        code: code,
        humanColor: PieceColor.black,
        whiteName: info.hostName,
        blackName: name,
        timeControl: info.timeControl,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Oda bulunamadı, kodu kontrol edin.';
      });
    }
  }

  void _beginGame({
    required String code,
    required PieceColor humanColor,
    required String whiteName,
    required String blackName,
    required ChessTimeControl timeControl,
  }) {
    final controller = widget.controller;
    controller.onLocalMove = (move) {
      final payload = [
        for (final m in controller.board.moveHistory)
          ChessRoomMove(from: m.from, to: m.to, promotionType: m.promotionType),
      ];
      unawaited(widget.roomService.pushMove(code, payload).catchError((_) {}));
    };
    controller.networkSubscription = widget.roomService
        .watchRoom(code)
        .listen((update) => _applyRemoteMoves(controller, update), onError: (_) {});
    controller.startGame(
      mode: ChessMode.online,
      whiteName: whiteName,
      blackName: blackName,
      humanColor: humanColor,
      timeControl: timeControl,
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _applyRemoteMoves(ChessController controller, ChessRoomInfo update) {
    try {
      final localCount = controller.board.moveHistory.length;
      for (var i = localCount; i < update.moves.length; i++) {
        final entry = update.moves[i];
        final legal = controller.board.legalMovesFrom(entry.from);
        final move = legal.firstWhere(
          (m) => m.to == entry.to && m.promotionType == entry.promotionType,
        );
        controller.applyRemoteMove(move);
      }
    } catch (_) {
      // Bozuk/gecikmiş bir ağ mesajı oyunu bozmasın — sessizce yut.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İnternetten Oyna')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _waitingCode != null ? _buildWaiting() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Rakibin katılması bekleniyor. Bu kodu paylaş:',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _waitingCode!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
        ],
        OutlinedButton(onPressed: _cancelWaiting, child: const Text('Vazgeç')),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SegmentedButton<_OnlineForm>(
            segments: const [
              ButtonSegment(value: _OnlineForm.create, label: Text('Oda Kur')),
              ButtonSegment(value: _OnlineForm.join, label: Text('Odaya Katıl')),
            ],
            selected: {_form},
            onSelectionChanged: (selection) => setState(() => _form = selection.first),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Adın', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        if (_form == _OnlineForm.create) ...[
          Center(
            child: SegmentedButton<ChessTimeControl>(
              showSelectedIcon: false,
              segments: [
                for (final control in ChessTimeControl.values)
                  ButtonSegment(value: control, label: Text(control.label)),
              ],
              selected: {_timeControl},
              onSelectionChanged: (selection) => setState(() => _timeControl = selection.first),
            ),
          ),
        ] else ...[
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Oda kodu',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (_error != null) ...[
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: _busy ? null : (_form == _OnlineForm.create ? _createRoom : _joinRoom),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_form == _OnlineForm.create ? 'Oda Kur' : 'Odaya Katıl'),
          ),
        ),
      ],
    );
  }
}
