import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/secure_storage_service.dart';

const String kSelectedLocaleStorageKey = 'yaadibook_user_locale';

/// Supported locales in Yaadibook.
class AppLocales {
  AppLocales._();

  static const Locale english = Locale('en');
  static const Locale gujarati = Locale('gu');
  static const Locale hindi = Locale('hi');

  static const List<Locale> supported = [english, gujarati, hindi];

  static bool isSupported(Locale locale) {
    return supported.any((l) => l.languageCode == locale.languageCode);
  }

  static String getDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'gu':
        return 'ગુજરાતી (Gujarati)';
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'en':
      default:
        return 'English';
    }
  }
}

/// Provider for the secure storage service.
final secureStorageProvider = Provider<ISecureStorageService>((ref) {
  return SecureStorageService();
});

/// Riverpod StateNotifier for managing app locale dynamically.
class AppLocaleNotifier extends StateNotifier<Locale> {
  final ISecureStorageService _storage;

  AppLocaleNotifier(this._storage, [Locale initialLocale = AppLocales.english])
    : super(initialLocale) {
    _loadPersistedLocale();
  }

  Future<void> _loadPersistedLocale() async {
    final savedCode = await _storage.read(kSelectedLocaleStorageKey);
    if (savedCode != null) {
      final matchedLocale = AppLocales.supported.firstWhere(
        (l) => l.languageCode == savedCode,
        orElse: () => AppLocales.english,
      );
      state = matchedLocale;
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!AppLocales.isSupported(newLocale)) return;
    state = newLocale;
    await _storage.write(kSelectedLocaleStorageKey, newLocale.languageCode);
  }

  Future<void> setByLanguageCode(String code) async {
    final newLocale = Locale(code);
    await setLocale(newLocale);
  }
}

/// Global provider for the active app locale.
final localeProvider = StateNotifierProvider<AppLocaleNotifier, Locale>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AppLocaleNotifier(storage);
});
