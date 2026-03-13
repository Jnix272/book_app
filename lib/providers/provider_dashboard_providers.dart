import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/models.dart';
import 'repository_providers.dart';

// ─────────────────────────────────────────────
// Provider Dashboard Data Providers
// ─────────────────────────────────────────────

/// The current authenticated provider's user ID
final currentProviderIdProvider = Provider<String?>((ref) {
  return ref.watch(authRepositoryProvider).currentUserId;
});

/// Fetches the profile data for the provider
final providerBusinessProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(currentProviderIdProvider);
  if (uid == null) return null;
  return ref.read(providerRepositoryProvider).getProviderProfile(uid);
});

/// Fetches all appointments assigned to this provider
final providerAppointmentsProvider = FutureProvider.autoDispose<List<ProviderAppointment>>((ref) async {
  final uid = ref.watch(currentProviderIdProvider);
  if (uid == null) return [];
  
  return ref.read(appointmentRepositoryProvider).getProviderAppointments(uid);
});

/// Fetches the list of services offered by this provider
final providerServicesListProvider = FutureProvider.autoDispose<List<ServiceItem>>((ref) async {
  final uid = ref.watch(currentProviderIdProvider);
  if (uid == null) return [];

  return ref.read(providerRepositoryProvider).getProviderServices(uid);
});

/// Fetches the weekly working hours schedule string for this provider
final providerScheduleProvider = FutureProvider.autoDispose<List<WorkingHours>>((ref) async {
  final uid = ref.watch(currentProviderIdProvider);
  if (uid == null) return [];

  return ref.read(scheduleRepositoryProvider).getWorkingHours(uid);
});

/// Fetches block time offsets for this provider
final providerTimeOffsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final uid = ref.watch(currentProviderIdProvider);
  if (uid == null) return [];

  return ref.read(scheduleRepositoryProvider).getBlockedTimeOffsets(uid);
});
