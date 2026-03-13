import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/models.dart';
import '../../data/dto/appointment_dto.dart';
import '../../data/dto/service_item_dto.dart';

class SupabaseClientService {
  static final SupabaseClientService instance =
      SupabaseClientService._internal();
  SupabaseClientService._internal();

  final _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetches all appointments for a specific provider.
  /// Uses the new schema: notes (not customer_notes), users join (not profiles),
  /// first_name + last_name (not full_name).
  Future<List<ProviderAppointment>> getProviderAppointments(
    String providerId,
  ) async {
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

  /// Updates an appointment's status.
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

  /// Fetches services for a provider.
  Future<List<ServiceItem>> getProviderServices(String providerId) async {
    try {
      final res = await _client
          .from('services')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      return (res as List).map((json) => ServiceItemDto.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching provider services: $e');
      return [];
    }
  }
}
