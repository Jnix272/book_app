import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class BookingRepository {
  final SupabaseClient _client;

  BookingRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>> fetchSlots({
    required String providerId,
    required DateTime selectedDate,
    required int serviceDurationMin,
    int intervalMin = 30,
  }) async {
    final dayOfWeek = selectedDate.weekday % 7; // Sunday = 0
    final scheduleRow = await _client
        .from('provider_schedules')
        .select('start_time, end_time')
        .eq('provider_id', providerId)
        .eq('day_of_week', dayOfWeek)
        .eq('is_open', true)
        .maybeSingle();

    final startStr = (scheduleRow?['start_time'] as String?) ?? '09:00:00';
    final endStr = (scheduleRow?['end_time'] as String?) ?? '17:00:00';

    DateTime parseTimeOnly(String t) {
      final parts = t.split(':');
      return DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    var cursor = parseTimeOnly(startStr);
    final end = parseTimeOnly(endStr);
    final raw = <DateTime>[];

    // Safety check to prevent infinite loop if start > end
    if (cursor.isBefore(end)) {
      while (cursor.isBefore(end)) {
        raw.add(cursor);
        cursor = cursor.add(Duration(minutes: intervalMin));
      }
    }

    final startOfDay = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day);
    final nextDay = startOfDay.add(const Duration(days: 1));

    final appts = await _client
        .from('appointments')
        .select('appointment_datetime, duration_minutes')
        .eq('provider_id', providerId)
        .gte('appointment_datetime', startOfDay.toUtc().toIso8601String())
        .lt('appointment_datetime', nextDay.toUtc().toIso8601String())
        .neq('status', 'cancelled')
        .neq('status', 'no_show');

    final bookedRanges = (appts as List).map((row) {
      final start =
          DateTime.parse(row['appointment_datetime'] as String).toLocal();
      final dur = row['duration_minutes'] as int;
      return DateTimeRange(
          start: start, end: start.add(Duration(minutes: dur)));
    }).toList();

    final now = DateTime.now();
    final unavailable = <DateTime>{};

    for (final slot in raw) {
      final slotEnd = slot.add(Duration(minutes: serviceDurationMin));

      // Past slot
      if (slot.isBefore(now)) {
        unavailable.add(slot);
        continue;
      }

      // Overlaps a booked range
      final overlaps = bookedRanges.any(
          (r) => slot.isBefore(r.end) && slotEnd.isAfter(r.start));
      if (overlaps) unavailable.add(slot);
    }

    return {
      'allSlots': raw,
      'unavailableSlots': unavailable,
    };
  }

  Future<String> confirmBooking({
    required String providerId,
    required String serviceId,
    required DateTime appointmentStart,
    required int durationMin,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final response = await _client
        .from('appointments')
        .insert({
          'customer_id': user.id,
          'provider_id': providerId,
          'service_id': serviceId,
          'appointment_datetime': appointmentStart.toIso8601String(),
          'duration_minutes': durationMin,
          'status': 'confirmed',
          'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        })
        .select('appointment_id')
        .single();

    return response['appointment_id'] as String;
  }
}
