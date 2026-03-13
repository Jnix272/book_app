import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/provider_repository.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(Supabase.instance.client);
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(client: Supabase.instance.client);
});

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  return ProviderRepository();
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository();
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});
