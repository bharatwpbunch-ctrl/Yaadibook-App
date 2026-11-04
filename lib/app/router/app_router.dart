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
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/quick_add_screen.dart';
import '../../features/dashboard/presentation/today_screen.dart';
import '../../features/onboarding/presentation/business_onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_status_provider.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

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

      // 4. Main App Shell (Dashboard, Customers, Quick Add, Reminders, Settings)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Today / Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          // Branch 2: Customers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomersScreen(),
              ),
            ],
          ),
          // Branch 3: Quick Add
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quick-add',
                builder: (context, state) => const QuickAddScreen(),
              ),
            ],
          ),
          // Branch 4: Reminders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reminders',
                builder: (context, state) => const RemindersScreen(),
              ),
            ],
          ),
          // Branch 5: More / Settings
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

/// Stateful navigation shell supporting the bottom navigation bar.
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onItemTapped,
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
            label: l10n.navQuickAdd,
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
    );
  }
}
