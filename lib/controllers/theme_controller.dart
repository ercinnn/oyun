import 'package:flutter/material.dart';

import '../models/color_theme.dart';

/// Bombalı Sayılar oyunu için ortak, o oyun oturumu boyunca geçerli renk
/// teması (iki oyuncu arasında paylaşılır; platform genelinde değil).
class AppThemeController extends ChangeNotifier {
  int? _selectedPresetIndex = 0;
  Color _customBoxColor = customColorPalette[0];
  Color _customBackgroundColor = customColorPalette[2];
  Color _customNumberColor = Colors.white;

  int? get selectedPresetIndex => _selectedPresetIndex;
  Color get customBoxColor => _customBoxColor;
  Color get customBackgroundColor => _customBackgroundColor;
  Color get customNumberColor => _customNumberColor;

  GameColorTheme get current {
    final presetIndex = _selectedPresetIndex;
    if (presetIndex != null) return standardThemes[presetIndex];
    return GameColorTheme(
      name: 'Özel',
      boxColor: _customBoxColor,
      backgroundColor: _customBackgroundColor,
      numberColor: _customNumberColor,
    );
  }

  void selectPreset(int index) {
    _selectedPresetIndex = index;
    notifyListeners();
  }

  void selectCustomBoxColor(Color color) {
    _selectedPresetIndex = null;
    _customBoxColor = color;
    notifyListeners();
  }

  void selectCustomBackgroundColor(Color color) {
    _selectedPresetIndex = null;
    _customBackgroundColor = color;
    notifyListeners();
  }

  void selectCustomNumberColor(Color color) {
    _selectedPresetIndex = null;
    _customNumberColor = color;
    notifyListeners();
  }
}
