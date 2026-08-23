import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

/// Oturum açık değilken [AuthGate]'in gösterdiği tek ekran. Google OAuth
/// akışı web'de tam sayfa yönlendirmeyle çalışır — buton, kullanıcıyı
/// Google'ın onay ekranına yönlendirip geri getirir; sonucu [AuthGate]
/// Supabase'in oturum akışını dinleyerek otomatik yakalar.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videogame_asset,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Oyun Platformu',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Devam etmek için Google hesabınla bağlan.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      context.read<AuthController>().signInWithGoogle(),
                  icon: const Icon(Icons.login),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Google ile Bağlan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
