enum AppEnvironment { dev, staging, prod }

/// Central configuration for Yaadibook.
///
/// Values can be injected at build time using `--dart-define`:
/// e.g. `flutter run --dart-define=APP_ENV=dev --dart-define=SUPABASE_URL=...`
///
/// **SECURITY NOTE**:
/// Safe client-side keys:
/// - [supabaseUrl] (Public project endpoint)
/// - [supabaseAnonKey] (Public anonymous key protected by Supabase Row Level Security / RLS)
///
/// **NEVER** expose:
/// - `service_role` keys
/// - Database root credentials / connection strings
/// - Private third-party payment/messaging API secrets
class AppConfig {
  final AppEnvironment environment;
  final String appName;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableLogging;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.enableLogging = true,
  });

  static AppConfig? _instance;

  static AppConfig get current {
    _instance ??= fromEnvironment();
    return _instance!;
  }

  static void setInstance(AppConfig config) {
    _instance = config;
  }

  static AppConfig fromEnvironment() {
    const envString = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final environment = switch (envString.toLowerCase()) {
      'prod' || 'production' => AppEnvironment.prod,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };

    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://placeholder.supabase.co',
    );

    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'placeholder-anon-key',
    );

    return AppConfig(
      environment: environment,
      appName: 'Yaadibook',
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      enableLogging: environment != AppEnvironment.prod,
    );
  }

  bool get isDev => environment == AppEnvironment.dev;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProd => environment == AppEnvironment.prod;
}
