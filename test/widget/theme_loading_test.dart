import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/theme/app_colors.dart';
import 'package:yaadibook/app/theme/app_theme.dart';

void main() {
  group('Theme Loading', () {
    test('AppTheme loads Material 3 with brand colors and tokens', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.primaryColor, AppColors.primary);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.appBarTheme.backgroundColor, AppColors.surface);
      expect(theme.cardTheme.color, AppColors.card);
      expect(theme.inputDecorationTheme.filled, isTrue);
    });

    testWidgets('Theme renders properly in widget tree context', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Center(child: Text('Theme Check'))),
        ),
      );

      final BuildContext context = tester.element(find.text('Theme Check'));
      final currentTheme = Theme.of(context);

      expect(currentTheme.useMaterial3, isTrue);
      expect(currentTheme.colorScheme.primary, AppColors.primary);
    });
  });
}
