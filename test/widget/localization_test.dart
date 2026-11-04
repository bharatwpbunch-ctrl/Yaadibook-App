import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';

void main() {
  group('Localization Loading', () {
    testWidgets('loads English strings correctly', (WidgetTester tester) async {
      late AppLocalizations localizations;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context)!;
              return Text(localizations.appName);
            },
          ),
        ),
      );

      expect(find.text('Yaadibook'), findsOneWidget);
      expect(localizations.navToday, 'Today');
      expect(localizations.actionSave, 'Save');
      expect(localizations.statusActive, 'Active');
    });

    testWidgets('loads Gujarati strings correctly', (
      WidgetTester tester,
    ) async {
      late AppLocalizations localizations;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('gu'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context)!;
              return Text(localizations.appName);
            },
          ),
        ),
      );

      expect(find.text('યાદીબુક'), findsOneWidget);
      expect(localizations.navToday, 'આજે');
      expect(localizations.actionSave, 'સાચવો');
      expect(localizations.statusActive, 'ચાલુ');
    });

    testWidgets('loads Hindi strings correctly', (WidgetTester tester) async {
      late AppLocalizations localizations;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('hi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context)!;
              return Text(localizations.appName);
            },
          ),
        ),
      );

      expect(find.text('यादीबुक'), findsOneWidget);
      expect(localizations.navToday, 'आज');
      expect(localizations.actionSave, 'सहेजें');
      expect(localizations.statusActive, 'सक्रिय');
    });
  });
}
