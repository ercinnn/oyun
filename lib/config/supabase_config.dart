/// Supabase projesinin bağlantı bilgileri.
///
/// `anonKey` bilerek burada sabit kodlanmıştır: Supabase'in "anon" anahtarı
/// istemci tarafında herkese açık olacak şekilde tasarlanmıştır (gerçek
/// erişim kontrolü veritabanındaki Row Level Security politikalarıyla
/// sağlanır), gizli bir servis anahtarı değildir — bkz.
/// https://supabase.com/docs/guides/api/api-keys
class SupabaseConfig {
  const SupabaseConfig._();

  /// Mobilde (Android APK) Google girişinden sonra tarayıcının uygulamaya
  /// geri dönmesini sağlayan derin bağlantı. Web'de kullanılmaz — orada
  /// yönlendirme sitenin kendi adresine döner.
  ///
  /// Bu adres üç yerde birbiriyle aynı olmalı: burada,
  /// `android/app/src/main/AndroidManifest.xml`'deki intent-filter'da ve
  /// Supabase panelinde Authentication > URL Configuration > Redirect URLs
  /// listesinde. Şemada alt çizgi kullanılamayacağı için uygulama
  /// kimliğinden (`io.github.ercinnn.bombali_sayilar`) bağımsız, ayrı bir
  /// şema seçildi.
  static const String mobileAuthRedirectUrl = 'oyunplatformu://login-callback/';

  static const String url = 'https://fdvokdfuamwezuoffbyz.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkdm9rZGZ1YW13ZXp1b2ZmYnl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg0NTc5MDUsImV4cCI6MjEwNDAzMzkwNX0.QrwZvs9HJWh9FIGbacJ6pK1A0CJXLNZfwJxW0KWv0RY';
}
