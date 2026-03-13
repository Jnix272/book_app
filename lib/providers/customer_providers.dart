import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/models.dart';
import 'repository_providers.dart';

// ─────────────────────────────────────────────
// Customer Core Data Providers
// ─────────────────────────────────────────────

/// The current authenticated user's ID
final customerIdProvider = Provider<String?>((ref) {
  // We can derive this directly from AuthRepository
  return ref.watch(authRepositoryProvider).currentUserId;
});

/// Fetches upcoming/past appointments for the logged-in customer
final customerAppointmentsProvider = FutureProvider.autoDispose<List<Appointment>>((ref) async {
  final uid = ref.watch(customerIdProvider);
  if (uid == null) return [];
  
  return ref.read(customerRepositoryProvider).getCustomerAppointments(uid);
});

/// Fetches the populated list of favorite providers for the logged-in customer
final favoriteProvidersProvider = FutureProvider.autoDispose<List<ServiceProvider>>((ref) async {
  final uid = ref.watch(customerIdProvider);
  if (uid == null) return [];

  return ref.read(customerRepositoryProvider).getFavoriteProviders(uid);
});

/// Fetches the generic default feed of providers for the Home screen
final homeFeedProvider = FutureProvider.autoDispose<List<ServiceProvider>>((ref) async {
  return ref.read(providerRepositoryProvider).fetchProviders();
});
