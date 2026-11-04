import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('default fromEnvironment sets dev environment and safe values', () {
      final config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.dev);
      expect(config.isDev, isTrue);
      expect(config.isProd, isFalse);
      expect(config.appName, 'Yaadibook');
      expect(config.supabaseUrl, isNotEmpty);
      expect(config.supabaseAnonKey, isNotEmpty);
      expect(config.enableLogging, isTrue);
    });

    test('custom instance can be assigned and accessed', () {
      const customConfig = AppConfig(
        environment: AppEnvironment.staging,
        appName: 'Yaadibook Staging',
        supabaseUrl: 'https://staging.supabase.co',
        supabaseAnonKey: 'staging-key',
        enableLogging: false,
      );

      AppConfig.setInstance(customConfig);
      expect(AppConfig.current.environment, AppEnvironment.staging);
      expect(AppConfig.current.isStaging, isTrue);
      expect(AppConfig.current.appName, 'Yaadibook Staging');
      expect(AppConfig.current.enableLogging, isFalse);

      // Restore dev config
      AppConfig.setInstance(AppConfig.fromEnvironment());
    });
  });
}
