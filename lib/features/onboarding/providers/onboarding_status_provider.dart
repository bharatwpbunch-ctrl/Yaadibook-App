import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/backend_providers.dart';
import 'onboarding_controller.dart';

enum OnboardingJourneyStatus {
  loading,
  unauthenticated,
  needsBusiness,
  completed,
}

/// Computes the active user's journey status by querying auth, profile, and business state.
final onboardingJourneyStatusProvider = Provider<OnboardingJourneyStatus>((
  ref,
) {
  // Listen to Supabase auth state stream for reactive updates
  ref.watch(authStateProvider);

  final authRepo = ref.watch(authRepositoryProvider);
  final currentUser = authRepo.currentUser;

  // 1. If not authenticated, route to welcome/login
  if (currentUser == null) {
    return OnboardingJourneyStatus.unauthenticated;
  }

  // 2. If onboardingController completed setup in memory, immediately allow transition
  final onboardingState = ref.watch(onboardingControllerProvider);
  if (onboardingState.isCompleted) {
    return OnboardingJourneyStatus.completed;
  }

  // 3. Watch business query
  final businessAsync = ref.watch(currentBusinessProvider);

  return businessAsync.when(
    data: (business) {
      if (business == null) {
        return OnboardingJourneyStatus.needsBusiness;
      }
      return OnboardingJourneyStatus.completed;
    },
    loading: () => OnboardingJourneyStatus.loading,
    error: (e, st) => OnboardingJourneyStatus.needsBusiness,
  );
});
