import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/home_palette.dart';
import '../widgets/home_backdrop.dart';
import '../widgets/platform_logo_mark.dart';
import 'game_catalog_screen.dart';

/// Oturum açık değilken [AuthGate]'in gösterdiği tek ekran. Google OAuth
/// akışı web'de tam sayfa yönlendirmeyle çalışır — buton, kullanıcıyı
/// Google'ın onay ekranına yönlendirip geri getirir; sonucu [AuthGate]
/// Supabase'in oturum akışını dinleyerek otomatik yakalar.
///
/// Görsel olarak bilerek ana menüyle aynı dili konuşur: aynı [HomeBackdrop],
/// aynı [HomePalette] ve aynı [PlatformLogoMark] — giriş → ana sayfa geçişinde
/// tema değişmez (bkz. CLAUDE.md, "Home page look").
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: homeThemeData(),
      child: Scaffold(
        backgroundColor: HomePalette.backdropTop,
        body: HomeBackdrop(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _LoginPanel(),
                      SizedBox(height: 18),
                      _SecurityNote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomePalette.surface, HomePalette.surfaceRaised],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HomePalette.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlatformLogoMark(size: 60),
          const SizedBox(height: 20),
          const Text(
            'Oyun Platformu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: HomePalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Zeka, hafıza ve dikkat oyunlarını tek uygulamada topladık. '
            'Devam etmek için Google hesabınla bağlan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: HomePalette.textSecondary,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  context.read<AuthController>().signInWithGoogle(),
              style: FilledButton.styleFrom(
                backgroundColor: HomePalette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              icon: const Icon(Icons.login, size: 20),
              label: const Text('Google ile Bağlan'),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: HomePalette.outline),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: platformStatChips(),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: HomePalette.textMuted),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Google ile güvenli giriş. Şifren bu uygulamaya hiç girilmez.',
            style: TextStyle(fontSize: 12, color: HomePalette.textMuted),
          ),
        ),
      ],
    );
  }
}
