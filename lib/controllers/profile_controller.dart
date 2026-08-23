import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platformun tamamında (her oyunda) paylaşılan kullanıcı kimliği: sadece
/// bir isim. Oyun state'lerinin aksine bilerek platform kökünde tek bir
/// örnek olarak sağlanır (bkz. CLAUDE.md — Kullanıcı profili), çünkü bu
/// isim doğası gereği oyunlar arasıdır, tek bir oyuna ait değildir.
class ProfileController extends ChangeNotifier {
  static const _nameKey = 'profile_name';

  String name = '';

  bool get hasName => name.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString(_nameKey) ?? '';
    notifyListeners();
  }

  Future<void> setName(String value) async {
    name = value.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }
}
