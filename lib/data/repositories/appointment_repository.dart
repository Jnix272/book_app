import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import '../../domain/models/models.dart';
import '../dto/appointment_dto.dart';

class AppointmentRepository {
  final SupabaseClient _client;

  AppointmentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<ProviderAppointment>> getProviderAppointments(
      String providerId) async {
    try {
      final res = await _client
          .from('appointments')
          .select('''
            appointment_id,
            appointment_datetime,
            duration_minutes,
            status,
            notes,
            services (
              service_name,
              price,
              duration_minutes
            ),
            users:customer_id (
              first_name,
              last_name
            )
          ''')
          .eq('provider_id', providerId)
          .order('appointment_datetime', ascending: true);

      return (res as List)
          .map((json) => ProviderAppointmentDto.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching provider appointments: $e');
      return [];
    }
  }

  Future<List<Appointment>> getCustomerAppointments() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final res = await _client
          .from('appointments')
          .select('''
            appointment_id,
            appointment_datetime,
            duration_minutes,
            status,
            provider_id,
            service_id,
            providers (
              business_name
            ),
            services (
              service_name,
              price,
              duration_minutes,
              buffer_minutes
            )
          ''')
          .eq('customer_id', userId)
          .order('appointment_datetime', ascending: false);

      return (res as List).map((json) => AppointmentDto.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching customer appointments: $e');
      return [];
    }
  }

  Future<bool> updateAppointmentStatus(
    String appointmentId,
    String newStatus, {
    String? reason,
  }) async {
    try {
      final dbStatus = switch (newStatus) {
        'Confirmed' => 'confirmed',
        'Cancelled' => 'cancelled',
        'Completed' => 'completed',
        'No Show' => 'no_show',
        'Pending' => 'pending',
        _ => throw ArgumentError('Unknown appointment status: $newStatus'),
      };

      final updates = <String, dynamic>{'status': dbStatus};
      if (reason != null && reason.isNotEmpty) {
        updates['cancellation_reason'] = reason;
      }

      await _client
          .from('appointments')
          .update(updates)
          .eq('appointment_id', appointmentId);

      return true;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return false;
    }
  }

  Future<bool> rescheduleAppointment(
    String appointmentId,
    String newDateTimeIso,
  ) async {
    try {
      await _client
          .from('appointments')
          .update({
            'appointment_datetime': newDateTimeIso,
            'status': 'rescheduled',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('appointment_id', appointmentId);
      return true;
    } catch (e) {
      debugPrint('Error rescheduling appointment: $e');
      return false;
    }
  }

  Future<bool> hasUpcomingAppointmentsForService(String serviceId) async {
    try {
      final upcoming = await _client
          .from('appointments')
          .select('appointment_id')
          .eq('service_id', serviceId)
          .gte('appointment_datetime', DateTime.now().toUtc().toIso8601String())
          .neq('status', 'cancelled')
          .limit(1);
      return (upcoming as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking upcoming appointments for service: $e');
      return true; // Fail safe: prevent deletion if error occurs
    }
  }
}
