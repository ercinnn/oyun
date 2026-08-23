import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';
import 'games/bombali_sayilar_game.dart';
import 'games/memory_match_game.dart';
import 'games/pattern_game.dart';
import 'games/puzzle_game.dart';
import 'games/reflex_game.dart';
import 'games/sequence_memory_game.dart';
import 'games/simon_game.dart';
import 'games/stroop_game.dart';
import 'screens/auth_gate.dart';
import 'screens/game_catalog_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
  // Profil ismi her oyunun kurulum ekranında ilk build'de hazır olsun diye
  // (bir sonraki setup ekranı bunu bir kerelik initState'te okuyup 1. Oyuncu
  // alanına yazıyor) uygulama açılmadan önce yükleniyor — bkz.
  // CLAUDE.md, "Kullanıcı profili".
  final profileController = ProfileController();
  await profileController.load();
  final authController = AuthController()..listenToSupabaseAuth();
  runApp(
    GamePlatformApp(
      profileController: profileController,
      authController: authController,
    ),
  );
}

/// Platformun kök widget'ı: ana menüyü ve platforma kayıtlı her oyunun
/// route'unu barındırır. Her oyun kendi state'ini ([Provider] ağacı dahil)
/// kendi route widget'ında kurar; burası yalnızca hangi ekranın açık
/// olduğunu yönetir. [ProfileController] ve [AuthController] bunun tek
/// istisnasıdır: oyunlar arası ortak kullanıcı kimliği/oturumu olduğu için
/// burada, platform kökünde tek birer örnek olarak sağlanır.
class GamePlatformApp extends StatelessWidget {
  const GamePlatformApp({
    super.key,
    ProfileController? profileController,
    AuthController? authController,
  }) : _profileController = profileController,
       _authController = authController;

  /// Testler bunu vermez; o durumda boş isimli, yüklenmemiş bir örnek
  /// kullanılır (bkz. test/widget_test.dart).
  final ProfileController? _profileController;

  /// Testler bunu da genelde vermez; o durumda oturum açılmış varsayılır
  /// ki mevcut testlerin çoğu giriş ekranıyla hiç uğraşmadan doğrudan
  /// oyunlara gidebilsin. Giriş ekranını test eden testler bunu açıkça
  /// `isSignedIn = false` ile verir (bkz. test/widget_test.dart).
  final AuthController? _authController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileController>(
          create: (_) => _profileController ?? ProfileController(),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (_) => _authController ?? (AuthController()..isSignedIn = true),
        ),
      ],
      child: MaterialApp(
        title: 'Oyun Platformu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        initialRoute: GameCatalogScreen.routeName,
        onGenerateRoute: (settings) {
          final builder = switch (settings.name) {
            BombaliSayilarGame.routeName => (BuildContext _) =>
                const BombaliSayilarGame(),
            MemoryMatchGame.routeName => (BuildContext _) =>
                const MemoryMatchGame(),
            StroopGame.routeName => (BuildContext _) => const StroopGame(),
            SequenceMemoryGame.routeName => (BuildContext _) =>
                const SequenceMemoryGame(),
            PatternGame.routeName => (BuildContext _) => const PatternGame(),
            ReflexGame.routeName => (BuildContext _) => const ReflexGame(),
            SimonGame.routeName => (BuildContext _) => const SimonGame(),
            PuzzleGame.routeName => (BuildContext _) => const PuzzleGame(),
            ProfileScreen.routeName => (BuildContext _) =>
                const ProfileScreen(),
            _ => (BuildContext _) => const AuthGate(),
          };
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ),
    );
  }
}
