import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/context_extensions.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/customers/presentation/add_customer_screen.dart';
import '../../features/customers/presentation/contact_import_screen.dart';
import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/customers/presentation/edit_customer_screen.dart';
import '../../features/dashboard/presentation/notifications_screen.dart';
import '../../features/dashboard/presentation/today_screen.dart';
import '../../features/dashboard/presentation/widgets/quick_add_sheet.dart';
import '../../features/onboarding/presentation/business_onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_status_provider.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/reminders/presentation/create_reminder_screen.dart';
import '../../features/reminders/presentation/edit_reminder_screen.dart';
import '../../features/reminders/presentation/reminder_detail_screen.dart';
import '../../features/notifications/presentation/notification_centre_screen.dart';
import '../../features/notifications/presentation/notification_preferences_screen.dart';
import '../../features/services/presentation/add_service_screen.dart';
import '../../features/services/presentation/edit_service_screen.dart';
import '../../features/services/presentation/service_detail_screen.dart';
import '../../features/services/presentation/services_list_screen.dart';
import '../../features/services/presentation/services_overview_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/maintenance/presentation/add_maintenance_plan_screen.dart';
import '../../features/maintenance/presentation/edit_maintenance_plan_screen.dart';
import '../../features/maintenance/presentation/maintenance_occurrence_detail_screen.dart';
import '../../features/maintenance/presentation/maintenance_overview_screen.dart';
import '../../features/maintenance/presentation/maintenance_plan_detail_screen.dart';
import '../../features/maintenance/presentation/maintenance_plans_screen.dart';
import '../../features/amc/presentation/amc_detail_screen.dart';
import '../../features/amc/presentation/amc_overview_screen.dart';
import '../../features/amc/presentation/create_amc_screen.dart';
import '../../features/amc/presentation/edit_amc_screen.dart';
import '../../features/amc/presentation/renew_amc_screen.dart';
import '../../features/communications/presentation/communication_overview_screen.dart';
import '../../features/communications/presentation/communication_usage_screen.dart';
import '../../features/communications/presentation/whatsapp_settings_screen.dart';
import '../../features/communications/presentation/sms_settings_screen.dart';
import '../../features/message_templates/presentation/message_templates_screen.dart';
import '../../features/message_templates/presentation/template_editor_screen.dart';
import '../../features/bulk_messaging/presentation/campaigns_screen.dart';
import '../../features/bulk_messaging/presentation/create_campaign_screen.dart';
import '../../features/bulk_messaging/presentation/campaign_detail_screen.dart';
import '../../features/offline_sync/presentation/offline_sync_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/business_profile_screen.dart';
import '../../features/settings/presentation/legal_and_deletion_screens.dart';
import '../../features/settings/presentation/operating_hours_screen.dart';
import '../../features/settings/presentation/service_categories_screen.dart';
import '../../features/subscriptions/presentation/subscription_screen.dart';
import '../../core/widgets/offline_status_banner.dart';
import '../../shared/providers/backend_providers.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Listenable that notifies GoRouter whenever auth or onboarding state changes.
class AppRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AppRouterNotifier(this._ref) {
    _ref.listen(
      onboardingJourneyStatusProvider,
      (previous, next) => notifyListeners(),
    );
    _ref.listen(authStateProvider, (previous, next) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<AppRouterNotifier>((ref) {
  return AppRouterNotifier(ref);
});

/// App router provider using GoRouter with full route guards.
final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final journeyStatus = ref.read(onboardingJourneyStatusProvider);
      final location = state.matchedLocation;

      final isSplash = location == '/splash';
      final isAuthRoute =
          location == '/welcome' ||
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/reset-password';
      final isOnboarding = location == '/onboarding';

      // 1. Loading: remain on splash
      if (journeyStatus == OnboardingJourneyStatus.loading) {
        return isSplash ? null : '/splash';
      }

      // 2. Unauthenticated: must be on welcome or auth sub-screens
      if (journeyStatus == OnboardingJourneyStatus.unauthenticated) {
        if (isAuthRoute) return null;
        return '/welcome';
      }

      // 3. Needs Business Onboarding:
      if (journeyStatus == OnboardingJourneyStatus.needsBusiness) {
        if (isOnboarding) return null;
        return '/onboarding';
      }

      // 4. Onboarding Completed: redirect from auth/onboarding/splash to dashboard
      if (journeyStatus == OnboardingJourneyStatus.completed) {
        if (isSplash || isAuthRoute || isOnboarding) {
          return '/today';
        }
        return null;
      }

      return null;
    },
    routes: [
      // 1. Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 2. Auth Flow Screens
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // 3. Single-Business Onboarding Wizard
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const BusinessOnboardingScreen(),
      ),

