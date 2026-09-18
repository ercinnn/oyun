import 'chess_move_sound_base.dart';
import 'chess_move_sound_native.dart'
    if (dart.library.js_interop) 'chess_move_sound_web.dart'
    as impl;

export 'chess_move_sound_base.dart';

/// Platforma uygun çalıcıyı üretir: web'de Web Audio API, diğerlerinde aynı
/// tarifi PCM olarak sentezleyen çalıcı. Ses çalma hiçbir zaman oyunu
/// bozmamalı; her iki uygulama da hataları içeride yutar.
ChessMoveSounds createChessMoveSounds() => impl.createPlatformMoveSounds();
