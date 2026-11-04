import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/config/app_config.dart';
import 'core/services/supabase_service.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize application configuration
  final config = AppConfig.fromEnvironment();
  AppConfig.setInstance(config);

  AppLogger.info(
    'Starting Yaadibook (${config.environment.name}) - Client foundation initialized.',
  );

  // 2. Prepare Supabase backend client (safe initialization in offline/placeholder mode)
  await SupabaseService.initialize(config);

  // 3. Launch application root with Riverpod scope
  runApp(const ProviderScope(child: YaadibookApp()));
}
