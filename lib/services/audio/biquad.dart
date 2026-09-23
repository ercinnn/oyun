import 'dart:math';

/// RBJ "Audio EQ Cookbook" iki kutuplu süzgeci (Web Audio
/// `BiquadFilterNode` ile aynı formüller). Katsayılar örnekler arasında
/// değiştirilebilir; süzgeç durumu korunur (süpürmeli kesim frekansı için
/// gerekli). Saf Dart'tır; sentezleyicilerin ortak parçasıdır.
class Biquad {
  double _b0 = 1, _b1 = 0, _b2 = 0, _a1 = 0, _a2 = 0;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  void _set(double b0, double b1, double b2, double a0, double a1, double a2) {
    _b0 = b0 / a0;
    _b1 = b1 / a0;
    _b2 = b2 / a0;
    _a1 = a1 / a0;
    _a2 = a2 / a0;
  }

  void lowpass(double hz, int sampleRate, [double q = 0.7071]) {
    final w = 2 * pi * hz / sampleRate;
    final c = cos(w);
    final alpha = sin(w) / (2 * q);
    _set((1 - c) / 2, 1 - c, (1 - c) / 2, 1 + alpha, -2 * c, 1 - alpha);
  }

  void highpass(double hz, int sampleRate, [double q = 0.7071]) {
    final w = 2 * pi * hz / sampleRate;
    final c = cos(w);
    final alpha = sin(w) / (2 * q);
    _set((1 + c) / 2, -(1 + c), (1 + c) / 2, 1 + alpha, -2 * c, 1 - alpha);
  }

  /// Sabit 0 dB tepe kazançlı band-geçiren.
  void bandpass(double hz, int sampleRate, double q) {
    final w = 2 * pi * hz / sampleRate;
    final c = cos(w);
    final alpha = sin(w) / (2 * q);
    _set(alpha, 0, -alpha, 1 + alpha, -2 * c, 1 - alpha);
  }

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}
