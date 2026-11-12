import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/business.dart';
import '../models/user_profile.dart';
import '../repositories/repositories.dart';

/// Provider for the active SupabaseClient.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return SupabaseService.client;
});

/// Provider for Auth repository.
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client);
});

/// Provider for Profile repository.
final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProfileRepository(client);
});

/// Provider for Business repository.
final businessRepositoryProvider = Provider<IBusinessRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseBusinessRepository(client);
});

/// Provider for Customer repository.
final customerRepositoryProvider = Provider<ICustomerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseCustomerRepository(client);
});

/// Provider for Service repository.
final serviceRepositoryProvider = Provider<IServiceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseServiceRepository(client);
});

/// Provider for Reminder repository.
final reminderRepositoryProvider = Provider<IReminderRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseReminderRepository(client);
});

/// Provider for Maintenance repository.
final maintenanceRepositoryProvider = Provider<IMaintenanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseMaintenanceRepository(client);
});

/// Provider for AMC repository.
final amcRepositoryProvider = Provider<IAmcRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAmcRepository(client);
});

/// Provider for Notification repository.
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseNotificationRepository(client);
});

/// Stream provider for authentication state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Future provider for loading the authenticated user's profile.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final profileRepo = ref.watch(profileRepositoryProvider);
    return await profileRepo.getMyProfile();
  } catch (_) {
    return null;
  }
});

/// Future provider for loading the active business of the authenticated owner.
final currentBusinessProvider = FutureProvider<Business?>((ref) async {
  try {
    final businessRepo = ref.watch(businessRepositoryProvider);
    return await businessRepo.getMyBusiness();
  } catch (_) {
    return null;
  }
});

/// Provider for communication repository (WhatsApp, SMS, manual logging, stats).
final communicationRepositoryProvider = Provider<ICommunicationRepository>((
  ref,
) {
  try {
    final client = ref.watch(supabaseClientProvider);
    return SupabaseCommunicationRepository(client);
  } catch (_) {
    return SupabaseCommunicationRepository(null);
  }
});

/// Provider for message template repository (en/gu/hi templates, placeholders).
final messageTemplateRepositoryProvider = Provider<IMessageTemplateRepository>((
  ref,
) {
  try {
    final client = ref.watch(supabaseClientProvider);
    return SupabaseMessageTemplateRepository(client);
  } catch (_) {
    return SupabaseMessageTemplateRepository(null);
  }
});

/// Provider for customer messaging preferences and consent repository.
final consentRepositoryProvider = Provider<IConsentRepository>((ref) {
  try {
    final client = ref.watch(supabaseClientProvider);
    return SupabaseConsentRepository(client);
  } catch (_) {
    return SupabaseConsentRepository(null);
  }
});

/// Provider for bulk messaging and campaign management.
final bulkMessagingRepositoryProvider = Provider<IBulkMessagingRepository>((
  ref,
) {
  try {
    final client = ref.watch(supabaseClientProvider);
    return SupabaseBulkMessagingRepository(client);
  } catch (_) {
    return SupabaseBulkMessagingRepository(null);
  }
});

// Bulk messaging & feature entitlements are served from `features/subscriptions/providers/subscription_providers.dart`.
