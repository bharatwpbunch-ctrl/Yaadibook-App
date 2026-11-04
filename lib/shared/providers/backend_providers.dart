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

/// Stream provider for authentication state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Future provider for loading the authenticated user's profile.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  return profileRepo.getMyProfile();
});

/// Future provider for loading the active business of the authenticated owner.
final currentBusinessProvider = FutureProvider<Business?>((ref) async {
  final businessRepo = ref.watch(businessRepositoryProvider);
  return businessRepo.getMyBusiness();
});
