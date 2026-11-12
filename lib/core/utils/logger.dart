import 'dart:developer' as dev;
import '../../app/config/app_config.dart';

typedef Logger = AppLogger;

/// Lightweight logging utility for Yaadibook.
///
/// Automatically mutes non-error logs in production mode.
class AppLogger {
  AppLogger._();

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (AppConfig.current.enableLogging) {
      dev.log(
        '[DEBUG] $message',
        name: 'Yaadibook',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void info(String message) {
    if (AppConfig.current.enableLogging) {
      dev.log('[INFO] $message', name: 'Yaadibook');
    }
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log(
      '[WARN] $message',
      name: 'Yaadibook',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log(
      '[ERROR] $message',
      name: 'Yaadibook',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
