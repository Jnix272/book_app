import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import '../../domain/models/models.dart';
import '../dto/appointment_dto.dart';
import '../dto/service_provider_dto.dart';

class CustomerRepository {
  final SupabaseClient _client;

  CustomerRepository(this._client);

  // ─────────────────────────────────────────────
  // Profile
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getCustomerProfile(String customerId) async {
    try {
      return await _client
          .from('users')
          .select()
          .eq('user_id', customerId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching customer profile: $e');
      return null;
    }
  }

  Future<bool> updateCustomerProfile(String customerId, Map<String, dynamic> updates) async {
    try {
      // Supabase updateUser for metadata vs direct table update
      // Since it's synced via trigger, we update the auth metadata
      // which syncs over to public.users automatically via trigger
      await _client.auth.updateUser(
        UserAttributes(data: updates),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating customer profile: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Appointments
  // ─────────────────────────────────────────────

  Future<List<Appointment>> getCustomerAppointments(String customerId) async {
    try {
      final res = await _client
          .from('appointments')
          .select(
            '*, providers(business_name), services(service_name, price, duration_minutes)',
          )
          .eq('customer_id', customerId)
          .order('appointment_datetime', ascending: true);

      return (res as List).map((a) => AppointmentDto.fromJson(a)).toList();
    } catch (e) {
      debugPrint('Error fetching customer appointments: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // Favorites
  // ─────────────────────────────────────────────

  Future<List<String>> getFavoriteProviderIds(String customerId) async {
    try {
      final res = await _client
          .from('favorites')
          .select('provider_id')
          .eq('customer_id', customerId);
          
      return (res as List).map((f) => f['provider_id'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      return [];
    }
  }

  Future<bool> toggleFavorite(String customerId, String providerId) async {
    try {
      final existing = await _client
          .from('favorites')
          .select()
          .eq('customer_id', customerId)
          .eq('provider_id', providerId)
          .maybeSingle();

      if (existing != null) {
        // remove
        await _client
            .from('favorites')
            .delete()
            .eq('customer_id', customerId)
            .eq('provider_id', providerId);
      } else {
        // add
        await _client.from('favorites').insert({
          'customer_id': customerId,
          'provider_id': providerId,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  Future<List<ServiceProvider>> getFavoriteProviders(String customerId) async {
    try {
      final res = await _client.from('favorites').select('''
        provider_id,
        providers (
          *,
          users!providers_user_id_fkey (
            first_name,
            last_name
          )
        )
      ''').eq('customer_id', customerId);

      final List<ServiceProvider> results = [];
      for (final row in res as List) {
        final Map<String, dynamic>? pData = row['providers'];
        if (pData != null) {
          // get services for this provider
          final svcRes = await _client
              .from('services')
              .select('*')
              .eq('provider_id', pData['provider_id']);
          
          pData['services'] = svcRes;
          results.add(ServiceProviderDto.fromJson(pData));
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error fetching favorite providers full: $e');
      return [];
    }
  }
}
