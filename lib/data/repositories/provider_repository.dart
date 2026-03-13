import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import '../../domain/models/models.dart';
import '../dto/service_provider_dto.dart';
import '../dto/service_item_dto.dart';

class ProviderRepository {
  final SupabaseClient _client;

  ProviderRepository({SupabaseClient? client}) 
    : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>?> getProviderProfile(String userId) async {
    try {
      return await _client
          .from('providers')
          .select(
            'provider_id, business_name, category, address, city, state, bio, average_rating, total_reviews, avatar_url, auto_confirm, allow_reschedule, show_rating, users!inner(email, phone, notification_email, notification_sms, notification_push, notification_daily_summary, notification_email_cancel)',
          )
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error getting provider profile: $e');
      return null;
    }
  }

  Future<void> updateProviderToggle(String providerId, String column, bool value) async {
    await _client.from('providers').update({column: value}).eq('provider_id', providerId);
  }

  Future<void> updateUserToggle(String userId, String column, bool value) async {
    await _client.from('users').update({column: value}).eq('user_id', userId);
  }

  Future<void> updateProviderDetails({
    required String providerId,
    required String businessName,
    required String bio,
    required String address,
  }) async {
    await _client.from('providers').update({
      'business_name': businessName,
      'bio': bio,
      'address': address,
    }).eq('provider_id', providerId);
  }

  Future<void> updateUserDetails({
    required String userId,
    required String email,
    required String phone,
  }) async {
    await _client.from('users').update({
      'email': email,
      'phone': phone,
    }).eq('user_id', userId);
  }

  Future<List<ServiceProvider>> fetchProviders({String? query}) async {
    try {
      var req = _client.from('providers').select('''
        *,
        provider_schedules (day_of_week, start_time, end_time, is_open),
        services (*)
      ''');

      if (query != null && query.isNotEmpty) {
        req = req.ilike('business_name', '%$query%');
      }

      final res = await req.limit(50);
      return (res as List).map((json) => ServiceProviderDto.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching providers: $e');
      return [];
    }
  }

  Future<List<ServiceProvider>> searchProviders({
    String? query,
    String category = 'All',
    double minRating = 0,
    double maxPrice = double.infinity,
    String sortBy = 'rating',
  }) async {
    try {
      var request = _client
          .from('providers')
          .select('''
            *,
            provider_schedules (day_of_week, start_time, end_time, is_open),
            services (*)
          ''')
          .eq('is_approved', true);

      if (minRating > 0) {
        request = request.gte('average_rating', minRating);
      }

      final orderColumn = sortBy == 'reviews' ? 'total_reviews' : 'average_rating';
      final res = await request.order(orderColumn, ascending: false);

      List<ServiceProvider> providers = (res as List)
          .map((p) => ServiceProviderDto.fromJson(p))
          .toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        providers = providers.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q);
        }).toList();
      }

      if (category != 'All') {
        providers = providers.where((p) => p.category == category).toList();
      }

      if (maxPrice != double.infinity) {
        providers = providers.where((p) {
          if (p.services.isEmpty) return false;
          final minP = p.services
              .map((s) => s.price)
              .reduce((a, b) => a < b ? a : b);
          return minP <= maxPrice;
        }).toList();
      }

      return providers;
    } catch (e) {
      debugPrint('Error searching providers: $e');
      return [];
    }
  }

  Future<ServiceProvider?> getProviderById(String id) async {
    try {
      final res = await _client.from('providers').select('''
        *,
        provider_schedules (day_of_week, start_time, end_time, is_open),
        services (*)
      ''').eq('provider_id', id).maybeSingle();

      if (res == null) return null;
      return ServiceProviderDto.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching provider details: $e');
      return null;
    }
  }

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

  Future<void> deleteService(String serviceId) async {
    await _client.from('services').delete().eq('service_id', serviceId);
  }

  Future<void> addService(Map<String, dynamic> payload) async {
    await _client.from('services').insert(payload);
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> payload) async {
    await _client.from('services').update(payload).eq('service_id', serviceId);
  }

  Future<void> updateProviderAvatar(String providerId, String avatarUrl) async {
    await _client
        .from('providers')
        .update({'avatar_url': avatarUrl}).eq('provider_id', providerId);
  }

  String? get currentUserId => _client.auth.currentUser?.id;
}
