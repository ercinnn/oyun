import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'game_catalog_screen.dart';
import 'login_screen.dart';

/// Platformun gerçek kök ekranı: [AuthController.isSignedIn]'e göre
/// [LoginScreen] veya [GameCatalogScreen] gösterir. `main.dart`'ta
/// `GameCatalogScreen.routeName` ('/') artık doğrudan katalogu değil bunu
/// üretir — çıkış yapıldığında bu widget yeniden build olup otomatik
/// olarak giriş ekranına döner.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AuthController>().isSignedIn;
    return isSignedIn ? const GameCatalogScreen() : const LoginScreen();
  }
}
