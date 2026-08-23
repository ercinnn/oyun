import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

/// Platformun tek profil ekranı: kullanıcı burada girdiği ismi her oyunun
/// kurulum ekranında 1. Oyuncu adı olarak otomatik bulur (bkz. CLAUDE.md).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<ProfileController>().name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'İsim boş olamaz';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileController>().setName(_nameController.text);
    Navigator.of(context).pop();
  }

  void _signOut() {
    context.read<AuthController>().signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Adını gir — her oyunun kurulum ekranında 1. Oyuncu '
                    'adı olarak otomatik dolar.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('profileNameField'),
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Adın',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _save,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Kaydet'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const Key('signOutButton'),
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Çıkış Yap'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
