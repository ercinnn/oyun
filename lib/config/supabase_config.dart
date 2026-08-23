/// Supabase projesinin bağlantı bilgileri.
///
/// `anonKey` bilerek burada sabit kodlanmıştır: Supabase'in "anon" anahtarı
/// istemci tarafında herkese açık olacak şekilde tasarlanmıştır (gerçek
/// erişim kontrolü veritabanındaki Row Level Security politikalarıyla
/// sağlanır), gizli bir servis anahtarı değildir — bkz.
/// https://supabase.com/docs/guides/api/api-keys
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://aufindwuwwllseaveely.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1ZmluZHd1d3dsbHNlYXZlZWx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1MDkzOTgsImV4cCI6MjEwMzA4NTM5OH0.YzZSDluK93DjID0WyolDFqu33FPs9TC4S8QXoazwkd8';
}
