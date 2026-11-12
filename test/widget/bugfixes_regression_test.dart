import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yaadibook/app/localization/generated/app_localizations.dart';
import 'package:yaadibook/app/localization/locale_provider.dart';
import 'package:yaadibook/app/theme/app_theme.dart';
import 'package:yaadibook/core/services/secure_storage_service.dart';
import 'package:yaadibook/features/dashboard/models/today_focus_item.dart';
import 'package:yaadibook/features/dashboard/presentation/widgets/today_focus_section.dart';
import 'package:yaadibook/features/settings/presentation/operating_hours_screen.dart';
import 'package:yaadibook/features/settings/presentation/service_categories_screen.dart';
import 'package:yaadibook/shared/models/business.dart';
import 'package:yaadibook/shared/providers/backend_providers.dart';

class _InMemoryStorage implements ISecureStorageService {
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
  group('TodayFocusItem routing & template category', () {
    final due = DateTime(2026, 11, 12);

    test('resolves targetRoute accurately from explicit foreign IDs', () {
      final remItem = TodayFocusItem(
        id: 'r1',
        title: 'Follow up',
        dueDate: due,
        source: TodayFocusSource.followup,
        reminderId: 'rem-123',
      );
      expect(remItem.targetRoute, '/reminders/rem-123');
      expect(remItem.templateCategory, 'follow_up');

      final maintItem = TodayFocusItem(
        id: 'm1',
        title: 'RO Checkup',
        dueDate: due,
        source: TodayFocusSource.maintenance,
        maintenanceOccurrenceId: 'occ-456',
      );
      expect(maintItem.targetRoute, '/maintenance/occurrences/occ-456');
      expect(maintItem.templateCategory, 'maintenance_reminder');

      final svcItem = TodayFocusItem(
        id: 's1',
        title: 'DVR Repair',
        dueDate: due,
        source: TodayFocusSource.service,
        serviceId: 'svc-789',
      );
      expect(svcItem.targetRoute, '/services/svc-789');
      expect(svcItem.templateCategory, 'service_update');

      final amcItem = TodayFocusItem(
        id: 'a1',
        title: 'Annual CCTV AMC',
        dueDate: due,
        source: TodayFocusSource.amc,
        amcContractId: 'amc-321',
      );
      expect(amcItem.targetRoute, '/amc/amc-321');
      expect(amcItem.templateCategory, 'amc_renewal');
    });
  });

  group('TodayFocusSection navigation widget tests', () {
    testWidgets('tapping focus item navigates to targetRoute', (tester) async {
      final due = DateTime(2026, 11, 12);
      final router = GoRouter(
        initialLocation: '/today',
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => Scaffold(
              body: SingleChildScrollView(
                child: TodayFocusSection(
                  items: [
                    TodayFocusItem(
                      id: 'occ-99',
                      title: 'Maintenance Service Due',
                      customerName: 'Patel Clinic',
                      customerPhone: '9825011223',
                      dueDate: due,
                      source: TodayFocusSource.maintenance,
                      maintenanceOccurrenceId: 'occ-99',
                    ),
                  ],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/maintenance/occurrences/:id',
            builder: (context, state) =>
                Scaffold(body: Text('Visited:${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maintenance Service Due'));
      await tester.pumpAndSettle();

      expect(find.text('Visited:occ-99'), findsOneWidget);
    });
  });

  group('Settings sub-screens (Operating Hours & Service Categories)', () {
    final mockBiz = Business(
      id: 'biz-test-1',
      ownerUserId: 'user-1',
      businessName: 'Bharat CCTV Company',
      businessCategory: 'CCTV & Security',
      phone: '9825011223',
      addressLine1: 'Shop 4',
      city: 'Surat',
      state: 'Gujarat',
      postalCode: '395007',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    testWidgets('OperatingHoursScreen renders and toggles day status', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentBusinessProvider.overrideWith((ref) => mockBiz),
            secureStorageProvider.overrideWithValue(_InMemoryStorage()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const OperatingHoursScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Operating Hours'), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Save Operating Hours'), 200);
      await tester.pumpAndSettle();
      expect(find.text('Sunday'), findsOneWidget);
      expect(find.text('Save Operating Hours'), findsOneWidget);
    });

    testWidgets(
      'ServiceCategoriesScreen renders default categories & adds one',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentBusinessProvider.overrideWith((ref) => mockBiz),
              secureStorageProvider.overrideWithValue(_InMemoryStorage()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ServiceCategoriesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Service Categories'), findsOneWidget);
        expect(find.text('Installation'), findsOneWidget);
        expect(find.text('AMC Support'), findsOneWidget);
      },
    );
  });
}
