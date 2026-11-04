import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/locale_provider.dart';
import 'package:yaadibook/core/services/secure_storage_service.dart';

class FakeSecureStorageService implements ISecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

void main() {
  group('AppLocaleNotifier', () {
    late FakeSecureStorageService storage;
    late AppLocaleNotifier notifier;

    setUp(() {
      storage = FakeSecureStorageService();
      notifier = AppLocaleNotifier(storage, AppLocales.english);
    });

    test('initial state defaults to English', () {
      expect(notifier.state, const Locale('en'));
    });

    test('updates state and persists to storage on setLocale', () async {
      await notifier.setLocale(AppLocales.gujarati);
      expect(notifier.state, const Locale('gu'));
      expect(await storage.read(kSelectedLocaleStorageKey), 'gu');

      await notifier.setLocale(AppLocales.hindi);
      expect(notifier.state, const Locale('hi'));
      expect(await storage.read(kSelectedLocaleStorageKey), 'hi');
    });

    test('ignores unsupported locales', () async {
      await notifier.setLocale(const Locale('fr'));
      expect(notifier.state, const Locale('en'));
    });

    test('setByLanguageCode switches locale correctly', () async {
      await notifier.setByLanguageCode('gu');
      expect(notifier.state, const Locale('gu'));
    });
  });
}
