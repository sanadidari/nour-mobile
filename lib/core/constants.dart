/// Configuration de l'application.
/// Les clés sont injectées via --dart-define au build.
/// Les fallbacks sont conservés pour le développement local uniquement.
class AppConstants {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bkacywpqfdacwwwtvlgw.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_TB0t32JcUr05joC496Y6jA_crPHICNE',
  );
}
