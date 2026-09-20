import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/town/town_profile.dart';

/// Kasaba ilerlemesinin (avatar, altın, eşyalar, oda) saklandığı yer.
/// Testler bellek içi uygulamayı ([InMemoryTownProgressRepository]) kullanır.
abstract class TownProgressRepository {
  /// Kayıtlı profil; hiç kayıt yoksa ya da okunamazsa null.
  Future<TownProfile?> load();

  Future<void> save(TownProfile profile);
}

/// Yalnızca oturum boyunca yaşar (testler ve kayıtsız çalıştırma için).
class InMemoryTownProgressRepository implements TownProgressRepository {
  Map<String, Object?>? _stored;

  @override
  Future<TownProfile?> load() async {
    final stored = _stored;
    return stored == null ? null : TownProfile.fromJson(stored);
  }

  @override
  Future<void> save(TownProfile profile) async {
    // JSON'a çevirip geri okumak, gerçek depolamanın davranışını taklit eder.
    _stored = jsonDecode(jsonEncode(profile.toJson())) as Map<String, Object?>;
  }
}

/// `shared_preferences` ile cihazda kalıcı. Bozuk kayıtta null döner (oyun
/// varsayılan profille açılır, hiçbir zaman çökmez).
class SharedPrefsTownProgressRepository implements TownProgressRepository {
  static const _key = 'town_profile_v1';

  @override
  Future<TownProfile?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return TownProfile.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(TownProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(profile.toJson()));
    } catch (_) {
      // Yan servis oyunu asla bozmaz (bkz. SoundService/SpeechService deseni).
    }
  }
}
