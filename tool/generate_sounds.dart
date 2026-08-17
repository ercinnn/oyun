// Bu betik, uygulama için gereken kısa ses efektlerini (bomba patlaması ve
// kazanma kutlaması) sıfırdan sentezleyip assets/sounds altına WAV olarak
// yazar. Harici bir ses dosyası indirmeye gerek bırakmaz.
//
// Çalıştırmak için: dart run tool/generate_sounds.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 44100;

void main() {
  final bomb = _generateBombSound();
  final win = _generateWinSound();

  final outDir = Directory('assets/sounds');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  File('assets/sounds/bomb.wav').writeAsBytesSync(_encodeWav(bomb));
  File('assets/sounds/win.wav').writeAsBytesSync(_encodeWav(win));

  stdout.writeln('Yazıldı: assets/sounds/bomb.wav, assets/sounds/win.wav');
}

/// Alçak frekanslı bir "gümbürtü" ile hızlı sönümlenen gürültüyü karıştırarak
/// kısa bir patlama efekti üretir.
List<double> _generateBombSound() {
  const duration = 0.45;
  final total = (sampleRate * duration).round();
  final rng = math.Random(7);
  final samples = List<double>.filled(total, 0);

  for (var i = 0; i < total; i++) {
    final t = i / sampleRate;
    final noiseEnvelope = math.exp(-t * 14);
    final thumpEnvelope = math.exp(-t * 9);
    final noise = (rng.nextDouble() * 2 - 1) * noiseEnvelope * 0.8;
    final thump = math.sin(2 * math.pi * 55 * t) * thumpEnvelope * 0.6;
    samples[i] = noise + thump;
  }
  return _normalize(samples);
}

/// Yükselen bir majör arpej (do-mi-sol-do) ile neşeli, kısa bir kutlama
/// melodisi üretir.
List<double> _generateWinSound() {
  const notes = [523.25, 659.25, 783.99, 1046.50]; // C5 E5 G5 C6
  const noteDuration = 0.16;
  final perNote = (sampleRate * noteDuration).round();
  final samples = <double>[];

  for (final freq in notes) {
    for (var i = 0; i < perNote; i++) {
      final t = i / sampleRate;
      final fadeIn = math.min(1.0, i / (perNote * 0.1));
      final fadeOut = math.min(1.0, (perNote - i) / (perNote * 0.3));
      final envelope = math.min(fadeIn, fadeOut);
      final tone =
          math.sin(2 * math.pi * freq * t) +
          0.3 * math.sin(2 * math.pi * freq * 2 * t);
      samples.add(tone * envelope * 0.5);
    }
  }
  return _normalize(samples);
}

List<double> _normalize(List<double> samples) {
  var peak = 0.0;
  for (final s in samples) {
    peak = math.max(peak, s.abs());
  }
  if (peak <= 1.0) return samples;
  return samples.map((s) => s / peak).toList();
}

Uint8List _encodeWav(List<double> samples) {
  final byteData = ByteData(44 + samples.length * 2);
  final dataSize = samples.length * 2;

  void writeString(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      byteData.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  byteData.setUint32(4, 36 + dataSize, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little); // fmt chunk size
  byteData.setUint16(20, 1, Endian.little); // PCM
  byteData.setUint16(22, 1, Endian.little); // mono
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  byteData.setUint16(32, 2, Endian.little); // block align
  byteData.setUint16(34, 16, Endian.little); // bits per sample
  writeString(36, 'data');
  byteData.setUint32(40, dataSize, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    final value = (clamped * 32767).round();
    byteData.setInt16(44 + i * 2, value, Endian.little);
  }

  return byteData.buffer.asUint8List();
}
