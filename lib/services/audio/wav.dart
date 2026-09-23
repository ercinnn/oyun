import 'dart:typed_data';

/// 16-bit mono PCM'i WAV baytlarına çevirir. Platform eklentisi kullanmaz,
/// bu yüzden birim testlenebilir; hem satranç hamle sesleri
/// (`chess_move_sound_synth.dart`) hem kasaba sesleri (`clip_synth.dart`)
/// aynı kodlayıcıyı kullanır.
Uint8List encodeWav16(Int16List pcm, int sampleRate) {
  final dataLen = pcm.length * 2;
  final bytes = ByteData(44 + dataLen);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLen, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, dataLen, Endian.little);
  for (var i = 0; i < pcm.length; i++) {
    bytes.setInt16(44 + i * 2, pcm[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

/// [-1, 1] aralığındaki örnekleri 16-bit WAV'a çevirir (aralık dışı kırpılır).
Uint8List encodeWavFromFloat(Float32List samples, int sampleRate) {
  final pcm = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    final v = samples[i].clamp(-1.0, 1.0).toDouble();
    pcm[i] = (v * 32767).round();
  }
  return encodeWav16(pcm, sampleRate);
}
