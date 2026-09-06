import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Platform genelinde tek örnek olarak sağlanan oturum kapısı (bkz.
/// CLAUDE.md — Google ile giriş): [ProfileController]'ın aksine bu bir
/// gerçek kimlik doğrulamasıdır — Supabase Auth'un Google OAuth sağlayıcısı
/// üzerinden. `isSignedIn` false olduğu sürece [AuthGate] `LoginScreen`
/// gösterir; oyun içi görünen isim ise hâlâ ayrı [ProfileController]'dan
/// gelir (bir Gmail hesabı ile giriş yapan kişi, ekranda çocuğunun ismini
/// göstermek isteyebilir).
class AuthController extends ChangeNotifier {
  bool isSignedIn = false;

  StreamSubscription<AuthState>? _subscription;

  /// main()'de bir kez çağrılır; testler bunu hiç çağırmaz, bunun yerine
  /// `isSignedIn`'i doğrudan set eder (bkz. test/widget_test.dart).
  void listenToSupabaseAuth() {
    isSignedIn = Supabase.instance.client.auth.currentSession != null;
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      isSignedIn = data.session != null;
      notifyListeners();
    });
  }

  /// Web'de OAuth akışı tam sayfa yönlendirmeyle çalışır ve kullanıcı zaten
  /// sitenin kendi adresine döner; bu yüzden `redirectTo` verilmez. Mobilde
  /// ise tarayıcı ayrı bir uygulamadır — geri dönebilmesi için
  /// [SupabaseConfig.mobileAuthRedirectUrl] derin bağlantısı gerekir (aynı
  /// adres AndroidManifest'te intent-filter olarak ve Supabase panelinde
  /// izinli yönlendirme adresi olarak tanımlı olmalı).
  Future<void> signInWithGoogle() {
    return Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : SupabaseConfig.mobileAuthRedirectUrl,
    );
  }

  /// Bilerek senkron: `isSignedIn` anında (ağ çağrısı beklemeden) false'a
  /// çekilip dinleyicilere bildirilir, böylece [AuthGate] her zaman hemen
  /// giriş ekranına döner. Supabase'e oturumu kapatma isteği arka planda,
  /// sonucu beklenmeden gönderilir — bir ağ sorunu (ya da testteki sahte
  /// proje gibi hiç var olmayan bir sunucu) çıkışı asla geciktirmemeli ya
  /// da engellememeli (bkz. SoundService/SpeechService'teki "yan servis
  /// asla oyunu bozmasın" deseniyle aynı tercih).
  void signOut() {
    isSignedIn = false;
    notifyListeners();
    unawaited(
      Supabase.instance.client.auth
          .signOut(scope: SignOutScope.local)
          .catchError((_) {}),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