      // 4. Notification Centre (Full-screen push route with back navigation)
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // 5. Customer Management Routes (Full-screen push routes with back navigation)
      GoRoute(
        path: '/customers/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final name = state.uri.queryParameters['name'];
          final phone = state.uri.queryParameters['phone'];
          return AddCustomerScreen(initialName: name, initialPhone: phone);
        },
      ),
      GoRoute(
        path: '/customers/import',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ContactImportScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            CustomerDetailScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EditCustomerScreen(customerId: state.pathParameters['id']!),
      ),

      // 6. Service Management Routes (Full-screen push routes with back navigation)
      GoRoute(
        path: '/services',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ServicesOverviewScreen(),
      ),
      GoRoute(
        path: '/services/list',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          return ServicesListScreen(initialStatus: status);
        },
      ),
      GoRoute(
        path: '/services/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'];
          return AddServiceScreen(initialCustomerId: customerId);
        },
      ),
      GoRoute(
        path: '/services/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ServiceDetailScreen(serviceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/services/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EditServiceScreen(serviceId: state.pathParameters['id']!),
      ),

      // 7. Maintenance Management Routes (Full-screen push routes with back navigation)
      GoRoute(
        path: '/maintenance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MaintenanceOverviewScreen(),
      ),
      GoRoute(
        path: '/maintenance/plans',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MaintenancePlansScreen(),
      ),
      GoRoute(
        path: '/maintenance/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'];
          final equipmentId = state.uri.queryParameters['equipmentId'];
          return AddMaintenancePlanScreen(
            initialCustomerId: customerId,
            initialEquipmentId: equipmentId,
          );
        },
      ),
      GoRoute(
        path: '/maintenance/plans/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            MaintenancePlanDetailScreen(planId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/maintenance/plans/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EditMaintenancePlanScreen(planId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/maintenance/occurrences/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MaintenanceOccurrenceDetailScreen(
          occurrenceId: state.pathParameters['id']!,
        ),
      ),

      // 8. AMC Contract Management Routes (Full-screen push routes with back navigation)
      GoRoute(
        path: '/amc',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          return AmcOverviewScreen(initialStatus: status);
        },
      ),
      GoRoute(
        path: '/amc/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'];
          final equipmentId = state.uri.queryParameters['equipmentId'];
          return CreateAmcScreen(
            initialCustomerId: customerId,
            initialEquipmentId: equipmentId,
          );
        },
      ),
      GoRoute(
        path: '/amc/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            AmcDetailScreen(contractId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/amc/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EditAmcScreen(contractId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/amc/:id/renew',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            RenewAmcScreen(contractId: state.pathParameters['id']!),
      ),

      // 9. Unified Reminders & Notifications Routes
      GoRoute(
        path: '/reminders/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'];
          final serviceId = state.uri.queryParameters['serviceId'];
          final category = state.uri.queryParameters['category'];
          return CreateReminderScreen(
            initialCustomerId: customerId,
            initialServiceId: serviceId,
            initialCategory: category,
          );
        },
      ),
      GoRoute(
        path: '/reminders/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ReminderDetailScreen(reminderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reminders/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EditReminderScreen(reminderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationCentreScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/settings/business-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BusinessProfileScreen(
          initialSection: state.uri.queryParameters['section'],
        ),
      ),
      GoRoute(
        path: '/settings/operating-hours',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OperatingHoursScreen(),
      ),
      GoRoute(
        path: '/settings/service-categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ServiceCategoriesScreen(),
      ),
      GoRoute(
        path: '/settings/subscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/settings/offline-sync',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OfflineSyncScreen(),
      ),
      GoRoute(
        path: '/settings/legal',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LegalOverviewScreen(),
      ),
      GoRoute(
        path: '/settings/delete-account',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),

      // 10. Communication, Templates & Campaigns Routes
      GoRoute(
        path: '/communications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommunicationOverviewScreen(),
      ),
      GoRoute(
        path: '/communications/templates',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MessageTemplatesScreen(),
      ),
      GoRoute(
        path: '/communications/templates/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TemplateEditorScreen(),
      ),
      GoRoute(
        path: '/communications/templates/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            TemplateEditorScreen(templateId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/communications/campaigns',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CampaignsScreen(),
      ),
      GoRoute(
        path: '/communications/campaigns/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateCampaignScreen(),
      ),
      GoRoute(
        path: '/communications/campaigns/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            CampaignDetailScreen(campaignId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/communications/usage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommunicationUsageScreen(),
      ),
      GoRoute(
        path: '/communications/settings/whatsapp',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WhatsAppSettingsScreen(),
      ),
      GoRoute(
        path: '/communications/settings/sms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SmsSettingsScreen(),
      ),

      // 6. Main App Shell (Today, Customers, Reminders, More with persistent bottom nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Today / Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          // Branch 1: Customers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomersScreen(),
              ),
            ],
          ),
          // Branch 2: Reminders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reminders',
                builder: (context, state) => const RemindersScreen(),
              ),
            ],
          ),
          // Branch 3: More / Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Stateful navigation shell supporting the persistent bottom navigation bar.
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  int _getNavBarIndex(int branchIndex) {
    switch (branchIndex) {
      case 0:
        return 0; // Today
      case 1:
        return 1; // Customers
      case 2:
        return 3; // Reminders
      case 3:
        return 4; // More
      default:
        return 0;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        navigationShell.goBranch(
          0,
          initialLocation: navigationShell.currentIndex == 0,
        );
        break;
      case 1:
        navigationShell.goBranch(
          1,
          initialLocation: navigationShell.currentIndex == 1,
        );
        break;
      case 2:
        // Central Quick Add action: opens modal bottom sheet without branch switch
        QuickAddSheet.show(context);
        break;
      case 3:
        navigationShell.goBranch(
          2,
          initialLocation: navigationShell.currentIndex == 2,
        );
        break;
      case 4:
        navigationShell.goBranch(
          3,
          initialLocation: navigationShell.currentIndex == 3,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedIndex = _getNavBarIndex(navigationShell.currentIndex);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OfflineStatusBanner(),
          NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.today_outlined),
                selectedIcon: const Icon(Icons.today),
                label: l10n.navToday,
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: l10n.navCustomers,
              ),
              NavigationDestination(
                icon: const Icon(Icons.add_circle_outline),
                selectedIcon: const Icon(Icons.add_circle),
                label: l10n.actionAdd,
              ),
              NavigationDestination(
                icon: const Icon(Icons.notifications_none_outlined),
                selectedIcon: const Icon(Icons.notifications),
                label: l10n.navReminders,
              ),
              NavigationDestination(
                icon: const Icon(Icons.more_horiz_outlined),
                selectedIcon: const Icon(Icons.more_horiz),
                label: l10n.navMore,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
