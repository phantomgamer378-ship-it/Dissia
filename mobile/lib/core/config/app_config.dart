/// Application configuration loaded via --dart-define-from-file.
/// Never embed service-role keys, AI provider keys, or DB passwords here.
class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;
  final bool isDebug;

  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
    required this.isDebug,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://placeholder.supabase.co',
      ),
      supabaseAnonKey: String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: 'placeholder-anon-key',
      ),
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      ),
      isDebug: bool.fromEnvironment('DEBUG', defaultValue: true),
    );
  }
}
